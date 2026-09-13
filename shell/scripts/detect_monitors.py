#!/usr/bin/env python3
"""
Detect connected monitors and their corresponding I2C DDC bus numbers.
Checks Linux DRM sysfs first, falling back to ddcutil detect.
Outputs a JSON array of objects: [{"connector": "DP-1", "busNum": "7"}]
"""

import glob
import json
import os
import re
import subprocess
import sys

def detect():
    monitors = {}

    # 1. Inspect DRM connectors in sysfs
    for conn_path in sorted(glob.glob("/sys/class/drm/card*-*")):
        status_file = os.path.join(conn_path, "status")
        if not os.path.isfile(status_file):
            continue
        try:
            with open(status_file, "r") as f:
                if f.read().strip() != "connected":
                    continue
        except Exception:
            continue

        cname = re.sub(r"^card\d+-", "", os.path.basename(conn_path))
        bus_num = None

        # Look for i2c-N subdirectories
        for entry in os.listdir(conn_path):
            m = re.match(r"^i2c-(\d+)$", entry)
            if m:
                bus_num = m.group(1)
                break

        # Fallback to ddc symlink
        if not bus_num:
            ddc_link = os.path.join(conn_path, "ddc")
            if os.path.islink(ddc_link):
                try:
                    target = os.readlink(ddc_link)
                    m = re.search(r"i2c-(\d+)", target)
                    if m:
                        bus_num = m.group(1)
                except Exception:
                    pass

        if bus_num:
            monitors[cname] = str(bus_num)

    # 2. Check ddcutil detect --brief to supplement/discover any missing displays
    try:
        p = subprocess.run(["ddcutil", "detect", "--brief"], capture_output=True, text=True, timeout=4)
        for block in p.stdout.strip().split("\n\n"):
            bus_m = re.search(r"I2C bus:\s+/dev/i2c-(\d+)", block)
            drm_m = re.search(r"DRM connector:\s+(?:card\d+-)?([^\s]+)", block)
            if bus_m and drm_m:
                conn = drm_m.group(1)
                bus = str(bus_m.group(1))
                if conn not in monitors:
                    monitors[conn] = bus
    except Exception:
        pass

    result = [{"connector": k, "busNum": v} for k, v in monitors.items()]
    sys.stdout.write(json.dumps(result) + "\n")

if __name__ == "__main__":
    detect()
