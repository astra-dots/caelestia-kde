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
                                const lead = item.Lead || {};
                                const syls = Array.isArray(lead.Syllables) ? lead.Syllables : [];
                                const bgRaw = Array.isArray(item.Background) ? item.Background : [];

                                if (syls.length === 0 && bgRaw.length === 0 && !item.Text) continue;

                                const syllables = [];
                                let fullText = "";
                                for (let sIdx = 0; sIdx < syls.length; sIdx++) {
                                    const s = syls[sIdx];
                                    const isLast = sIdx === syls.length - 1;
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

                                // Extract background vocals (small lyrics):
                                const backgroundLines = [];
                                for (const bgItem of bgRaw) {
                                    const bgSyllables = [];
                                    let bgFullText = "";
                                    if (Array.isArray(bgItem.Syllables)) {
                                        for (let sIdx = 0; sIdx < bgItem.Syllables.length; sIdx++) {
                                            const s = bgItem.Syllables[sIdx];
                                            const isLast = sIdx === bgItem.Syllables.length - 1;
                                            let stext = s.Text || "";
                                            if (!s.IsPartOfWord && !isLast && !stext.endsWith(" ")) {
                                                stext += " ";
                                            }
                                            bgFullText += stext;
                                            bgSyllables.push({
                                                text: stext,
                                                startTime: Number(s.StartTime) || 0,
                                                endTime: Number(s.EndTime) || 0,
                                                isPartOfWord: Boolean(s.IsPartOfWord)
                                            });
                                        }
                                    }
                                    if (bgFullText.trim().length > 0 || bgSyllables.length > 0) {
                                        backgroundLines.push({
                                            text: bgFullText.trim(),
                                            startTime: Number(bgItem.StartTime) || 0,
                                            endTime: Number(bgItem.EndTime) || 0,
                                            syllables: bgSyllables
                                        });
                                    }
                                }

                                const lineStart = (lead.StartTime !== undefined) ? Number(lead.StartTime) : (Number(item.StartTime) || 0);
                                const lineEnd = (lead.EndTime !== undefined) ? Number(lead.EndTime) : (Number(item.EndTime) || 0);

                                lines.push({
                                    text: fullText.trim(),
                                    startTime: lineStart,
                                    endTime: lineEnd,
                                    syllables: syllables,
                                    oppositeAligned: Boolean(item.OppositeAligned),
                                    background: backgroundLines
                                });
                            }
                        } else {
                            for (const item of content.Content) {
                                const backgroundLines = [];
                                if (Array.isArray(item.Background)) {
                                    for (const bgItem of item.Background) {
                                        const bgText = (bgItem.Text || "").trim();
                                        if (bgText.length > 0) {
                                            backgroundLines.push({
                                                text: bgText,
                                                startTime: Number(bgItem.StartTime) || 0,
                                                endTime: Number(bgItem.EndTime) || 0,
                                                syllables: []
                                            });
                                        }
                                    }
                                }
                                lines.push({
                                    text: (item.Text || "").trim(),
                                    startTime: Number(item.StartTime) || 0,
                                    endTime: Number(item.EndTime) || 0,
                                    syllables: [],
                                    oppositeAligned: Boolean(item.OppositeAligned),
                                    background: backgroundLines
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

    // ==========================================
    // Caelestia Dynamic Theme Manager
    // ==========================================
    let currentThemeMode = localStorage.getItem("caelestia:theme_mode") || "song";
    let activeScheme = null;
    let topbarThemeBtn = null;
    let contextMenuItem = null;
    let caelestiaGradCanvas = null;

    const SVG_SONG_THEME = `<svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg>`;
    const SVG_SYSTEM_THEME = `<svg viewBox="0 0 24 24" width="16" height="16" fill="currentColor"><path d="M12 3a9 9 0 0 0 0 18c.83 0 1.5-.67 1.5-1.5 0-.39-.15-.74-.39-1.01-.23-.26-.38-.61-.38-.99 0-.83.67-1.5 1.5-1.5H16c2.76 0 5-2.24 5-5 0-4.42-4.03-8-9-8zm-5.5 9c-.83 0-1.5-.67-1.5-1.5S5.67 9 6.5 9 8 9.67 8 10.5 7.33 12 6.5 12zm3-4C8.67 8 8 7.33 8 6.5S8.67 5 9.5 5s1.5.67 1.5 1.5S10.33 8 9.5 8zm5 0c-.83 0-1.5-.67-1.5-1.5S13.67 5 14.5 5s1.5.67 1.5 1.5S15.33 8 14.5 8zm3 4c-.83 0-1.5-.67-1.5-1.5S16.67 9 17.5 9s1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/></svg>`;

    function hexToRgb(hex) {
        if (!hex) return "0,0,0";
        let c = hex.replace("#", "").trim();
        if (c.length === 3) c = c.split("").map(x => x + x).join("");
        if (c.length !== 6) return "0,0,0";
        const r = parseInt(c.substring(0, 2), 16);
        const g = parseInt(c.substring(2, 4), 16);
        const b = parseInt(c.substring(4, 6), 16);
        return `${r},${g},${b}`;
    }

    function createCaelestiaGradientCanvas(scheme) {
        if (!scheme) return null;
        const canvas = document.createElement("canvas");
        canvas.width = 512;
        canvas.height = 512;
        const ctx = canvas.getContext("2d");
        if (!ctx) return null;

        const primary = scheme.primary || "#afc8eb";
        const primaryContainer = scheme.primaryContainer || "#3c5472";
        const secondary = scheme.secondary || "#bbc7db";
        const tertiary = scheme.tertiary || "#e1d8ff";
        const surfaceContainer = scheme.surfaceContainer || "#161a1f";

        // Multi-stop liquid gradient matching Caelestia Material You
        const grad = ctx.createLinearGradient(0, 0, 512, 512);
        grad.addColorStop(0.0, primary);
        grad.addColorStop(0.32, primaryContainer);
        grad.addColorStop(0.62, tertiary);
        grad.addColorStop(0.82, secondary);
        grad.addColorStop(1.0, surfaceContainer);
        ctx.fillStyle = grad;
        ctx.fillRect(0, 0, 512, 512);

        // Soft radial highlight in upper right
        const rad = ctx.createRadialGradient(420, 90, 10, 420, 90, 320);
        rad.addColorStop(0, primary);
        rad.addColorStop(1, "rgba(0,0,0,0)");
        ctx.fillStyle = rad;
        ctx.fillRect(0, 0, 512, 512);

        return canvas;
    }

    function installKawarpShaderHook() {
        if (window._caelestiaShaderHookInstalled) return;
        window._caelestiaShaderHookInstalled = true;

        const origTexImage2D = WebGLRenderingContext.prototype.texImage2D;
        WebGLRenderingContext.prototype.texImage2D = function(...args) {
            const canvas = this.canvas;
            if (canvas && canvas.classList && canvas.classList.contains("spicy-dynamic-bg")) {
                canvas._kawarpGL = this;
                if (currentThemeMode === "system" && caelestiaGradCanvas) {
                    if (args.length === 6) {
                        args[5] = caelestiaGradCanvas;
                    }
                }
            }
            return origTexImage2D.apply(this, args);
        };
    }

    function applySystemTheme(scheme) {
        if (!scheme) return;
        activeScheme = scheme;
        caelestiaGradCanvas = createCaelestiaGradientCanvas(scheme);

        let styleEl = document.getElementById("caelestia-system-theme");
        if (!styleEl) {
            styleEl = document.createElement("style");
            styleEl.id = "caelestia-system-theme";
            document.head.appendChild(styleEl);
        }

        const p = scheme.primary || "#afc8eb";
        const onP = scheme.onPrimary || "#29425f";
        const pC = scheme.primaryContainer || "#3c5472";
        const onPC = scheme.onPrimaryContainer || "#d3e5ff";
        const s = scheme.secondary || "#bbc7db";
        const onS = scheme.onSecondary || "#354151";
        const sC = scheme.secondaryContainer || "#303c4c";
        const onSC = scheme.onSecondaryContainer || "#b4c0d4";
        const t = scheme.tertiary || "#e1d8ff";
        const onT = scheme.onTertiary || "#504972";
        const tC = scheme.tertiaryContainer || "#d3c8f9";
        const onTC = scheme.onTertiaryContainer || "#484068";
        const err = scheme.error || "#fa746f";
        const surf = scheme.surface || "#0c0e12";
        const surfLow = scheme.surfaceContainerLow || "#101418";
        const surfC = scheme.surfaceContainer || "#161a1f";
        const surfHigh = scheme.surfaceContainerHigh || "#1c2026";
        const surfHighest = scheme.surfaceContainerHighest || "#21262d";
        const bg = scheme.background || "#0c0e12";
        const onBg = scheme.onBackground || "#e1e5ef";
        const onSurf = scheme.onSurface || "#e1e5ef";
        const surfVar = scheme.surfaceVariant || "#21262d";
        const onSurfVar = scheme.onSurfaceVariant || "#a7abb4";
        const outline = scheme.outline || "#71767e";
        const outlineVar = scheme.outlineVariant || "#434850";

        styleEl.textContent = `
            :root {
                --clr-primary: ${p} !important;
                --clr-primary-rgb: ${hexToRgb(p)} !important;
                --clr-on-primary: ${onP} !important;
                --clr-on-primary-rgb: ${hexToRgb(onP)} !important;
                --clr-primary-container: ${pC} !important;
                --clr-primary-container-rgb: ${hexToRgb(pC)} !important;
                --clr-on-primary-container: ${onPC} !important;
                --clr-on-primary-container-rgb: ${hexToRgb(onPC)} !important;
                --clr-secondary: ${s} !important;
                --clr-secondary-rgb: ${hexToRgb(s)} !important;
                --clr-on-secondary: ${onS} !important;
                --clr-on-secondary-rgb: ${hexToRgb(onS)} !important;
                --clr-secondary-container: ${sC} !important;
                --clr-secondary-container-rgb: ${hexToRgb(sC)} !important;
                --clr-on-secondary-container: ${onSC} !important;
                --clr-on-secondary-container-rgb: ${hexToRgb(onSC)} !important;
                --clr-tertiary: ${t} !important;
                --clr-tertiary-rgb: ${hexToRgb(t)} !important;
                --clr-on-tertiary: ${onT} !important;
                --clr-on-tertiary-rgb: ${hexToRgb(onT)} !important;
                --clr-tertiary-container: ${tC} !important;
                --clr-tertiary-container-rgb: ${hexToRgb(tC)} !important;
                --clr-on-tertiary-container: ${onTC} !important;
                --clr-on-tertiary-container-rgb: ${hexToRgb(onTC)} !important;
                --clr-error: ${err} !important;
                --clr-error-rgb: ${hexToRgb(err)} !important;
                --clr-surface: ${surf} !important;
                --clr-surface-rgb: ${hexToRgb(surf)} !important;
                --clr-surface-1: ${surfLow} !important;
                --clr-surface-1-rgb: ${hexToRgb(surfLow)} !important;
                --clr-surface-2: ${surfC} !important;
                --clr-surface-2-rgb: ${hexToRgb(surfC)} !important;
                --clr-surface-3: ${surfHigh} !important;
                --clr-surface-3-rgb: ${hexToRgb(surfHigh)} !important;
                --clr-surface-4: ${surfHighest} !important;
                --clr-surface-4-rgb: ${hexToRgb(surfHighest)} !important;
                --clr-background: ${bg} !important;
                --clr-background-rgb: ${hexToRgb(bg)} !important;
                --clr-on-background: ${onBg} !important;
                --clr-on-background-rgb: ${hexToRgb(onBg)} !important;
                --clr-on-surface: ${onSurf} !important;
                --clr-on-surface-rgb: ${hexToRgb(onSurf)} !important;
                --clr-surface-variant: ${surfVar} !important;
                --clr-surface-variant-rgb: ${hexToRgb(surfVar)} !important;
                --clr-on-surface-variant: ${onSurfVar} !important;
                --clr-on-surface-variant-rgb: ${hexToRgb(onSurfVar)} !important;
                --clr-outline: ${outline} !important;
                --clr-outline-rgb: ${hexToRgb(outline)} !important;
                --clr-outline-variant: ${outlineVar} !important;
                --clr-outline-variant-rgb: ${hexToRgb(outlineVar)} !important;

                --spice-text: ${onSurf} !important;
                --spice-subtext: ${onSurfVar} !important;
                --spice-main: ${surfC} !important;
                --spice-sidebar: ${surf} !important;
                --spice-card: ${surfHigh} !important;
                --spice-player: ${sC} !important;
                --spice-main-elevated: ${surfHigh} !important;
                --spice-highlight-elevated: ${surfHighest} !important;
                --spice-selected-row: ${onSurf} !important;
                --spice-button: ${p} !important;
                --spice-button-active: ${p} !important;
                --spice-button-disabled: ${outline} !important;
                --spice-tab-active: ${surfHigh} !important;
                --spice-notification: ${outline} !important;
                --spice-notification-error: ${err} !important;
            }

            html.caelestia-system-mode .lucid-bg .bg.static,
            html.caelestia-system-mode .lucid-bg .bg.animated {
                opacity: 0 !important;
                visibility: hidden !important;
            }
            html.caelestia-system-mode .lucid-bg {
                background: radial-gradient(ellipse at 50% -20%, ${surfHigh} 0%, ${surfC} 45%, ${surf} 100%) !important;
            }
            html.caelestia-system-mode .lucid-bg .bg-wrapper {
                background: transparent !important;
            }
            #caelestia-topbar-theme-btn svg {
                color: ${p} !important;
            }
        `;

        document.documentElement.classList.add("caelestia-system-mode");
    }

    function removeSystemTheme() {
        const styleEl = document.getElementById("caelestia-system-theme");
        if (styleEl) styleEl.remove();
        document.documentElement.classList.remove("caelestia-system-mode");
    }

    function refreshBackgrounds() {
        document.querySelectorAll(".spicy-dynamic-bg").forEach(el => {
            el.removeAttribute("data-cover-id");
        });

        // Trigger a gentle skip/seek cycle or event so Spicy Lyrics re-evaluates
        if (Spicetify.Player && Spicetify.Player.dispatchEvent) {
            Spicetify.Player.dispatchEvent({ type: "songchange", data: Spicetify.Player.data });
        }
    }

    function updateTopbarButton() {
        const isSystem = (currentThemeMode === "system");
        const tooltip = isSystem
            ? "Theme: System Colors (Click for Song Colors)"
            : "Theme: Song Colors (Click for System Colors)";
        const icon = isSystem ? SVG_SYSTEM_THEME : SVG_SONG_THEME;

        if (topbarThemeBtn) {
            topbarThemeBtn.label = tooltip;
            topbarThemeBtn.icon = icon;
            if (topbarThemeBtn.element) {
                topbarThemeBtn.element.setAttribute("title", tooltip);
            }
            if (topbarThemeBtn.tippy) {
                topbarThemeBtn.tippy.setContent(tooltip);
            }
        }
        if (contextMenuItem) {
            contextMenuItem.name = isSystem
                ? "Theme: System Colors (Switch to Song)"
                : "Theme: Song Colors (Switch to System)";
        }
    }

    function setThemeMode(mode, scheme, notifyBridge = true) {
        if (mode !== "song" && mode !== "system") return;
        currentThemeMode = mode;
        try {
            localStorage.setItem("caelestia:theme_mode", mode);
        } catch (e) {}

        if (scheme) {
            activeScheme = scheme;
        }

        if (currentThemeMode === "system") {
            if (!activeScheme) {
                fetch("http://127.0.0.1:8999/scheme")
                    .then(r => r.json())
                    .then(s => {
                        applySystemTheme(s);
                        refreshBackgrounds();
                        updateTopbarButton();
                    }).catch(() => {});
            } else {
                applySystemTheme(activeScheme);
                refreshBackgrounds();
            }
        } else {
            removeSystemTheme();
            refreshBackgrounds();
        }

        updateTopbarButton();

        if (notifyBridge) {
            fetch("http://127.0.0.1:8999/theme-mode", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ mode: currentThemeMode })
            }).catch(() => {});
        }
    }

    function toggleThemeMode() {
        const nextMode = (currentThemeMode === "system") ? "song" : "system";
        setThemeMode(nextMode, activeScheme, true);
    }

    function initThemeControls() {
        installKawarpShaderHook();

        // Create Spicetify Topbar Button
        if (Spicetify.Topbar && typeof Spicetify.Topbar.Button === "function") {
            try {
                topbarThemeBtn = new Spicetify.Topbar.Button(
                    currentThemeMode === "system" ? "Theme: System Colors" : "Theme: Song Colors",
                    currentThemeMode === "system" ? SVG_SYSTEM_THEME : SVG_SONG_THEME,
                    () => toggleThemeMode()
                );
                if (topbarThemeBtn.element) {
                    topbarThemeBtn.element.id = "caelestia-topbar-theme-btn";
                }
            } catch (e) {}
        }

        // Create Spicetify Menu Item
        if (Spicetify.Menu && typeof Spicetify.Menu.Item === "function") {
            try {
                contextMenuItem = new Spicetify.Menu.Item(
                    currentThemeMode === "system" ? "Theme: System Colors (Switch to Song)" : "Theme: Song Colors (Switch to System)",
                    false,
                    () => toggleThemeMode()
                );
                contextMenuItem.register();
            } catch (e) {}
        }

        updateTopbarButton();

        // Initial sync with bridge
        fetch("http://127.0.0.1:8999/theme-mode")
            .then(r => r.json())
            .then(data => {
                if (data && data.scheme) {
                    activeScheme = data.scheme;
                    caelestiaGradCanvas = createCaelestiaGradientCanvas(data.scheme);
                }
                const preferredMode = data?.mode || currentThemeMode;
                setThemeMode(preferredMode, data?.scheme, false);
            }).catch(() => {
                if (currentThemeMode === "system") {
                    setThemeMode("system", null, false);
                }
            });
    }

    async function handleCommand(cmd) {
        if (!cmd || !cmd.action || cmd.action === "none") return;
        if (cmd.action === "eval" && cmd.code) {
            try {
                const res = (0, eval)(cmd.code);
                Promise.resolve(res).then(val => {
                    if (val !== undefined) logToBridge("EVAL_RES: " + JSON.stringify(val));
                }).catch(err => {
                    logToBridge("EVAL_PROMISE_ERR: " + err.message);
                });
            } catch (e) {
                logToBridge("EVAL_ERR: " + e.message);
            }
            return;
        }
        if (cmd.action === "setThemeMode") {
            if (cmd.mode) {
                setThemeMode(cmd.mode, cmd.scheme, false);
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
        initThemeControls();
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
