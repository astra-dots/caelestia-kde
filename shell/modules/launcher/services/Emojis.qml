pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.Services
import qs.utils

Singleton {
    id: root

    readonly property bool _loaded: EmojiDb.loaded || (emojiData && emojiData.categories && emojiData.categories.length > 0)
    readonly property int itemCount: emojiData && emojiData.all ? emojiData.all.length : EmojiDb.count

    property var emojiData: ({
        categories: [
            {"id": "recents", "name": "Recent", "icon": "schedule"},
            {"id": "smileys", "name": "Smileys & Emotion", "icon": "sentiment_satisfied"},
            {"id": "people", "name": "People & Body", "icon": "person"},
            {"id": "animals", "name": "Animals & Nature", "icon": "pets"},
            {"id": "food", "name": "Food & Drink", "icon": "lunch_dining"},
            {"id": "travel", "name": "Travel & Places", "icon": "flight"},
            {"id": "activities", "name": "Activities", "icon": "sports_esports"},
            {"id": "objects", "name": "Objects", "icon": "lightbulb"},
            {"id": "symbols", "name": "Symbols", "icon": "emergency"},
            {"id": "flags", "name": "Flags", "icon": "flag"}
        ],
        byCategory: {},
        all: []
    })

    readonly property var categories: emojiData.categories || []
    readonly property var byCategory: emojiData.byCategory || ({})
    readonly property var allEmojis: emojiData.all || []

    property list<string> recents: []

    FileView {
        id: fileView
        path: `${Quickshell.shellDir}/assets/emojis_categorized.json`
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (parsed && parsed.categories && parsed.byCategory) {
                    root.emojiData = parsed;
                }
            } catch (e) {
                console.warn("[Emojis] Could not parse emojis_categorized.json:", e);
            }
        }
    }

    FileView {
        id: recentsStorage
        path: `${Paths.state}/emoji_recents.json`
        printErrors: false
        onLoaded: {
            try {
                const parsed = JSON.parse(text());
                if (Array.isArray(parsed)) {
                    root.recents = parsed;
                }
            } catch (e) {
                root.recents = [];
            }
        }
    }

    function saveRecents(list: var): void {
        root.recents = list;
        recentsStorage.setText(JSON.stringify(list, null, 2));
    }

    function recordUsage(ch: string): void {
        if (!ch) return;
        EmojiDb.recordUsage(ch);

        const current = [...root.recents];
        const idx = current.indexOf(ch);
        if (idx !== -1) {
            current.splice(idx, 1);
        }
        current.unshift(ch);
        if (current.length > 40) {
            current.length = 40;
        }
        saveRecents(current);
    }

    function clearRecents(): void {
        saveRecents([]);
    }

    function getRecents(): var {
        const recentList = root.recents || [];
        const result = [];
        const seen = new Set();

        for (const r of recentList) {
            if (!r || seen.has(r)) continue;
            seen.add(r);
            const found = root.allEmojis.find(e => e.ch === r);
            if (found) {
                result.push(found);
            } else {
                result.push({ ch: r, name: "Recent", category: "recents" });
            }
        }

        return result;
    }

    function getItemsForCategory(categoryId: string): var {
        if (categoryId === "recents") {
            return getRecents();
        }
        return root.byCategory[categoryId] || [];
    }

    function search(text: string): var {
        if (!text || text.trim().length === 0) {
            return getRecents();
        }
        const q = text.trim().toLowerCase();
        
        const matches = [];
        for (let i = 0; i < root.allEmojis.length; i++) {
            const item = root.allEmojis[i];
            if (item.kw && item.kw.includes(q)) {
                matches.push(item);
                if (matches.length >= 250) break;
            }
        }
        
        if (matches.length > 0) return matches;

        return EmojiDb.search(q, 250);
    }
}
