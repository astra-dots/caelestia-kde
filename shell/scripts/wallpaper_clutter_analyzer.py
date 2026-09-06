#!/usr/bin/env python3
"""
Wallpaper Clutter & Busyness Analyzer for Caelestia Desktop Clock
Calculates edge density and texture entropy across 9 screen sectors to find the cleanest placement.
"""

import sys
import os
import numpy as np
from PIL import Image, ImageFilter

def get_current_wallpaper_path():
    candidates = [
        os.path.expanduser("~/.local/state/caelestia/wallpaper/path.txt"),
        os.path.expanduser("~/.config/caelestia/wallpaper.png"),
        os.path.expanduser("~/.local/share/caelestia/state/wallpaper/path.txt"),
        os.path.expanduser("~/.config/quickshell/caelestia/assets/wallpapers/default.png")
    ]
    for p in candidates:
        if os.path.isfile(p):
            if p.endswith(".txt"):
                try:
                    with open(p) as f:
                        path = f.read().strip()
                        if os.path.isfile(path):
                            return path
                except Exception:
                    pass
            else:
                return p
    return ""

def analyze_wallpaper(image_path):
    if not image_path or not os.path.isfile(image_path):
        image_path = get_current_wallpaper_path()

    if not image_path or not os.path.isfile(image_path):
        return "top-left"

    try:
        img = Image.open(image_path).convert('L')
    except Exception:
        fallback = get_current_wallpaper_path()
        if fallback and fallback != image_path and os.path.isfile(fallback):
            try:
                img = Image.open(fallback).convert('L')
            except Exception:
                return "top-left"
        else:
            return "top-left"

    try:
        # Fast downsample to 160x90 thumbnail
        img_thumb = img.resize((160, 90), Image.Resampling.BILINEAR)
        edges = img_thumb.filter(ImageFilter.FIND_EDGES)
        arr = np.array(edges, dtype=np.float32)

        h, w = arr.shape
        grid_scores = {}
        positions = [
            ('top-left', 0, 0), ('top-center', 0, 1), ('top-right', 0, 2),
            ('middle-left', 1, 0), ('middle-center', 1, 1), ('middle-right', 1, 2),
            ('bottom-left', 2, 0), ('bottom-center', 2, 1), ('bottom-right', 2, 2)
        ]

        for name, r, c in positions:
            sub = arr[r*(h//3):(r+1)*(h//3), c*(w//3):(c+1)*(w//3)]
            # Clean score: average edge brightness in sector (lower = emptier/cleaner)
            score = np.mean(sub)
            grid_scores[name] = float(score)

        best_pos = min(grid_scores, key=grid_scores.get)
        return best_pos
    except Exception as e:
        sys.stderr.write(f"Error analyzing wallpaper: {e}\n")
        return "top-left"

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 and sys.argv[1] else ""
    best_pos = analyze_wallpaper(path)
    print(best_pos)
