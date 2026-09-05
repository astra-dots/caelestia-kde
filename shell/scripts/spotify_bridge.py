#!/usr/bin/env python3
"""
Caelestia <-> Spicetify Multi-Threaded Local IPC Bridge Server
Robust, self-healing, with orphan cleanup and broken-pipe protection.
"""

import sys
import os
import json
import time
import queue
import threading
import urllib.parse
import subprocess
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

PORT = 8999
LOG_FILE = "/tmp/spotify_bridge.log"
pending_commands = []
active_waiters = []
lock = threading.Lock()
current_state = {"isLiked": False, "uri": ""}
current_lyrics = {}
LYRICS_CACHE_FILE = "/tmp/caelestia_spotify_lyrics.json"


def load_cached_lyrics():
    global current_lyrics
    if os.path.exists(LYRICS_CACHE_FILE):
        try:
            with open(LYRICS_CACHE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
            if data and data.get("lines"):
                current_lyrics = data
                log_debug(f"Loaded {len(data.get('lines', []))} lines from disk for {data.get('uri')}")
                emit_lyrics(current_lyrics)
        except Exception as e:
            log_debug(f"Error loading disk lyrics: {e}")


def save_cached_lyrics(data):
    try:
        with open(LYRICS_CACHE_FILE, "w", encoding="utf-8") as f:
            json.dump(data, f)
    except Exception as e:
        log_debug(f"Error saving disk lyrics: {e}")


def find_spicy_lyrics_on_disk(uri):
    if not uri or not uri.startswith("spotify:track:"):
        return None
    track_id = uri.split(":")[2]
    cache_base = os.path.expanduser("~/.cache/spotify/Browser/Service Worker/CacheStorage")
    if not os.path.exists(cache_base):
        return None
    import glob
    pattern = os.path.join(cache_base, "*", "*", "*_0")
    for fp in glob.glob(pattern):
        try:
            with open(fp, "rb") as f:
                c = f.read()
            if track_id.encode("utf-8") not in c:
                continue
            idx = c.find(b"{\"")
            if idx == -1:
                continue
            s = c[idx:].decode("utf-8", errors="ignore")
            data, _ = json.JSONDecoder().raw_decode(s)
            content = data.get("Content", {})
            type_name = content.get("Type", "Line")
            raw_items = content.get("Content", [])
            if not raw_items:
                continue
            lines = []
            if type_name == "Syllable":
                for it in raw_items:
                    lead = it.get("Lead") or {}
                    syls = lead.get("Syllables", []) if isinstance(lead, dict) else []
                    bg_raw = it.get("Background", [])

                    if not syls and not bg_raw and not it.get("Text"):
                        continue

                    s_list = []
                    full_text = ""
                    for sIdx, s_obj in enumerate(syls):
                        isLast = (sIdx == len(syls) - 1)
                        stext = s_obj.get("Text", "")
                        if not s_obj.get("IsPartOfWord") and not isLast and not stext.endswith(" "):
                            stext += " "
                        full_text += stext
                        s_list.append({
                            "text": stext,
                            "startTime": float(s_obj.get("StartTime", 0)),
                            "endTime": float(s_obj.get("EndTime", 0)),
                            "isPartOfWord": bool(s_obj.get("IsPartOfWord"))
                        })

                    bg_lines = []
                    for bgItem in bg_raw:
                        bg_s_list = []
                        bg_full_text = ""
                        bg_syls = bgItem.get("Syllables", [])
                        for sIdx, s_obj in enumerate(bg_syls):
                            isLast = (sIdx == len(bg_syls) - 1)
                            stext = s_obj.get("Text", "")
                            if not s_obj.get("IsPartOfWord") and not isLast and not stext.endswith(" "):
                                stext += " "
                            bg_full_text += stext
                            bg_s_list.append({
                                "text": stext,
                                "startTime": float(s_obj.get("StartTime", 0)),
                                "endTime": float(s_obj.get("EndTime", 0)),
                                "isPartOfWord": bool(s_obj.get("IsPartOfWord"))
                            })
                        if bg_full_text.strip() or bg_s_list:
                            bg_lines.append({
                                "text": bg_full_text.strip(),
                                "startTime": float(bgItem.get("StartTime", 0)),
                                "endTime": float(bgItem.get("EndTime", 0)),
                                "syllables": bg_s_list
                            })

                    line_start = float(lead.get("StartTime", 0)) if (isinstance(lead, dict) and lead.get("StartTime") is not None) else float(it.get("StartTime", 0))
                    line_end = float(lead.get("EndTime", 0)) if (isinstance(lead, dict) and lead.get("EndTime") is not None) else float(it.get("EndTime", 0))

                    lines.append({
                        "text": full_text.strip(),
                        "startTime": line_start,
                        "endTime": line_end,
                        "syllables": s_list,
                        "oppositeAligned": bool(it.get("OppositeAligned")),
                        "background": bg_lines
                    })
            else:
                for it in raw_items:
                    bg_lines = []
                    for bgItem in it.get("Background", []):
                        bg_text = (bgItem.get("Text") or "").strip()
                        if bg_text:
                            bg_lines.append({
                                "text": bg_text,
                                "startTime": float(bgItem.get("StartTime", 0)),
                                "endTime": float(bgItem.get("EndTime", 0)),
                                "syllables": []
                            })
                    lines.append({
                        "text": (it.get("Text") or "").strip(),
                        "startTime": float(it.get("StartTime", 0)),
                        "endTime": float(it.get("EndTime", 0)),
                        "syllables": [],
                        "oppositeAligned": bool(it.get("OppositeAligned")),
                        "background": bg_lines
                    })
            if lines:
                return {
                    "uri": uri,
                    "source": "spicy-lyrics",
                    "type": type_name,
                    "lines": lines
                }
        except Exception:
            continue
    return None


def log_debug(msg):
    try:
        # Cap log size to 200KB
        if os.path.exists(LOG_FILE) and os.path.getsize(LOG_FILE) > 200000:
            with open(LOG_FILE, "w") as f:
                f.write(f"[{time.strftime('%X')}] Log rotated\n")
        with open(LOG_FILE, "a") as f:
            f.write(f"[{time.strftime('%X')}] {msg}\n")
    except Exception:
        pass


def kill_stale_bridges():
    current_pid = os.getpid()
    try:
        res = subprocess.run(["pgrep", "-f", "spotify_bridge.py"], capture_output=True, text=True)
        for line in res.stdout.strip().splitlines():
            try:
                pid = int(line.strip())
                if pid != current_pid:
                    os.kill(pid, 9)
            except Exception:
                pass
        time.sleep(0.1)
    except Exception:
        pass


def emit_state(state):
    try:
        sys.stdout.write(f"STATE:{json.dumps(state)}\n")
        sys.stdout.flush()
    except (BrokenPipeError, IOError, Exception):
        pass


def emit_lyrics(lyrics):
    try:
        sys.stdout.write(f"LYRICS:{json.dumps(lyrics)}\n")
        sys.stdout.flush()
    except (BrokenPipeError, IOError, Exception):
        pass


def queue_command(cmd):
    with lock:
        pending_commands.append(cmd)
        for event in active_waiters:
            event.set()
        active_waiters.clear()


class BridgeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Override to suppress default console spam and use log_debug
        pass

    def end_headers_cors(self, status=200, content_type="application/json"):
        try:
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
            self.send_header("Access-Control-Allow-Headers", "*")
            self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
            self.end_headers()
        except Exception:
            pass

    def do_OPTIONS(self):
        self.end_headers_cors(200)
        try:
            self.wfile.write(b"")
        except Exception:
            pass

    def do_GET(self):
        global current_lyrics
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path

        if path == "/state":
            params = urllib.parse.parse_qs(parsed.query)
            if "data" in params:
                try:
                    data = json.loads(params["data"][0])
                    if "isLiked" in data:
                        current_state["isLiked"] = bool(data["isLiked"])
                    if "uri" in data:
                        current_state["uri"] = str(data["uri"])
                    if "upcoming" in data:
                        current_state["upcoming"] = data["upcoming"]
                except Exception:
                    pass
            elif "liked" in params:
                current_state["isLiked"] = params.get("liked", ["false"])[0].lower() == "true"
                current_state["uri"] = params.get("uri", [""])[0]

            log_debug(f"GET /state -> isLiked={current_state.get('isLiked')} uri={current_state.get('uri')}")
            emit_state(current_state)

            self.end_headers_cors(200)
            try:
                self.wfile.write(json.dumps(current_state).encode("utf-8"))
            except Exception:
                pass

        elif path == "/lyrics" or parsed.path == "/lyrics":
            from urllib.parse import parse_qs
            req_uri = parse_qs(parsed.query).get("uri", [""])[0]
            log_debug(f"GET /lyrics requested (req_uri={req_uri})")
            target_uri = req_uri or current_state.get("uri") or current_lyrics.get("uri")
            if target_uri:
                disk_lyrics = find_spicy_lyrics_on_disk(target_uri)
                if disk_lyrics:
                    disk_bg = sum(1 for l in disk_lyrics.get("lines", []) if l.get("background"))
                    curr_bg = sum(1 for l in current_lyrics.get("lines", []) if l.get("background"))
                    if not current_lyrics or current_lyrics.get("uri") != target_uri or disk_bg > curr_bg:
                        current_lyrics = disk_lyrics
                        save_cached_lyrics(current_lyrics)
                        log_debug(f"Loaded {len(current_lyrics.get('lines', []))} lines (bg={disk_bg}) from Spotify disk cache for {target_uri}")
            if current_lyrics and current_lyrics.get("lines"):
                emit_lyrics(current_lyrics)
            self.end_headers_cors(200)
            try:
                self.wfile.write(json.dumps(current_lyrics).encode("utf-8"))
            except Exception:
                pass

        elif path == "/poll":
            cmd = None
            event = None

            with lock:
                if pending_commands:
                    cmd = pending_commands.pop(0)
                else:
                    event = threading.Event()
                    active_waiters.append(event)

            if not cmd and event:
                event.wait(timeout=15.0)
                with lock:
                    if event in active_waiters:
                        active_waiters.remove(event)
                    if pending_commands:
                        cmd = pending_commands.pop(0)

            self.end_headers_cors(200)
            try:
                if cmd:
                    log_debug(f"POLL dispatched: {cmd}")
                    self.wfile.write(json.dumps(cmd).encode("utf-8"))
                else:
                    self.wfile.write(b'{"action":"none"}')
            except Exception:
                pass

        elif path == "/toggle":
            log_debug("GET /toggle received")
            queue_command({"action": "toggleHeart"})
            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"queued"}')
            except Exception:
                pass

        elif path == "/skip":
            log_debug("GET /skip received")
            queue_command({"action": "skipNext"})
            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"queued"}')
            except Exception:
                pass

        elif path == "/refresh" or path == "/reload":
            log_debug("GET /refresh received")
            queue_command({"action": "reloadLyrics"})
            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"queued"}')
            except Exception:
                pass

        else:
            self.end_headers_cors(404)
            try:
                self.wfile.write(b'{"error":"not_found"}')
            except Exception:
                pass

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/state":
            try:
                length = int(self.headers.get("Content-Length", 0))
                body = self.rfile.read(length).decode("utf-8")
                data = json.loads(body)
                if "isLiked" in data:
                    current_state["isLiked"] = bool(data["isLiked"])
                if "uri" in data:
                    current_state["uri"] = str(data["uri"])
                if "upcoming" in data:
                    current_state["upcoming"] = data["upcoming"]

                log_debug(f"POST /state -> isLiked={current_state.get('isLiked')} uri={current_state.get('uri')}")
                emit_state(current_state)
            except Exception:
                pass

            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"ok"}')
            except Exception:
                pass

        elif parsed.path == "/lyrics":
            global current_lyrics
            try:
                length = int(self.headers.get("Content-Length", 0))
                body = self.rfile.read(length).decode("utf-8")
                data = json.loads(body)
                post_bg_count = sum(1 for l in data.get("lines", []) if l.get("background"))
                uri = data.get("uri") or current_state.get("uri")
                if uri:
                    disk_lyrics = find_spicy_lyrics_on_disk(uri)
                    if disk_lyrics:
                        disk_bg_count = sum(1 for l in disk_lyrics.get("lines", []) if l.get("background"))
                        if disk_bg_count > post_bg_count:
                            log_debug(f"Preserving {disk_bg_count} background lines from disk cache over bridge POST ({post_bg_count} bg)")
                            data = disk_lyrics
                current_lyrics = data
                save_cached_lyrics(current_lyrics)
                log_debug(f"POST /lyrics -> uri={data.get('uri')} type={data.get('type')} lines={len(data.get('lines', []))}")
                emit_lyrics(current_lyrics)
            except Exception as e:
                log_debug(f"POST /lyrics error: {e}")

            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"ok"}')
            except Exception:
                pass

        elif parsed.path == "/debug":
            try:
                length = int(self.headers.get("Content-Length", 0))
                msg = self.rfile.read(length).decode("utf-8")
                log_debug(f"[BRIDGE_JS] {msg}")
            except Exception:
                pass
            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"ok"}')
            except Exception:
                pass

        elif parsed.path == "/eval":
            try:
                length = int(self.headers.get("Content-Length", 0))
                code = self.rfile.read(length).decode("utf-8")
                queue_command({"action": "eval", "code": code})
                log_debug(f"Queued eval: {code[:60]}...")
            except Exception as e:
                log_debug(f"Eval queue error: {e}")
            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"queued"}')
            except Exception:
                pass

        elif parsed.path == "/toggle":
            log_debug("POST /toggle received")
            queue_command({"action": "toggleHeart"})
            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"queued"}')
            except Exception:
                pass

        elif parsed.path == "/skip":
            log_debug("POST /skip received")
            queue_command({"action": "skipNext"})
            self.end_headers_cors(200)
            try:
                self.wfile.write(b'{"status":"queued"}')
            except Exception:
                pass

        else:
            self.end_headers_cors(404)
            try:
                self.wfile.write(b'{"error":"not_found"}')
            except Exception:
                pass


def stdin_reader():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        if line == "TOGGLE":
            queue_command({"action": "toggleHeart"})


def main():
    kill_stale_bridges()

    server = None
    for attempt in range(5):
        try:
            server = ThreadingHTTPServer(("127.0.0.1", PORT), BridgeHandler)
            server.allow_reuse_address = True
            break
        except OSError:
            kill_stale_bridges()
            time.sleep(0.3)

    if not server:
        log_debug(f"Failed to bind port {PORT} after retries")
        sys.exit(1)

    t = threading.Thread(target=stdin_reader, daemon=True)
    t.start()

    log_debug(f"Server ready on port {PORT}")
    try:
        sys.stdout.write(f"READY:{PORT}\n")
        sys.stdout.flush()
    except Exception:
        pass

    load_cached_lyrics()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

