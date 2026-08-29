#!/usr/bin/env python3
"""
Caelestia <-> Spicetify Multi-Threaded Local IPC Bridge Server
"""

import sys
import os
import json
import time
import queue
import threading
import urllib.parse
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler

PORT = 8999
pending_commands = []
active_waiters = []
lock = threading.Lock()
current_state = {"isLiked": False, "uri": ""}


def queue_command(cmd):
    with lock:
        pending_commands.append(cmd)
        for event in active_waiters:
            event.set()
        active_waiters.clear()


class BridgeHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        try:
            with open("/tmp/spotify_bridge.log", "a") as f:
                f.write(f"[{time.strftime('%X')}] {self.command} {self.path}\n")
        except Exception:
            pass

    def end_headers_cors(self, status=200, content_type="application/json"):
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "*")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate")
        self.end_headers()

    def do_OPTIONS(self):
        self.end_headers_cors(200)
        self.wfile.write(b"")

    def do_GET(self):
        try:
            with open("/tmp/spotify_bridge.log", "a") as f:
                f.write(f"[{time.strftime('%X')}] GET {self.path[:120]}\n")
        except Exception:
            pass
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

            sys.stdout.write(f"STATE:{json.dumps(current_state)}\n")
            sys.stdout.flush()

            self.end_headers_cors(200)
            self.wfile.write(json.dumps(current_state).encode("utf-8"))

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
            if cmd:
                self.wfile.write(json.dumps(cmd).encode("utf-8"))
            else:
                self.wfile.write(b'{"action":"none"}')

        elif path == "/toggle":
            queue_command({"action": "toggleHeart"})
            self.end_headers_cors(200)
            self.wfile.write(b'{"status":"queued"}')

        elif path == "/skip":
            queue_command({"action": "skipNext"})
            self.end_headers_cors(200)
            self.wfile.write(b'{"status":"queued"}')

        else:
            self.end_headers_cors(404)
            self.wfile.write(b'{"error":"not_found"}')

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

                sys.stdout.write(f"STATE:{json.dumps(current_state)}\n")
                sys.stdout.flush()
            except Exception as e:
                pass

            self.end_headers_cors(200)
            self.wfile.write(b'{"status":"ok"}')

        elif parsed.path == "/toggle":
            queue_command({"action": "toggleHeart"})
            self.end_headers_cors(200)
            self.wfile.write(b'{"status":"queued"}')

        elif parsed.path == "/skip":
            queue_command({"action": "skipNext"})
            self.end_headers_cors(200)
            self.wfile.write(b'{"status":"queued"}')

        else:
            self.end_headers_cors(404)
            self.wfile.write(b'{"error":"not_found"}')


def stdin_reader():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        if line == "TOGGLE":
            queue_command({"action": "toggleHeart"})


def main():
    server = ThreadingHTTPServer(("127.0.0.1", PORT), BridgeHandler)
    server.allow_reuse_address = True

    t = threading.Thread(target=stdin_reader, daemon=True)
    t.start()

    sys.stdout.write(f"READY:{PORT}\n")
    sys.stdout.flush()

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
