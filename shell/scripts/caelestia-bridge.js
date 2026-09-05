// Caelestia <-> Spicetify Zero-Config Local IPC Bridge
(function CaelestiaBridge() {
    if (!window.Spicetify || !Spicetify.Player) {
        setTimeout(CaelestiaBridge, 200);
        return;
    }
    window.__caelestia_bridge_version = (window.__caelestia_bridge_version || 0) + 1;
    const currentVersion = window.__caelestia_bridge_version;

    let lastUri = "";
    let lastLiked = null;
    let lastUpcomingHash = "";
    let isToggling = false;

    function getHeartState() {
        try {
            const uri = Spicetify.Player.data?.item?.uri || Spicetify.Player.origin?._state?.item?.uri || lastUri;

            // 1. Spicetify Library API containsSync (synchronous & accurate)
            if (uri && Spicetify.Platform?.LibraryAPI?.containsSync) {
                const inLib = Spicetify.Platform.LibraryAPI.containsSync(uri);
                if (typeof inLib === "boolean") return inLib;
            }

            // 2. Direct inspection of Spotify's now-playing DOM button
            const btn = document.querySelector('button[data-testid="add-button"], .main-nowPlayingBar-left button[data-testid="add-button"], .main-nowPlayingBar-left button[aria-label*="Library"], .main-nowPlayingBar-left button[aria-label*="Liked"], .main-nowPlayingBar-left button[aria-label*="library"], .main-nowPlayingBar-left button[aria-label*="liked"]');
            if (btn) {
                const checked = btn.getAttribute("aria-checked");
                if (checked !== null) return checked === "true";
                if (btn.classList.contains("main-addButton-active")) return true;
                const label = (btn.getAttribute("aria-label") || "").toLowerCase();
                if (label.includes("remove") || label.includes("saved") || label.includes("added") || label.includes("already")) return true;
                if (label.includes("add") || label.includes("save")) return false;
            }

            // 3. Spicetify Player API
            if (typeof Spicetify.Player.getHeart === "function") {
                const res = Spicetify.Player.getHeart();
                if (typeof res === "boolean") return res;
            }

            // 4. Fallback to Player origin state metadata
            const meta = Spicetify.Player.origin?._state?.item?.metadata;
            if (meta && "collection.in_collection" in meta) {
                return meta["collection.in_collection"] === "true";
            }
        } catch (e) {}
        return false;
    }

    function parseTrack(raw) {
        if (!raw) return null;
        try {
            const item = raw.item || raw.track || raw;
            const meta = raw.metadata || item.metadata || {};
            
            const title = raw.name || raw.title || item.name || item.title || meta.title || meta.name || meta["title"] || "";
            if (!title || typeof title !== "string") return null;

            let artist = "";
            const artists = raw.artists || item.artists;
            if (Array.isArray(artists) && artists.length > 0) {
                artist = artists.map(a => (typeof a === "string" ? a : (a?.name || ""))).filter(Boolean).join(", ");
            } else if (raw.artist || item.artist) {
                const art = raw.artist || item.artist;
                artist = typeof art === "string" ? art : (art?.name || "");
            } else if (meta.artist_name) {
                artist = meta.artist_name;
            } else if (meta.artists) {
                artist = typeof meta.artists === "string" ? meta.artists : (Array.isArray(meta.artists) ? meta.artists.map(a => (typeof a === "string" ? a : (a?.name || ""))).filter(Boolean).join(", ") : (meta.artists[0]?.name || ""));
            }

            let album = raw.album?.name || item.album?.name || (typeof raw.album === "string" ? raw.album : "") || meta.album_title || meta.album_name || "";

            let artUrl = meta.image_url || meta.image_small_url || meta.image_large_url || meta.image_xlarge_url || raw.album?.images?.[0]?.url || item.album?.images?.[0]?.url || meta["image_url"] || "";
            
            if (artUrl && typeof artUrl === "string" && artUrl.startsWith("spotify:image:")) {
                artUrl = "https://i.scdn.co/image/" + artUrl.replace("spotify:image:", "");
            }

            const uri = raw.uri || item.uri || meta.uri || "";
            return { title, artist, album, artUrl, uri };
        } catch (e) {
            return null;
        }
    }

    async function fetchUpcomingAsync() {
        try {
            // Source 1: Spicetify.Platform.PlayerAPI._queue
            if (window.Spicetify && Spicetify.Platform && Spicetify.Platform.PlayerAPI) {
                const pApi = Spicetify.Platform.PlayerAPI;
                if (pApi._queue) {
                    const list = pApi._queue.nextTracks || pApi._queue.queued || pApi._queue.contextTracks || [];
                    if (Array.isArray(list) && list.length > 0) {
                        const parsed = parseTrack(list[0]);
                        if (parsed) return parsed;
                    }
                }
                if (typeof pApi.getQueue === "function") {
                    try {
                        const q = await pApi.getQueue();
                        const list = q?.nextTracks || q?.queued || q?.contextTracks || [];
                        if (Array.isArray(list) && list.length > 0) {
                            const parsed = parseTrack(list[0]);
                            if (parsed) return parsed;
                        }
                    } catch (e) {}
                }
                if (typeof pApi.getState === "function") {
                    try {
                        const s = await pApi.getState();
                        const list = s?.nextTracks || s?.nextItems || s?.queue || [];
                        if (Array.isArray(list) && list.length > 0) {
                            const parsed = parseTrack(list[0]);
                            if (parsed) return parsed;
                        }
                    } catch (e) {}
                }
            }

            // Source 2: Spicetify.Queue
            if (window.Spicetify && Spicetify.Queue) {
                const q = Spicetify.Queue;
                const list = q.nextTracks || q.queuedTracks || q.queued || q.future || [];
                if (Array.isArray(list) && list.length > 0) {
                    const parsed = parseTrack(list[0]);
                    if (parsed) return parsed;
                }
            }

            // Source 3: Spicetify.Player.data (Context next items)
            if (window.Spicetify && Spicetify.Player && Spicetify.Player.data) {
                const d = Spicetify.Player.data;
                const list = d.next_items || d.queue || d.future_items || d.context_items || [];
                if (Array.isArray(list) && list.length > 0) {
                    const parsed = parseTrack(list[0]);
                    if (parsed) return parsed;
                }
            }

            // Source 4: Cosmos API endpoint
            if (window.Spicetify && Spicetify.CosmosAsync) {
                try {
                    const res = await Spicetify.CosmosAsync.get("sp://player/v2/main");
                    const list = res?.next_items || res?.queue || res?.future_items || [];
                    if (Array.isArray(list) && list.length > 0) {
                        const parsed = parseTrack(list[0]);
                        if (parsed) return parsed;
                    }
                } catch (e) {}
            }
        } catch (e) {}
        return null;
    }

    async function sendState(force = false) {
        try {
            if (isToggling && !force) return;
            if (!Spicetify.Player || !Spicetify.Player.data) return;
            const item = Spicetify.Player.data.item;
            const uri = item?.uri || "";
            const isHearted = getHeartState();
            const upcoming = await fetchUpcomingAsync();
            const upcomingHash = upcoming ? `${upcoming.uri || upcoming.title}_${upcoming.artist}` : "";

            if (force || uri !== lastUri || isHearted !== lastLiked || upcomingHash !== lastUpcomingHash) {
                lastUri = uri;
                lastLiked = isHearted;
                lastUpcomingHash = upcomingHash;

                const payload = {
                    isLiked: isHearted,
                    uri: uri,
                    upcoming: upcoming
                };

                const dataParam = encodeURIComponent(JSON.stringify(payload));
                fetch(`http://127.0.0.1:8999/state?data=${dataParam}&liked=${isHearted}&uri=${encodeURIComponent(uri)}`, {
                    method: "GET",
                    mode: "no-cors"
                }).catch(() => {});
            }
        } catch (e) {}
    }

    function logToBridge(msg) {
        try {
            fetch("http://127.0.0.1:8999/debug", {
                method: "POST",
                body: typeof msg === "string" ? msg : JSON.stringify(msg)
            }).catch(() => {});
        } catch (e) {}
    }

    let lastLyricsUri = "";
    let lyricsRetryTimeouts = [];

    function clearLyricsRetries() {
        for (const t of lyricsRetryTimeouts) clearTimeout(t);
        lyricsRetryTimeouts = [];
    }

    async function tryGetSpicyLyrics(uri) {
        logToBridge("tryGetSpicyLyrics for " + uri);
        if (!uri || !uri.startsWith("spotify:track:")) return null;
        const trackId = uri.split(":")[2];

        // 1. Try reading from Spicy Lyrics Browser CacheStorage
        try {
            if (window.caches) {
                const keys = await window.caches.keys();
                logToBridge("Available caches: " + JSON.stringify(keys));
                const cache = await window.caches.open("SpicyLyrics_LyricsStore_g1");
                let cachedRequests = [];
                try {
                    cachedRequests = await cache.keys();
                } catch (ke) {
                    logToBridge("cache.keys() error: " + ke.message);
                }
                logToBridge("Cache entries count: " + cachedRequests.length);
                if (cachedRequests.length > 0) {
                    logToBridge("Sample URLs: " + JSON.stringify(cachedRequests.slice(0, 3).map(r => r.url)));
                    for (const req of cachedRequests.slice(0, 40)) {
                        try {
                            const cr = await cache.match(req);
                            if (cr) {
                                const cd = await cr.json();
                                if (cd?.Content?.Type === "Syllable") {
                                    logToBridge("FOUND_SYLLABLE_TRACK: " + req.url);
                                    break;
                                }
                            }
                        } catch (e) {}
                    }
                }

                // Try both "/trackId" and full request
                let res = await cache.match("/" + trackId);
                if (!res) {
                    res = await cache.match(new Request("https://xpui.app.spotify.com/" + trackId));
                }
                if (!res) {
                    res = await cache.match(trackId);
                }
                logToBridge("Cache match for " + trackId + ": " + (res ? "HIT" : "MISS"));
                if (res) {
                    const wrapped = await res.json();
                    logToBridge("Cache JSON loaded, keys: " + JSON.stringify(Object.keys(wrapped || {})));
                    const content = wrapped?.Content || wrapped;
                    if (content && Array.isArray(content.Content) && content.Content.length > 0) {
                        const type = content.Type === "Syllable" ? "Syllable" : "Line";
                        const lines = [];

                        if (type === "Syllable") {
                            for (const item of content.Content) {
                                const lead = item.Lead;
                                if (!lead) continue;
                                const syllables = [];
                                let fullText = "";
                                if (Array.isArray(lead.Syllables)) {
                                    for (let sIdx = 0; sIdx < lead.Syllables.length; sIdx++) {
                                        const s = lead.Syllables[sIdx];
                                        const isLast = sIdx === lead.Syllables.length - 1;
                                        let stext = s.Text || "";
                                        if (!s.IsPartOfWord && !isLast && !stext.endsWith(" ")) {
                                            stext += " ";
                                        }
                                        fullText += stext;
                                        syllables.push({
                                            text: stext,
                                            startTime: Number(s.StartTime) || 0,
                                            endTime: Number(s.EndTime) || 0,
                                            isPartOfWord: Boolean(s.IsPartOfWord)
                                        });
                                    }
                                }
                                lines.push({
                                    text: fullText.trim(),
                                    startTime: Number(lead.StartTime) || 0,
                                    endTime: Number(lead.EndTime) || 0,
                                    syllables: syllables
                                });
                            }
                        } else {
                            for (const item of content.Content) {
                                lines.push({
                                    text: (item.Text || "").trim(),
                                    startTime: Number(item.StartTime) || 0,
                                    endTime: Number(item.EndTime) || 0,
                                    syllables: []
                                });
                            }
                        }

                        if (lines.length > 0) {
                            return {
                                uri: uri,
                                source: "spicy-lyrics",
                                type: type,
                                lines: lines
                            };
                        }
                    }
                }
            }
        } catch (e) {
            logToBridge("Error in cache read: " + e.message);
        }

        // 2. Fallback: Spotify's internal color-lyrics Cosmos API
        try {
            if (window.Spicetify && Spicetify.CosmosAsync) {
                const res = await Spicetify.CosmosAsync.get("sp://lyrics/v1/track/" + trackId);
                logToBridge("Cosmos lyrics response: " + (res ? "received" : "null"));
                const rawLyrics = res?.lyrics;
                if (rawLyrics && Array.isArray(rawLyrics.lines) && rawLyrics.lines.length > 0) {
                    const syncType = rawLyrics.syncType;
                    const isSyllable = syncType === "SYLLABLE_SYNCED";
                    const lines = [];

                    for (let i = 0; i < rawLyrics.lines.length; i++) {
                        const l = rawLyrics.lines[i];
                        const startMs = Number(l.startTimeMs) || 0;
                        const nextMs = i + 1 < rawLyrics.lines.length ? (Number(rawLyrics.lines[i + 1].startTimeMs) || startMs + 3000) : startMs + 4000;
                        const syllables = [];

                        if (isSyllable && Array.isArray(l.syllables) && l.syllables.length > 0) {
                            for (const s of l.syllables) {
                                syllables.push({
                                    text: s.words || s.text || "",
                                    startTime: (Number(s.startTimeMs) || startMs) / 1000.0,
                                    endTime: (Number(s.endTimeMs) || nextMs) / 1000.0,
                                    isPartOfWord: Boolean(s.isPartOfWord)
                                });
                            }
                        }

                        lines.push({
                            text: (l.words || "").trim(),
                            startTime: startMs / 1000.0,
                            endTime: nextMs / 1000.0,
                            syllables: syllables
                        });
                    }

                    if (lines.length > 0) {
                        return {
                            uri: uri,
                            source: "spotify-internal",
                            type: isSyllable ? "Syllable" : "Line",
                            lines: lines
                        };
                    }
                }
            }
        } catch (e) {
            logToBridge("Cosmos error: " + e.message);
        }

        return null;
    }

    async function sendLyrics(lyricsPayload) {
        if (!lyricsPayload) return;
        try {
            await fetch("http://127.0.0.1:8999/lyrics", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify(lyricsPayload)
            });
        } catch (e) {}
    }

    async function syncLyricsForCurrentTrack(force = false) {
        const item = Spicetify.Player.data?.item;
        const uri = item?.uri || "";
        if (!uri || !uri.startsWith("spotify:track:")) {
            clearLyricsRetries();
            lastLyricsUri = "";
            return;
        }

        if (!force && uri === lastLyricsUri) return;

        clearLyricsRetries();
        lastLyricsUri = uri;

        async function attempt(attemptNum) {
            const currentItem = Spicetify.Player.data?.item;
            if (currentItem?.uri !== uri) return;

            const lyrics = await tryGetSpicyLyrics(uri);
            if (lyrics) {
                clearLyricsRetries();
                await sendLyrics(lyrics);
            } else if (attemptNum < 8) {
                const delays = [150, 250, 400, 600, 900, 1300, 1800, 2500];
                const delay = delays[attemptNum] || 2000;
                const tid = setTimeout(() => attempt(attemptNum + 1), delay);
                lyricsRetryTimeouts.push(tid);
            }
        }

        attempt(0);
    }

    async function handleCommand(cmd) {
        if (!cmd) return;
        if (cmd.action === "eval") {
            try {
                Promise.resolve(eval(cmd.code)).then(res => {
                    logToBridge("EVAL_RESULT: " + (typeof res === "string" ? res : JSON.stringify(res)));
                }).catch(err => {
                    logToBridge("EVAL_PROMISE_ERR: " + err.message);
                });
            } catch (e) {
                logToBridge("EVAL_ERR: " + e.message);
            }
            return;
        }
        if (cmd.action === "getLyrics" || cmd.action === "reloadLyrics") {
            syncLyricsForCurrentTrack(true);
            return;
        }
        if (cmd.action === "toggleHeart" || cmd.action === "toggle") {
            if (isToggling) return;
            isToggling = true;

            const uri = Spicetify.Player.data?.item?.uri || Spicetify.Player.origin?._state?.item?.uri || lastUri;
            const current = getHeartState();
            const targetState = !current;

            try {
                if (uri && Spicetify.Platform?.LibraryAPI?.add && Spicetify.Platform?.LibraryAPI?.remove) {
                    if (targetState) {
                        Spicetify.Platform.LibraryAPI.add({ uris: [uri] });
                    } else {
                        Spicetify.Platform.LibraryAPI.remove({ uris: [uri] });
                    }
                } else if (typeof Spicetify.Player?.setHeart === "function") {
                    Spicetify.Player.setHeart(targetState);
                } else if (typeof Spicetify.Player?.toggleHeart === "function") {
                    Spicetify.Player.toggleHeart();
                } else {
                    const btn = document.querySelector('button[data-testid="add-button"], .main-nowPlayingBar-left button[data-testid="add-button"]');
                    if (btn) btn.click();
                }
            } catch (err) {}

            // Immediately broadcast optimistic target state to bridge
            lastLiked = targetState;
            const item = Spicetify.Player.data?.item;
            const trackUri = item?.uri || uri;
            fetch(`http://127.0.0.1:8999/state?data=${encodeURIComponent(JSON.stringify({ isLiked: targetState, uri: trackUri }))}&liked=${targetState}&uri=${encodeURIComponent(trackUri)}`, {
                method: "GET",
                mode: "no-cors"
            }).catch(() => {});

            // Allow Spotify's backend mutation to settle, then re-verify
            setTimeout(() => sendState(true), 350);
            setTimeout(() => {
                sendState(true);
                isToggling = false;
            }, 800);
        } else if (cmd.action === "skipNext") {
            try {
                if (typeof Spicetify.Player.next === "function") {
                    Spicetify.Player.next();
                }
            } catch (e) {}
            setTimeout(() => sendState(true), 200);
        }
    }

    async function pollCommands() {
        logToBridge("Bridge initialized v" + currentVersion);
        sendState(true);
        syncLyricsForCurrentTrack(true);
        while (window.__caelestia_bridge_version === currentVersion) {
            try {
                const res = await fetch("http://127.0.0.1:8999/poll", { cache: "no-store", mode: "cors" });
                if (window.__caelestia_bridge_version !== currentVersion) return;
                if (res.ok) {
                    const data = await res.json();
                    await handleCommand(data);
                } else {
                    await new Promise(r => setTimeout(r, 1000));
                }
            } catch (e) {
                await new Promise(r => setTimeout(r, 1000));
            }
        }
    }

    Spicetify.Player.addEventListener("songchange", () => {
        sendState(true);
        setTimeout(() => sendState(true), 350);
        setTimeout(() => sendState(true), 1000);
        syncLyricsForCurrentTrack(true);
    });
    Spicetify.Player.addEventListener("onplaypause", () => sendState(true));
    if (Spicetify.Player.addEventListener) {
        try {
            Spicetify.Player.addEventListener("queuechange", () => sendState(true));
        } catch (e) {}
    }
    try {
        if (Spicetify.Platform?.LibraryAPI?.getEvents) {
            Spicetify.Platform.LibraryAPI.getEvents().addListener("update_item", (e) => {
                if (e?.data?.uri === (Spicetify.Player?.data?.item?.uri || lastUri)) {
                    sendState(true);
                }
            });
        }
    } catch (e) {}
    const pollInterval = setInterval(() => {
        if (window.__caelestia_bridge_version !== currentVersion) {
            clearInterval(pollInterval);
            return;
        }
        sendState(false);
        syncLyricsForCurrentTrack(false);
    }, 1000);

    sendState(true);
    syncLyricsForCurrentTrack(true);
    pollCommands();
})();
