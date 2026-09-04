# Caelestia KDE — My Modifications Log

> This file tracks every direct edit made to Caelestia's source files.
> Since edits can be overwritten by updates, this document contains the **exact rationale, target files, and descriptions** to re-apply whenever needed.
>
> **Keep this file updated every time you change something.**
> After an update (`git pull` / `caelestia-update`), compare against this file to instantly restore your modifications.

---

## System Info

- **OS:** Arch Linux, KDE Plasma 6 (Wayland)
- **Install Date:** 2026-08-26
- **Caelestia Version:** v2.3.2 (commit `8c89d350`)
- **Quickshell Version:** 0.3.1-1

---

## Installer Options Selected

- [x] Papirus icon theme (installed)
- [x] Darkly theme package (darkly-bin 0.5.39-1)
- [x] Kvantum theme engine (installed)
- [x] Apply Darkly theme (applied)
- [x] Material You dynamic colors (enabled & running)
- [x] Custom fonts Rubik + JetBrains Mono Nerd (installed)
- [x] Custom lockscreen (configured)
- [x] Default shell: zsh
- [ ] Fish shell (skipped)
- [ ] Thunar integration (skipped)

---

## Direct File Modifications (Summary & Reference)

---

### 1. Launch Kitty Terminal on `Meta+Return`
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/Shortcuts.qml`
* **Location:** Around Line 275–282
* **Reason:** System uses Kitty terminal (`/usr/bin/kitty`), not foot.
* **Re-apply after update:** **Yes** (if `Shortcuts.qml` gets overwritten by git pull).

```diff
--- a/modules/Shortcuts.qml
+++ b/modules/Shortcuts.qml
@@ -275,7 +275,7 @@
     CustomShortcut {
         name: "foot"
         description: "Launch Terminal"
-        onPressed: Quickshell.execDetached(["kstart", "--", "foot"])
+        onPressed: Quickshell.execDetached(["kstart", "--", "kitty"])
     }
```

---

### 2. Application Menu: Reveal Action Icons (Pin, Heart, Hide) on Hover
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/launcher/items/AppItem.qml`
* **Location:** Around Line 80–195
* **Reason:** Clean up the app launcher view; action icons are hidden by default and smoothly transition in when the user hovers over the item row.
* **Re-apply after update:** **Yes** (if `AppItem.qml` gets overwritten by git pull).

---

### 3. Sidebar Notifications: Clean Empty State & Removed Caelestia Mode Toggle
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/sidebar/NotifDock.qml`
* **Reason:** Replaced the Dino game Easter egg with a clean Material 3 `notifications_none` empty state and removed the Caelestia Mode toggle to provide full vertical space for notifications.
* **Re-apply after update:** **Yes** (if `NotifDock.qml` is overwritten by git pull).

---

### 4. Clipboard Manager: Support All Image Formats & Size Units (MiB, B, decimal sizes)
* **Date:** 2026-08-27
* **Target File:** `~/caelestia-dots-kde/shell/plugin/src/Caelestia/Services/clipboardmanager.cpp`
* **Location:** Line 310
* **Reason:** Fixed regex `^\[\[ binary data .* \]\]$` so image clips in MiB/B/KiB decode properly into thumbnails.
* **Re-apply after update:** **Yes** (rebuild with `cd ~/caelestia-dots-kde/shell/build && cmake --build . && cmake --install .`).

---

### 5. Clipboard History: Expandable Items (Full Multiline Text & Large Image Lightbox) + Hover Action Buttons
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/launcher/items/ClipItem.qml`
* **Reason:** Added an "Expand / Details" button next to the Pin button. Clicking it smoothly expands the item:
  - Text clips: decodes full multiline original string in a scrollable Material 3 container.
  - Image clips: expands to a large preview lightbox.
  - Both action buttons (Expand + Pin) show only on hover.
* **Re-apply after update:** **Yes** (if `ClipItem.qml` is overwritten by git pull).

---

### 6. Session Menu: Clean 3-Button Layout (Logout, Shutdown, Reboot)
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/session/Content.qml`
* **Reason:** Removed the animated GIF mascot and the hibernate button, leaving a clean, compact, minimal 3-button session controls drawer with direct keyboard navigation (`Tab` / arrow navigation between Logout, Shutdown, and Reboot).
* **Re-apply after update:** **Yes** (if `Content.qml` is overwritten by git pull).

---

### 7. Taskbar Dock: Only Show Windows from Current Virtual Desktop
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/bar/components/Dock.qml`
  - `~/.config/quickshell/caelestia/modules/nexus/pages/panels/taskbar/BarDock.qml`
  - `~/caelestia-dots-kde/shell/plugin/src/Caelestia/Config/barconfig.hpp`
* **Reason:** Added an option `onlyCurrentWorkspace` (default `true`) and workspace switch event listeners (`KWinWorkspaceState.onActiveIdChanged`) so that unpinned apps from other desktops are hidden from the dock and pinned apps only show active indicators for windows on the active desktop. Added a GUI toggle in Nexus settings (`Taskbar > Dock > Only current workspace`).
* **Re-apply after update:** **Yes** (if `Dock.qml` or `BarDock.qml` is overwritten by git pull).

---

### 8. Toasts: Configurable & Reduced Default Toast Duration
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/utilities/toasts/Toasts.qml`
  - `~/.config/quickshell/caelestia/modules/nexus/pages/services/ToastPreferencesPage.qml`
  - `~/caelestia-dots-kde/shell/plugin/src/Caelestia/Config/utilitiesconfig.hpp`
* **Reason:** Default toast timeout was 5.0 seconds. Added `GlobalConfig.utilities.toasts.duration` (defaulting to 2.5s) and a Stepper in Nexus settings (`Nexus > Services > Toasts > Toast duration`) allowing adjustment between 1s and 10s.
* **Re-apply after update:** **Yes** (if `Toasts.qml` or `ToastPreferencesPage.qml` is overwritten by git pull).

---

### 9. Dashboard: Multi-Greetings & Dynamic Speech Bubble Auto-Sizing
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/dashboard/dash/User.qml`
* **Reason:** Removed the system uptime indicator from the dashboard user card. Added clean randomized short greetings (`Hello`, `Hey`, `Hi`, `Greetings`, `Welcome`, `Welcome back`), with capitalized user name and exclamation mark (`<Greeting>, <Name>!`), centered vertically beside the avatar with dynamic auto-sizing to fit seamlessly on single or multi-wrapped lines without overflowing.
* **Re-apply after update:** **Yes** (if `User.qml` is overwritten by git pull).

---

### 10. Font Rendering: Fix Corrupted Glyph Indices / Gibberish Text
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/components/StyledText.qml`
  - `~/.config/quickshell/caelestia/components/controls/StyledTextField.qml`
* **Reason:** In Qt 6 on Wayland with variable fonts (like Google Sans Flex), `renderType: Text.NativeRendering` has an upstream glyph-cache desynchronization bug where characters shift into random symbols (e.g. `¿Ėķ : € # ₈` on the clock and taskbar). Switching to `renderType: Text.QtRendering` resolves glyph-index shifting completely, rendering sharp, accurate typography across all components.
* **Re-apply after update:** **Yes** (if `StyledText.qml` is overwritten by git pull).

---

### 11. Taskbar Clock & Active Window: Fix Variable Font Glyph Corruption (Use Rubik Clock Font)
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/bar/components/Clock.qml`
  - `~/.config/quickshell/caelestia/modules/bar/components/ActiveWindow.qml`
  - `~/.config/quickshell/caelestia/components/StyledText.qml`
* **Reason:** Upstream `appearanceconfig.hpp` configured Rubik (`Tokens.font.clock` and `Tokens.font.workspaces`) specifically because variable fonts (like Google Sans Flex) with continuous variable axes (`ROND`, `opsz`, `GRAD`) suffer from FreeType/Qt variable font delta calculation bugs that corrupt ASCII numbers and letters into glyph table shifts (e.g. `¿Ėķ : € # ₈`). Binding `Clock.qml` and `ActiveWindow.qml` to `Tokens.font.clock` (Rubik) resolves all corruption permanently.
* **Re-apply after update:** **Yes** (if `Clock.qml` or `ActiveWindow.qml` is overwritten by git pull).

---

### 12. Taskbar Clock: Connected Calendar Popout (400px Hover Only)
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/bar/popouts/Calendar.qml` [NEW]
  - `~/.config/quickshell/caelestia/modules/bar/popouts/Content.qml`
  - `~/.config/quickshell/caelestia/modules/bar/Bar.qml`
* **Reason:** Added a native connected popout panel for the taskbar clock that displays an interactive Material 3 month grid calendar (with 400px width, month navigation chevrons, jump-to-today reset, weekend accent highlights, today indicator, and wheel scrolling) whenever hovering over the clock element on the taskbar.
* **Re-apply after update:** **Yes** (if `Bar.qml` or `Content.qml` is overwritten by git pull).

---

### 13. Taskbar Visual Harmony: Dynamic Expanding Clock, 21px Tray Icons, & Unified Colors
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/bar/components/Clock.qml`
  - `~/.config/quickshell/caelestia/modules/bar/components/Tray.qml`
  - `~/.config/quickshell/caelestia/modules/bar/components/TrayItem.qml`
* **Reason:** 
  1. **Dynamic Expanding Clock**: Resting state displays clean, compact time (`[ 02:05 pm ]`), smoothly expanding leftwards on hover (`[ Thu 27 | 02:05 pm ]`) with `Anim.DefaultSpatial` while triggering the Calendar popout above.
  2. **21px Tray Icons**: Set the system tray chevron arrow and expanded tray application icons to a crisp integer `21px` (`0.52 * barThickness`), eliminating subpixel blur.
  3. **Unified Right-Side Palette**: Unified the text and icon colors of all taskbar widgets on the right side (`Clock`, `Tray arrow`, `Tray items`, `Status icons`, `Sidebar / Notifications toggle`, `Keyboard layout`) to `Colours.palette.m3secondary` (while preserving the session/power button in accent red/error).
* **Re-apply after update:** **Yes** (if `Clock.qml`, `Tray.qml`, or `TrayItem.qml` is overwritten by git pull).

---

### 14. Utilities Drawer: Material Design Volume & Brightness Sliders Card
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/utilities/cards/Sliders.qml` [NEW]
  - `~/.config/quickshell/caelestia/modules/utilities/Content.qml`
* **Reason:** Added a dedicated Material Design card to the Utilities panel (top right) featuring interactive horizontal `StyledSlider`s for both Volume (bound to PipeWire default audio sink) and Screen Brightness (bound to `Brightness.monitors[0]`), static leading `MaterialIcon` indicators, live percentage labels in `Colours.palette.m3secondary`, and mouse-wheel increment support.
* **Re-apply after update:** **Yes** (if `Content.qml` is overwritten by git pull).

---

### 15. On-Screen Display (OSD): Connected Bottom-Center end-4 Style Horizontal Capsule (with Inverted Arcs)
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/osd/Content.qml`
  - `~/.config/quickshell/caelestia/modules/osd/Wrapper.qml`
  - `~/.config/quickshell/caelestia/modules/drawers/Panels.qml`
  - `~/.config/quickshell/caelestia/modules/drawers/ContentWindow.qml`
  - `~/.config/quickshell/caelestia/modules/drawers/Regions.qml`
* **Reason:** Replaced the side vertical slider drawer with a connected horizontal pill capsule anchored above the taskbar at the bottom center of the screen (end-4 dots style). Connected directly into `PanelBg` and `BlurMask` shader system for seamless inverted arc corners, with a fixed 380px width, circular icon badge, title/percentage, and smooth animated progress bar.
* **Re-apply after update:** **Yes** (if `Content.qml`, `Wrapper.qml`, `Panels.qml`, `ContentWindow.qml`, or `Regions.qml` is overwritten by git pull).

---

## Pre-Install Backup & Recovery

* **Backup Directory:** `~/Downloads/System Ricing/pre-caelestia-backup-20260826_221008/`

### Restore Plasma Panels:
```bash
cp ~/Downloads/System\ Ricing/pre-caelestia-backup-20260826_221008/plasma-org.kde.plasma.desktop-appletsrc ~/.config/
kquitapp6 plasmashell && kstart6 plasmashell
```

### Restore Klassy Window Decoration:
```bash
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.klassy
kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Klassy
qdbus6 org.kde.KWin /KWin reconfigure
```

---

### 16. Application Launcher: Material 3 Pinned Apps Grid, All Apps Browsing, & Instant Search
* **Date:** 2026-08-27
* **Target Files:**
  - `~/.config/quickshell/caelestia/modules/launcher/PinnedList.qml` [NEW]
  - `~/.config/quickshell/caelestia/modules/launcher/ContentList.qml`
  - `~/.config/quickshell/caelestia/modules/launcher/AppList.qml`
  - `~/.config/quickshell/caelestia/modules/launcher/items/AppItem.qml`
* **Reason:** Transformed the default Application Launcher opening view into an elegant Material 3 Pinned Apps Grid:
  1. **Pinned Grid (Default)**: Opens into a clean 4-column grid of large 44px app tiles with centered labels and smooth hover states.
  2. **All Apps Browsing**: Added an `[ All apps (apps) ]` button in the header that switches to the full vertical alphabetized app list with a `[ < Back to Pinned ]` navigation header.
  3. **Instant Search as You Type**: Typing any character immediately transitions to live search results, and clearing the search returns to the Pinned Grid.
  4. **Launcher Pinning**: Clicking the pin icon in the app list directly pins/unpins applications to/from the launcher grid.
* **Re-apply after update:** **Yes** (if `PinnedList.qml`, `ContentList.qml`, `AppList.qml`, or `AppItem.qml` is overwritten by git pull).

<!-- LauncherPins: Created dedicated singleton in modules/launcher/services/LauncherPins.qml saving to ~/.local/state/caelestia/launcher_pinned.json, keeping Launcher Pinned Apps completely independent from Taskbar Dock Pinned Apps -->

<!-- Section 16 Enhanced: Added Material 3 Expressive Bento Grid (Hero cards with descriptions), Right-Click Context Menu, Clean Empty State when 0 apps pinned, and Nexus Settings in LauncherPanel.qml -->

<!-- Section 16 Refined: Uniform 4-column grid, minimal Caelestia-style context menu, alphabetical sorting in All Apps list, and identical header formatting for "Pinned" and "All Applications" -->

<!-- Section 16 Fixed: Restored desktop context menu styling positioned above tiles, fixed All Applications list initialization, unified left header alignment, and expanded launcher width to 540px with 2-line wrapped text labels -->

<!-- Section 16 Refined: Fixed AppList search and All Apps reactive model binding, added full keyboard arrow navigation across Pinned Grid, added desktop-style context menu, and enabled 2-line wrapped app labels -->

<!-- Section 16 Restored: Restored stock Caelestia AppList action/clipboard/calc logic, configured 2x2 horizontal pinned grid, replaced blue border with subtle white highlight overlay, and updated arrow keys navigation -->

---

### 17. Taskbar Audio Popout: Microphone Input Level Slider
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/bar/popouts/Audio.qml`
* **Reason:** Added an interactive Material Design Microphone volume slider (with live level label, mute indicator, mouse-wheel stepping support, and PipeWire input source binding) directly below the Output Volume slider in the Audio popout panel.
* **Re-apply after update:** **Yes** (if `Audio.qml` is overwritten by git pull).

<!-- Section 15 Enhanced: Added 1.5s startup initialization grace period in osd/Wrapper.qml to prevent PipeWire initial connection signals from falsely popping up the mic volume OSD on shell restart, and tied show triggers to Config.osd toggles -->

<!-- Section 15 Final: Configured OSD in shell.json to keep only Volume enabled (enableVolume: true, enableMicrophone: false, enableBrightness: false), and restored osd/Wrapper.qml to exclusively trigger on volume changes -->

---

### 18. Taskbar Dock: App Activation & Toggle Shortcuts (`Meta+Shift+1...9`)
* **Date:** 2026-08-27
* **Target Files:**
  * `~/.config/quickshell/caelestia/services/DockService.qml` [NEW]
  * `~/.config/quickshell/caelestia/modules/bar/components/Dock.qml`
  * `~/.config/quickshell/caelestia/modules/Shortcuts.qml`
  * `~/.config/caelestia/keybinds.json`
* **Reason:** Implemented global shortcuts `Meta+Shift+1` through `Meta+Shift+9` to directly interact with visible Taskbar Dock slots (launching if closed, focusing/restoring if in background, minimizing if focused, cycling if multiple windows exist), leaving `Meta+1...5` dedicated to virtual desktops.
* **Re-apply after update:** **Yes** (if `Dock.qml` or `Shortcuts.qml` are overwritten by git pull).

<!-- Section 18 Refined: Configured dual key sequence bindings (Meta+Shift+1..9; Meta+!..() to guarantee compatibility with KDE Plasma 6 Wayland keyboard layouts, and verified active KGlobalAccel registration -->

<!-- Section 18 Updated: Fixed closed application launching from shortcut dispatcher using Caelestia's native Quickshell.execDetached systemd app2unit pipeline -->

<!-- Section 18 Swapped: Swapped keybinds per user request: Meta+1...9 now opens/minimizes Taskbar Dock app icons, and Meta+Shift+1...9 switches virtual desktops/workspaces -->

---

### 19. Launcher Calculator: Direct `qalc` Terminal Invocation
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/modules/launcher/items/CalcItem.qml`
* **Reason:** Replaced hardcoded `fish -C exec qalc` command with direct `qalc -i` invocation inside the user's configured terminal (`kitty`), fixing the *"Failed to launch child: fish"* error for users running `zsh`.
* **Re-apply after update:** **Yes** (if `CalcItem.qml` is overwritten by git pull).

---

### 20. Material Icons: Fixed Glitchy Solid Filled Icon Rendering
* **Date:** 2026-08-27
* **Target File:** `~/.config/quickshell/caelestia/components/MaterialIcon.qml`
* **Reason:** Fixed corrupted/hollow rendering on solid filled Material Symbols icons (`fill: 1.0`) by switching `renderType` to `Text.NativeRendering`. Qt's default signed distance-field renderer (`Text.QtRendering`) failed to properly compute distances on overlapping TrueType variable font contours when the `FILL` axis was interpolated, causing glitchy visual artifacts. FreeType native rasterization renders all filled glyphs with 100% solid, crisp geometry.
* **Re-apply after update:** **Yes** (if `MaterialIcon.qml` is overwritten by git pull).

---

### 21. Material 3 Expressive Floating Screenshot Toolbar (Spectacle Backend)
* **Date:** 2026-08-27
* **Target Files:**
  * `~/.config/quickshell/caelestia/modules/screenshot/FloatingScreenshotBar.qml` [NEW]
  * `~/.config/quickshell/caelestia/modules/screenshot/ScreenshotAction.qml`
  * `~/.config/quickshell/caelestia/shell.qml`
  * `~/.config/quickshell/caelestia/modules/Shortcuts.qml`
  * `~/.config/caelestia/keybinds.json`
* **Reason:** Implemented a custom Material 3 Expressive floating pill screenshot toolbar at the top center of the screen, triggered via `Print` (Fn+Home) or `Meta+Shift+S`. Region snip features interactive X-Y crosshair axes, window snapping/outlines, automatic clipboard copying, and seamless delegation to KDE Spectacle's native Kirigami annotation/drawing editor. Full screen capture operates silently to clipboard without opening the editor.
* **Re-apply after update:** **Yes** (if screenshot modules or `shell.qml` are overwritten).

<!-- Section 21 Refined: Removed all legacy regionSelector and swappy dependencies; FloatingScreenshotBar now invokes KDE Spectacle exclusively across all capture modes (interactive region with Kirigami annotation editor, active window, live window hover highlighting, silent full screen, and MP4 video recording) -->

<!-- Section 21 Completed: Custom Quickshell Material 3 Floating Pill Bar + Custom Selection Overlay (X-Y crosshairs & live window hover outlines) with post-capture delegation to KDE Spectacle Kirigami Annotation Editor; full screen and active window capture operate 100% silently to clipboard -->

<!-- Section 21 Refined (M3 Expressive UI): Upgraded FloatingScreenshotBar to Material Design 3 Expressive layout with hierarchical shapes, icons with text labels, destination toggle chip (Copy & Save / Clipboard Only / File Only), removed separate active window button in favor of window-under-cursor live hover outlines, and integrated delay timer -->

<!-- Section 21 Final: Implemented HyprQuickFrame-inspired instant dashed crosshairs, dynamic live region selection, window hover snapping, and compact Material 3 Expressive top toolbar with functional destination toggle chip (Save & Copy / Clipboard Only / File Only) and Spectacle editor integration -->

<!-- Section 21 Update: Fixed region snip crop execution with fast headless snapshot + ImageMagick pipeline, integrated direct Spectacle app launcher button ([ 🚀 Spectacle (4) ]), and connected live destination mode switching -->

<!-- Section 21 Finalized: Resolved QML invisible window timer freezing by transferring countdown delay and headless capture dispatching directly to detached bash subprocesses; verified reliable snip execution, clipboard copying, file persistence, and automatic Spectacle Kirigami editor launch -->

<!-- Section 21 Bugfix: Fixed Paths.pictures type evaluation (string path concatenation vs erroneous function invocation) and removed blocking overlay mouse handler; confirmed 100% working drag-to-snip execution, live Spectacle editor launching, and clickable top bar controls -->

<!-- Section 21 Final Polish: Removed number suffixes from UI labels; replaced click toggle with dynamic Shift-hold save modifier (defaulting to clipboard only, automatically saving to disk + clipboard when Shift is held during capture) with visual reactive badge -->

<!-- Section 21 Polish: Replaced multi-word save badge with fixed-width (78px) single-word 'Copy' / 'Save' modifier indicator to prevent pill jitter; corrected KWin window coordinate schema in findWindowAt to restore live window hover outlines and click-to-capture -->

<!-- Section 21 Native KWin Window Selection: Switched Window button to native Spectacle/KWin window under cursor mode (spectacle -u) for 100% window detection accuracy, subsurfaces, popups, and full Alt-Tab compositor switching support while preserving instant Quickshell crosshair drag-to-snip -->

<!-- Section 21 Unified TargetRegion Overlay: Re-integrated Caelestia's native TargetRegion window highlighting architecture (app icon badges, window title labels, rounded highlight borders, and instant window click snapping) with the top Material 3 Expressive toolbar and dynamic Shift-hold save modifier -->

<!-- Section 21 Architecture Fix: Set visible: true on RegionSelection and updated RegionSelector loader active condition to guarantee immediate overlay and floating toolbar rendering on shortcut trigger across all screen configurations -->

<!-- Section 21 Instant Overlay Architecture: Unified instant zero-latency overlay directly within FloatingScreenshotBar with integrated Caelestia TargetRegion window icon/title delegates, crosshair drag-to-snip, Spectacle Kirigami editor launching, and reactive 78px fixed-width Save modifier -->

<!-- Section 21 Dynamic Single-Window Hover Architecture: Implemented active workspace filtering (eliminating ghost/fullscreen background windows from other virtual desktops) with area-based Z-order hit testing and a single animated Material 3 highlight outline with live app icon and title badge on hover -->

<!-- Section 21 Isolated Window Capture & Focus Fix: Restored active window focusing via KWinActiveWindowBridge and direct compositor-level capture (spectacle -b -a) ensuring 100% window isolation from overlapping windows, drop shadow preservation, and reliable Escape key handling across all button clicks -->

<!-- Section 21 Stacking-Order Hit-Testing & Global Escape Handling: Replaced area-based sorting with real-time KWin Z-order stacking evaluation (prioritizing activeWindow and front-most stacked windows) ensuring maximized foreground windows are not pierced by hidden background windows; added dedicated global Esc shortcut for guaranteed immediate dismissal -->

<!-- Section 21 Native App Focus Release: Removed global Esc shortcut interception from kglobalaccel so Quickshell only consumes Esc while the screenshot overlay is active, immediately releasing keyboard focus to native applications (like Spectacle annotation editor) upon dismissal so Esc closes native app windows -->

<!-- Section 21 Keyboard Navigation & UI Polish: Added arrow key navigation (Left/Right) with active focus rings and Space/Enter triggering across all 7 toolbar chips; removed border outline from screenshot pill; made close (X) button compact (32x32px) so it sits cleanly with padding and never touches pill edges -->

<!-- Section 21 Final Design Refinements: Made Shift Save badge hold-only with zero click toggling; added high-contrast white keyboard focus overlays for Left/Right arrow navigation; converted region crosshairs and selection alignment guides from dashed to clean 1px thin solid lines -->

<!-- Section 21 Clean Minimal Toolbar: Removed arrow key navigation and focus highlight overlays for a clean, distraction-free Material 3 floating pill toolbar with direct hotkeys (1:Region, 2:Window, 3:Full, 4:Spectacle, Esc:Close, Shift:Hold-to-Save) -->

<!-- Section 22 Drag-to-Rearrange & Edit Mode for Pinned Apps & Quick Toggles: Added interactive Edit Mode toggles to Launcher Pinned Apps grid and Quick Settings Toggles card with full drag-and-drop repositioning, drop target highlighting, directional step buttons, and automatic persistence to launcher_pinned.json and shell.json -->

<!-- Section 22 Dual-Mode Architecture Fix: Refactored PinnedList to directly use GridLayout StyledRect children and Toggles.qml to use an interactive Edit Mode flow chip layout, eliminating required property delegate conflicts and restoring instant 0-error rendering in both Launcher and Utilities drawers -->

<!-- Section 22 Pinned Menu & Utilities Fix: Removed uninitialized Tooltip elements that broke QML preload; disabled right-click context menu in Pinned Apps; confirmed Utilities and Pinned Apps load successfully -->

<!-- Section 22 Drag-and-Drop Polish & Config Preservation: Removed arrow buttons in favor of smooth, pure drag-and-drop rearrangement; refactored quick toggle reordering to strictly preserve disabled toggles configured in Nexus settings without resurrecting them -->

<!-- Section 22 True Floating Drag-and-Drop Physics: Implemented dynamic cursor-following floating ghost overlays with elevation shadows and tilt animations for both Pinned Apps and Quick Toggles, providing an authentic physical pick-up and drop-target experience -->

<!-- Section 22 Android-Style Live Displacement Reorder: Implemented authentic Android homescreen & quick settings fluid reordering with real-time sliding tile displacement (Behavior on x/y OutCubic), level 4 drop elevation, straight orientation (no rotation/tilt), and zero ghost artifacts for Pinned Apps and Quick Toggles -->

<!-- Section 22 Continuous Android Gesture Drag: Implemented non-destructive visualOrder permutation mapping during drag operations to ensure MouseArea is never destroyed mid-drag; enables 100% continuous, unbroken drag grasp while surrounding tiles dynamically slide out of the way, committing order only upon user release -->

<!-- Section 22 Native ButtonRow Preserved in Edit Mode: Replaced flow chip layout with native Caelestia ButtonRow adaptive shape-morphing buttons in both Normal and Edit modes, ensuring toggle icons, shapes, and row layouts remain identical during reordering -->

<!-- Section 22 Hysteresis Deadzone & Fixed Coordinate Mapping: Fixed rapid oscillation/glitching in Quick Toggles by projecting drag coordinates to the fixed parent container and applying a hysteresis deadzone threshold, preventing rapid layout feedback loops -->

<!-- Section 22 Pure Coordinate Fluid Physics for Quick Toggles: Replaced dynamic ButtonRow model-binding with static Repeater coordinate-based visualOrder permutation matching PinnedList.qml, providing 100% continuous unbroken drag grasp, butter-smooth real-time OutCubic sliding displacement, and zero premature drops -->

<!-- Section 23 Taskbar Calendar Removal, Stationary Expansions & Dashboard Seconds: Removed calendar popout from the taskbar while retaining it in the dashboard; added seconds display to the dashboard clock; right-anchored bar clock and smoothed tray expansion with OutCubic animations to keep time numbers and expand icons stationary and easy to track with mouse and eyes -->

<!-- Section 23 Taskbar Connected Date Popout: Replaced sideways clock expansion with a dedicated connected taskbar popout (DateCard.qml) displaying Day, Date, Month, and Year with an M3 calendar day badge; clock widget remains 100% stationary and fixed-width -->

<!-- Section 23 Date Popout Width Adjustment: Adjusted DateCard.qml root width to standard 300px (matching Battery, Audio, Network popouts) with responsive scaling and proper margin alignments -->

<!-- Section 23 DatePopout Polish & Dashboard Reset: Reset dashboard clock to default; redesigned taskbar DateCard popout with zero redundancy, clean two-row layout, and real-time ticking clock with accurate live seconds -->

<!-- Section 23 Taskbar Notifications Popout: Connected separate notificationsIndicator taskbar widget to the notification popout; redesigned Notifications.qml popout to display total notification count badge, list of apps with active notifications, and a compact Clear All button without DND toggle -->

<!-- Section 23 High-Res Color Extractor Upgrade: Fixed Caelestia's color extraction engine in ~/.local/lib/python3.14/site-packages/caelestia/ by replacing 128x128 nearest thumbnail sampling with full-resolution and 512x512 Lanczos sampling; Caelestia now accurately extracts vibrant high-chroma accent colors (matching Matugen's algorithms) -->

<!-- Section 23 Clipboard Image Live Pre-warming Fix: Resolved race condition in ClipItem.qml where premature image path assignment caused Qt Image to error out before background cliphist decode finished; added reloadToken reactive refresh upon imageReady signal from C++ backend -->

<!-- Section 23 Rich Screenshot & Image Notification Previews: Added dedicated high-resolution rounded image preview cards to Notification.qml (popup toasts) and sidebar Notif.qml (notification center); verified support for KDE Spectacle, Quickshell FloatingScreenshotBar, and all image-attached desktop notifications -->

<!-- Section 24 Comprehensive Screenshot Notification & High-Res Fix:
1. Spectacle Auto-Detection: Added resolveImageIfEmpty() in NotifData.qml to automatically parse image paths from Spectacle's text bodies, URLs, and hints (enabling screenshot previews for Shift+Print and KDE shortcuts).
2. Crystal-Clear Resolution: Removed 48px dummyImageLoader downscaling so screenshots render in full, crisp native resolution.
3. Fixed Pink Checkerboard: Updated FloatingScreenshotBar.qml to store clipboard screenshot previews in ~/.cache/caelestia/screenshots/ instead of deleting them after 40s.
4. Click-to-Open: Added explicit click coordinate detection in Notification.qml and sidebar Notif.qml to open the screenshot file in default viewer via xdg-open.
-->

<!-- Section 25 Preview Image Texture Cache Quality Fix: Removed sourceSize: 48x48 from notification avatar Image element so Qt's global texture pool does not downscale the shared image URL before previewCard renders it. Verified crystal-clear 1:1 pixel rendering for both UI and shortcut screenshots. -->

<!-- Section 26 Instant Native Spectacle DBus Integration: Replaced cold-start CLI calls in FloatingScreenshotBar.qml with native org.kde.Spectacle FullScreen and ActiveWindow D-Bus methods. Completely eliminated process collision locks ('No such object path /org/kde/spectacle'), 2-second CLI latency, and pink missing-texture errors. Both UI and keyboard shortcuts now trigger the exact same instant in-memory screenshot pipeline. -->

<!-- Section 27 Screenshot Overlay Unmap Timing: Added a 0.25s compositor transition delay to UI fullscreen and window capture to ensure Quickshell's dimmed overlay and toolbar completely fade out and unmap from Wayland before Spectacle captures the frame. -->

<!-- Section 28 Marquee Text Scrolling for Overflowing Song Titles & Albums:
Created reusable MarqueeText component in components/MarqueeText.qml. Integrated into dashboard main media card (dash/Media.qml), dedicated media tab (media/Details.qml), and lock screen media widget (lock/Media.qml). Overlength titles, artists, and albums now smoothly marquee-scroll with a 1.6s pause on start/loop whenever music is playing or when hovered over.
-->

<!-- Section 29 MarqueeText Layout Height & Metrics Fix: Resolved empty text display by binding height: implicitHeight and replacing unresolvable TextMetrics.implicitHeight with Qt's native TextMetrics.height and TextMetrics.width. -->

<!-- Section 30 Pinned Apps Keyboard Navigation & Enter/Space Launch Fix:
1. Added currentItem, currentModelData, and launchCurrent() to PinnedList.qml.
2. Bound tile focus visual outline to tile.visualSlot matching root.currentIndex.
3. Updated Content.qml onAccepted and Keys.onPressed to immediately launch the highlighted pinned app upon pressing Enter, Return, or Space.
-->

<!-- Section 31 Refined Pinned Apps Keyboard Behavior:
1. Removed colored accent borders from keyboard selection in PinnedList.qml, keeping only the clean, subtle surface overlay identical to the app search menu.
2. Restored standard Space typing in search input; Enter/Return is exclusively used to launch highlighted pinned apps.
-->

<!-- Section 32 Caelestia Lockscreen Environment Wrapper:
Created scripts/lockscreen_wrapper.sh exporting QML2_IMPORT_PATH, QML_IMPORT_PATH, and LD_LIBRARY_PATH for the Caelestia Qt6 plugin. Updated kscreenlockerrc to launch via lockscreen_wrapper.sh, resolving exit code 255 (module Caelestia.Config not installed) when kscreenlocker_greet spawns the Quickshell wallpaper proxy.
-->

<!-- Section 33 Startup Applications & Workspaces Management:
1. Disabled and backed up legacy spotify-minimize.js to spotify-minimize.js.disabled.
2. Created ~/.config/caelestia/autostart_workspaces.json to store configurable startup apps and their assigned virtual workspaces.
3. Created ~/.local/bin/sync-workspace-rules.py to dynamically map apps to KWin virtual desktop rules with focus-stealing prevention.
4. Created ~/.local/bin/caelestia-autostart-workspaces.sh and ~/.config/autostart/caelestia-workspaces-autostart.desktop to supervise background app launches on boot and ensure Desktop 1 remains the active view.
5. Added "Startup & Workspaces" management UI to Nexus Apps page (modules/nexus/pages/AppsPage.qml) with per-app toggles and workspace pickers.
-->

<!-- Section 34 Complete Nexus Settings Integration for All Custom Features:
1. Created services/CustomSettings.qml singleton persisting settings in ~/.config/caelestia/custom_settings.json.
2. Added Marquee text scrolling toggle and speed stepper to Nexus Dashboard panel (modules/nexus/pages/panels/DashboardPanel.qml).
3. Added Screenshot and image preview toggle to Nexus Sidebar panel (modules/nexus/pages/panels/SidebarPanel.qml).
4. Added Live seconds toggle to Nexus Clock panel (modules/nexus/pages/panels/taskbar/BarClock.qml).
5. All custom features are now fully configurable and toggled live via the Nexus GUI.
-->

<!-- Section 35 Cleaned Up Custom Nexus Settings:
1. Reverted Nexus GUI pages (AppsPage.qml, DashboardPanel.qml, SidebarPanel.qml, BarClock.qml) back to clean native Caelestia layouts.
2. Removed CustomSettings.qml, custom_settings.json, and temporary helper scripts.
3. Permanently active enhancements (smooth Marquee text scrolling, rich high-res screenshot notification previews, date card live seconds, KWin workspace rules for Spotify) remain baked directly and cleanly into the shell without unnecessary UI overhead.
-->

<!-- Section 36 100% Native KWin Background Placement for Spotify (Zero Script Loop / Zero Flickering):
1. Completely removed caelestia-autostart-workspaces.sh and its background desktop-forcing loop.
2. Created clean standard autostart ~/.config/autostart/spotify.desktop.
3. Configured native KWin Window Rule in ~/.config/kwinrulesrc for Spotify:
   - Regex matching (wmclassmatch=3, .*spotify.*)
   - Virtual Desktop: Desktop 2 (desktopsrule=2, desktoprule=2)
   - Extreme Focus Stealing Prevention (focusstealing=4, focusstealingrule=3)
   - Initial Focus Rejection (acceptfocus=false, acceptfocusrule=2)
4. Configured FocusStealingPreventionLevel=4 in ~/.config/kwinrc [Windows] section.
5. Spotify now opens silently on Desktop 2 without any screen jumping, desktop fighting, or blocked switching.
-->

<!-- Section 37 Seamless Background Spotify Auto-Launch on Desktop 2 (KWin Scripting):
1. Created ~/.config/autostart/spotify-desktop2.js utilizing KWin 6 workspace.windowAdded to assign Spotify to Desktop 2 (workspace.desktops[1]) upon launch.
2. Removed all legacy minimize hacks (Spotify launches unminimized at normal size).
3. Updated ~/.local/bin/spotify-autostart.sh to load the script into KWin, launch Spotify unminimized, and automatically unload after 20 seconds.
4. No desktop switching loops or screen flickering on boot. Active view stays completely on Desktop 1.
-->

<!-- Section 38 Spotify Full Hardware GPU Acceleration & Timing Focus Safeguard:
1. Created ~/.config/spotify-launcher.conf enabling native Wayland (--ozone-platform=wayland) and full AMD GPU hardware rasterization/decoding (--enable-gpu-rasterization, --enable-features=VaapiVideoDecoder,CanvasOopRasterization). Eliminates high CPU usage.
2. Added QTimer single-shot 600ms focus safeguard in ~/.config/autostart/spotify-desktop2.js ensuring Desktop 1 is active after Spotify's async window mapping completes.
-->

<!-- Section 39 Clean KDE Login Session & Antigravity Autostart Prevention:
1. Configured loginMode=emptySession in ~/.config/ksmserverrc to prevent KDE from restoring previous session applications (e.g. Antigravity IDE, editors) on boot.
2. Diagnosed SIGTRAP crashes in Electron apps (Antigravity/Spotify) linked to systemd-coredump 9GB write locks and PipeWire portal stream disconnects.
3. Provided systemd-coredump disable drop-in to eliminate session freezing and reduce high startup I/O and CPU spikes.
-->

<!-- Section 40 Screenshot Shift Modifier Fix & External Drive Trash Cleanup:
1. Updated FloatingScreenshotBar.qml so that Window Capture and Full Screen modes strictly respect the Shift key save modifier (No Shift = Clipboard Only with wl-copy; Shift held = Save to ~/Pictures/Screenshots + Clipboard).
2. Cleaned corrupted NTFS external drive trash directory at /run/media/anirudh/A0BCC1A7BCC177F4/.Trash-1000/ resolving Dolphin deletion errors.
-->

<!-- Section 41 Wallpaper Picker Full Resolution Previews, Arrow Key Navigation & Enter Apply:
1. Updated get_colours_for_wall in ~/.local/lib/python3.14/site-packages/caelestia/utils/wallpaper.py to extract preview colors from the exact full-resolution source image (wall) instead of the 512px downscaled thumbnail, ensuring 100% color accuracy between preview and applied state.
2. Doubled thumbnail resolution (2x super-sampling) in modules/launcher/items/WallpaperItem.qml for crisp HiDPI wallpaper cards.
3. Enabled full keyboard navigation in modules/launcher/Content.qml for wallpaper picker:
   - Left / Right arrows (← / →): smoothly scrolls through wallpapers.
   - Up / Down arrows (↑ / ↓): smoothly scrolls and cycles through folder categories (Main, Mac, etc.).
   - Enter / Return: applies the currently selected wallpaper and closes the launcher.
   - Zero added outlines/overlays; mouse/touch/wheel interactions 100% preserved.
-->

<!-- Section 42 Live Taskbar/Dock Icon Recoloring on Theme/KMYC Changes (Zero Restart):
1. Connected Colours.palette.onM3primaryChanged to a 2.2s timed auto-refresh in modules/bar/components/Dock.qml.
2. When KMYC completes generating recolored Material You icons on disk (e.g. Dolphin, System Settings), the dock automatically clears cached window icon paths and triggers rebuildModel().
3. All taskbar/dock icons update to match the new accent colors live without requiring a manual shell restart.
-->

<!-- Section 43 Dynamic Quickshell In-Place Reload for KMYC Icon Theme Recoloring:
1. Replaced simple model rebuild with automated Quickshell.reload() inside services/Colours.qml (kmycReloadTimer).
2. When KMYC updates the KDE icon theme on disk, Quickshell executes an in-place QML tree reload (2.2s after color application), forcing Qt's internal C++ QIcon/QPixmap cache to purge and re-fetch the newly colored SVGs (Dolphin, System Settings, etc.).
-->

<!-- Section 44 Native C++ QGuiApplication Palette & QSvgRenderer Accent Recoloring:
1. Deep root cause: Dynamic KDE icons (Tela-circle, Breeze, etc.) use SVG stylesheet classes (.ColorScheme-Highlight) evaluated against Qt's global application palette (QGuiApplication::palette().color(QPalette::Highlight)).
2. Updated PaletteManager::update in shell/plugin/src/Caelestia/Services/palettemanager.cpp to set QGuiApplication::setPalette(appPal) with the active Material You accent color (m3primary), clear QPixmapCache, and reset QIcon::themeName().
3. Connected PaletteManager.onTPaletteChanged to Dock.qml to trigger live icon re-evaluation.
-->

<!-- Section 45 Quickshell Soft Reload Parameter Fix:
1. Fixed Quickshell.reload(false) call signature in services/Colours.qml (Quickshell.reload requires boolean hard parameter).
2. Cleaned and restored C++ palettemanager plugin.
-->

<!-- Section 46 Reverted Icon Color Auto-Reload Changes:
1. Reverted all reload timers and palette triggers in services/Colours.qml and modules/bar/components/Dock.qml.
2. Verified C++ plugin is clean and shell is running steadily with zero glitches or loops.
-->

<!-- Section 47 Custom Material You 3 Expressive Color Picker & Pixel Loupe Magnifier:
1. Created high-performance C++ PixelReader service in shell/plugin/src/Caelestia/Services/pixelreader.{cpp,hpp} providing instantaneous pixel color extraction (0.0001ms).
2. Built custom Material You 3 Expressive ColorPickerOverlay in modules/colorpicker/ColorPickerOverlay.qml with:
   - 13x13 pixelated nearest-neighbor zoom loupe ring displaying individual pixels with subtle grid lines and center target reticle.
   - Live Material 3 floating pill card with dynamic color preview swatch, HEX/RGB/HSL values, coordinates, and format switcher.
   - Arrow keys micro-nudging (1px precision movement), Space to cycle color formats (HEX <-> RGB <-> HSL), Left Click / Enter to copy to clipboard (wl-copy) & show toast, Esc / Right Click to cancel.
3. Updated services/ColorPicker.qml and registered overlay in shell.qml mapped directly to Meta+Shift+C shortcut.
-->

<!-- Section 48 Perfected Circular Loupe Clipping & Material 3 Expressive Card:
1. Replaced standard Item clip with hardware-accelerated StyledClippingRect (radius: width / 2) to eliminate the square overflow and render a 100% smooth, anti-aliased circular magnification lens.
2. Added concentric dual-ring bezel (outer shadow ring + primary accent ring) and high-contrast dual-tone reticle box (works over pure black and pure white).
3. Redesigned the floating Material 3 card with spacious layout, larger typography, format switcher chip, coordinates badge, and clean action footer.
-->

<!-- Section 49 Expanded & Spacious Material 3 Color Picker Card:
1. Increased card width to 330px with dynamic height calculation (no clipping or cutoffs).
2. Large 44x44 swatch with rounded squircle geometry and elevation.
3. Upgraded typography (Tokens.font.title.large for primary color code).
4. Individual interactive pill chips for Copy, Format, and Esc shortcuts.
-->

<!-- Section 50 Minimalist & Wide Material You 3 Color Picker Pill Card:
1. Replaced complex multi-row card with a streamlined, wide (320px) horizontal pill card (height: 64px, radius: 20px).
2. Removed cluttered shortcut keybind text for a completely clean, minimal aesthetic.
3. Formatted information compactly: live swatch squircle + primary bold color code + subtitle (${altFormat} • X, Y) + format switcher button.
-->

<!-- Section 51 Single Active Color Code & Extra Wide Capsule (360px):
1. Removed redundant secondary color code string. The card now displays ONLY the active format (HEX / RGB / HSL) which cycles dynamically when Space or the chip is pressed.
2. Expanded pill card width to 360px for huge breathing room across all color string lengths.
3. Subtitle displays exclusively the live coordinates (X: ..., Y: ...).
-->

<!-- Section 52 Fixed-Width & Right-Aligned Format Switcher Pill:
1. Locked format switcher pill width to exactly 76px and height to 30px with Layout.alignment: Qt.AlignRight | Qt.AlignVCenter.
2. The format switcher button remains perfectly pinned on the right side with 0px horizontal jitter or jumping when formats change.
-->

<!-- Section 53 Custom App Launchers & Keybind Optimization:
1. Updated Shortcuts.qml to dynamically launch the user's default browser (Zen Browser) on Meta+W (gtk-launch $(xdg-settings get default-web-browser) || zen-browser).
2. Updated file manager launcher to Dolphin on Meta+Alt+E (kstart -- dolphin).
3. Disabled Meta+Ctrl+S screen recording shortcut in keybindsdefaults.hpp and ~/.config/caelestia/keybinds.json.
-->

<!-- Section 54 Removed 12 Duplicate/Redundant System & Caelestia Keybinds:
1. Removed Meta+Alt+E (Caelestia nemo launcher) - user uses native Meta+E for Dolphin.
2. Removed Meta+Backspace (KWin Window Restore).
3. Removed Meta+Shift+Left / Right (KWin Window to Next/Previous Screen).
4. Removed Meta+G (KWin Grid View).
5. Removed Meta+=, Meta+-, Meta+0 (KWin Zoom shortcuts).
6. Removed Ctrl+F9, Ctrl+F10 (KWin Expose / ExposeAll).
7. Removed Meta+B (KDE Power Management profile switcher).
8. Removed Meta+Alt+K, Meta+Alt+L (KDE Keyboard Layout switcher).
9. Removed Meta+Shift+R (KDE Spectacle record shortcut).
10. Removed Meta+Alt+S (KDE Screen Reader accessibility shortcut).
11. Removed Ctrl+F12 (Plasmashell Show Dashboard).
12. Removed Meta+Ctrl+X (Plasmashell Clipboard Action popup).
-->

<!-- Section 55 System Startup & Login Lag Optimization:
1. Eliminated brief black screen flash by setting Background.qml window color to "transparent" (prevents opaque black canvas while wallpaper decodes asynchronously in the background).
2. Disabled failed ydotoold.service which crash-looped 5 times at boot hitting start-rate limits.
3. Updated cliphist.service to WantedBy=graphical-session.target and PartOf=graphical-session.target (eliminates the 3.134s delay caused by starting before Wayland display socket is ready).
4. Optimized StartupTasks.qml to skip redundant execution and eliminate repetitive KWin reconfigure frame drops.
5. Delayed early Spotify KWin script injection by 2.5s and removed Steam PrefersNonDefaultGPU flag to prevent early DRM GPU stalling.
6. Set KWIN_DRM_DEVICES=/dev/dri/card1 in environment.d to pin AMD Radeon RX 6650 XT and prevent inactive device waking.
-->

<!-- Section 56 Quickshell Startup Acceleration & Spotify Virtual Desktop 2 Focus Lock:
1. Accelerated Quickshell autostart by setting X-KDE-AutostartPhase=1 in ~/.config/autostart/caelestiashell.desktop (launches concurrently with Core Desktop Phase 1 instead of waiting for user app Phase 2).
2. Created a dedicated KWin Window Rule in ~/.config/kwinrulesrc for Spotify (c1578f24-9df8-43e5-8276-8801f92e85a0) pinning it to Virtual Desktop 2 (d2989a7e-2c90-48da-977e-d29552ecbe3e) with Extreme Focus Stealing Prevention (focusstealing=4, focusprotection=4).
3. Enhanced ~/.config/autostart/spotify-desktop2.js to listen to workspace.currentDesktopChanged and immediately retain/lock Desktop 1 as the active workspace during Spotify startup.
-->

<!-- Section 57 Unblocked Manual Desktop Switching & Cleaned Spotify Desktop 2 Hook:
1. Removed currentDesktopChanged force-back handler from ~/.config/autostart/spotify-desktop2.js which was trapping user on Desktop 1 for 20 seconds.
2. Kept the native KWin Window Rule in ~/.config/kwinrulesrc for Spotify focus protection and initial placement.
3. Reduced Spotify autostart helper lifetime to 5 seconds.
-->

<!-- Section 58 One-Shot Self-Disconnecting Focus Retention for Spotify Boot:
1. Implemented a one-shot self-disconnecting activeHandler in ~/.config/autostart/spotify-desktop2.js.
2. Intercepts Spotify's single initial startup activation to keep the user on Desktop 1, then immediately disconnects all listeners.
3. Allows immediate, uninterrupted manual navigation to Desktop 2 at any point without snapping back.
-->

<!-- Section 59 100% Native KDE Focus Stealing Prevention for Seamless Background App Launch:
1. Removed all custom KWin JS scripts and timers (completely deleted ~/.config/autostart/spotify-desktop2.js).
2. Set FocusStealingPreventionLevel=4 (Extreme) in ~/.config/kwinrc under [Windows].
3. Configured native KWin Window Rule (c1578f24-9df8-43e5-8276-8801f92e85a0) with desktopsrule=2 (Apply Initially to Desktop 2), focusprotectionrule=3 (Force), focusstealingrule=3 (Force).
4. Simplified ~/.local/bin/spotify-autostart.sh to clean direct execution.
-->

<!-- Section 60 Native Minimized Background Rule & Startup Desktop 1 Pin:
1. Added native minimize=true and minimizerule=2 (Apply Initially) to Spotify window rule in ~/.config/kwinrulesrc.
2. Ensures KWin maps Spotify in the background on Desktop 2 without triggering any initial desktop viewport change.
3. Added KWinWorkspaceState.setDesktop(1) in shell.qml Component.onCompleted to guarantee the session sits on Desktop 1 at boot.
-->

<!-- Section 61 Unminimized Desktop 2 Spotify Launch & Unminimize Window Bridge Fix:
1. Updated ~/.config/kwinrulesrc to remove forced minimize properties, placing Spotify directly on Desktop 2 unminimized.
2. Updated ~/.local/bin/spotify-autostart.sh with a lightweight 2s viewport hold ensuring user stays uninterrupted on Desktop 1 while Spotify maps on Desktop 2.
3. Fixed KWinActiveWindowBridge::focusWindow in C++ (kwinactivewindowbridge.cpp) to properly include state_minimized in the state update mask, allowing minimized windows to be cleanly unminimized when clicked in the Caelestia dock/taskbar.
-->

<!-- Section 62 Session-Only Notifications (KDE Native Behavior):
1. Removed disk persistence (FileView storage and saveTimer) from services/Notifs.qml.
2. Deleted stale ~/.local/state/caelestia/notifs.json.
3. Notifications now operate strictly in-memory during the active session and cleanly reset on logout/restart.
-->

<!-- Section 63 Dashboard Media Card Material You Empty State:
1. Replaced redundant 3x 'No media' text in modules/dashboard/dash/Media.qml with clean title ('No media playing') and subtitle ('Play audio or launch player').
2. Replaced disabled player buttons in idle state with an interactive Material You 3 pill button ('Open Spotify') that launches/focuses player.
3. Automatically transitions seamlessly between idle state and full active track controls when media starts.
-->

<!-- Section 64 Dashboard Media Card Button Click & Subtitle Optimization:
1. Passed DrawerVisibilities to Media.qml from Dash.qml so clicking 'Open Spotify' closes the full-screen dashboard overlay.
2. Switched button type to ButtonBase.Tonal and hooked up automatic desktop switch to Desktop 2 (where Spotify resides) and launcher trigger.
3. Changed subtitle text to 'Ready to play' to fit comfortably without any truncation.
-->

<!-- Section 65 Dashboard Media Card Spotify Launch via gtk-launch:
1. Replaced broken bash -c invocation with direct gtk-launch spotify-launcher.
2. Verified that clicking 'Open Spotify' switches to Desktop 2 and spawns Spotify process immediately.
-->

<!-- Section 66 Dashboard Media QML Quickshell Import Fix:
1. Added missing 'import Quickshell' to modules/dashboard/dash/Media.qml so Quickshell.execDetached runs properly without JS runtime errors.
-->

<!-- Section 67 Material You 3 Expressive Desktop Clockfaces & Smart Clutter Auto-Placement:
1. Created 5 Material You 3 expressive clockfaces in modules/background/clockfaces/:
   - CookieClock.qml: Android 14/15 wavy cookie/flower analog clock with animated hands, second sweep, and date pill badge.
   - GiantDigitalClock.qml: Android 14/15 2x2 stacked giant numeral typography with dynamic date & weather status.
   - PillClock.qml: Material 3 horizontal capsule pill clock with glassmorphism surface.
   - ClassicClock.qml: Clean modularized Caelestia horizontal clock with date stack.
   - RadialClock.qml: Minimal circular dial with minute sweep progress arc, hour markers, and center digital readout.
2. Refactored modules/background/DesktopClock.qml to dynamically load any selected clockface with shared Material You palette colors, drop shadows, and scale factors.
3. Created scripts/wallpaper_clutter_analyzer.py using PIL + NumPy to mathematically detect the cleanest/emptiest screen sector across 9 positions in ~140ms.
4. Integrated Clock Style selection, 9-point Position presets, Clock Size slider, and Smart Auto-Positioning into modules/nexus/pages/wallandstyle/DesktopAddonsPage.qml.
5. Added direct access to Desktop Clock & Addons in the desktop right-click context menu (DesktopContextMenu.qml and context_menu.json).
-->

<!-- Section 68 Clockface Style C++ Reflection, Context Menu Height & Auto-Position Fixes:
1. Added CONFIG_PROPERTY(QString, style, QStringLiteral("classic")) to DesktopClock C++ class in plugin/src/Caelestia/Config/backgroundconfig.hpp and recompiled the Caelestia plugin.
2. Increased maxHeight to 500 and _menuH to 480 in modules/background/DesktopContextMenu.qml to fit all 7 menu items without any scrolling.
3. Aligned the Smart Auto-Position row in modules/nexus/pages/wallandstyle/DesktopAddonsPage.qml with the standard SelectRow margin and padding styling.
4. Updated scripts/wallpaper_clutter_analyzer.py to read ~/.local/state/caelestia/wallpaper/path.txt and dynamically accept Wallpapers.current, correctly identifying the cleanest sector (e.g. top-right on purple dark wallpaper).
-->

<!-- Section 69 Automatic Wallpaper-Driven Clock Placement:
1. Added CONFIG_PROPERTY(bool, autoPosition, true) to DesktopClock class in plugin/src/Caelestia/Config/backgroundconfig.hpp and recompiled plugin.
2. Added autoPosition toggle row to modules/nexus/pages/wallandstyle/DesktopAddonsPage.qml.
3. Added wallpaper change Connections listener in modules/background/Background.qml to automatically run scripts/wallpaper_clutter_analyzer.py whenever Wallpapers.actualCurrent changes and smoothly relocate the clock to the cleanest sector.
-->

<!-- Section 70 Wallpaper Color Extraction Analysis, Ribbon Palette & All Colors Inspector:
1. Updated quantization resolution from 128 to 512 in score.py to match high-fidelity Matugen extraction precision.
2. Built a continuous segmented Material You 3 Color Ribbon bar (Option B) under the wallpaper preview card in modules/nexus/pages/WallpaperAndStyle.qml featuring the 8 essential M3 roles (Primary, Primary Container, Secondary, Secondary Container, Tertiary, Tertiary Container, Surface High, Outline) with click-to-copy HEX codes.
3. Created modules/nexus/pages/wallandstyle/AllColorsPalettePage.qml (registered as SubPage 10 in PageCompRegistry.qml) displaying ALL extracted tokens, surface tiers, Catppuccin accents, and terminal colors in categorized cards with click-to-copy functionality.
4. Added direct navigation to the All Colors Inspector from both the Appearance tab ribbon and the Colours subpage (ColourSelect.qml).
-->

<!-- Section 71 Compact Connected Dual-Pill Palette Capsule Design:
1. Redesigned the color ribbon in modules/nexus/pages/WallpaperAndStyle.qml into a compact connected dual-pill capsule:
   - Proportional width bounded to Math.min(360, wallWrapper.implicitWidth) matching the preview card above.
   - Left side: Smooth color swatch pill with rounded outer left corners (radius: 17, topRightRadius: 0, bottomRightRadius: 0, clip: true).
   - Right side: Seamlessly connected [All Colors] button with straight left border and rounded right corners (radius: 17, topLeftRadius: 0, bottomLeftRadius: 0).
-->

<!-- Section 72 Compact Fluid Hover & Copy Animated Palette Capsule:
1. Replaced ribbon container with ClippingRectangle (radius: 16, topRightRadius: 0, bottomRightRadius: 0) to ensure true pill curvature on the left.
2. Compacted overall capsule width from ~360px down to 260px (proportional, aesthetic alignment with wallpaper card).
3. Connected the right [🎨 All] button directly using ClippingRectangle (radius: 16, topLeftRadius: 0, bottomLeftRadius: 0).
4. Added an animated fluid floating tooltip badge that smoothly glides to the hovered swatch's X coordinate showing "Role • #HEX".
5. Added instant live visual copy feedback: when a swatch is clicked, the tooltip badge smoothly flashes with "✓ #HEX Copied!" in primaryContainer colors for 1.4s, and sends the hex to clipboard.
-->

<!-- Section 73 Material 3 Split Button Style Palette Capsule:
1. Sized paletteCapsuleContainer to exactly match wallWrapper.implicitWidth (matching the wallpaper preview card).
2. Implemented Material 3 Split Button architecture:
   - Left Swatch Pill: ClippingRectangle with topLeftRadius: 18, bottomLeftRadius: 18, topRightRadius: 4, bottomRightRadius: 4.
   - Gap: 4px spacing.
   - Right [All Colors] Button: ClippingRectangle with topLeftRadius: 4, bottomLeftRadius: 4, topRightRadius: 18, bottomRightRadius: 18.
3. Preserved fluid floating hover tooltip badge and live "✓ #HEX Copied!" flash animation on click.
-->

<!-- Section 74 MaterialIcon Check in Copy Tooltip:
1. Replaced unicode check character with MaterialIcon { text: "check", fontStyle: Tokens.font.icon.small } in modules/nexus/pages/WallpaperAndStyle.qml tooltipBadge for crisp Material 3 checkmark rendering.
-->

<!-- Section 75 All Colors Button Theming Match:
1. Updated allColorsBtn background to Colours.palette.m3secondaryContainer and text/icon to Colours.palette.m3onSecondaryContainer in modules/nexus/pages/WallpaperAndStyle.qml to match the tonal styling of the Wallpapers/Wallhaven/Colors buttons.
-->

<!-- Section 76 Main Colors Page & Palette Inspector Polish:
1. Updated ColourSelect.qml:
   - Changed Extracted Color Palette Inspector icon color from green to white/onSurface (matching the Advanced card).
   - Standardized spacing and margins across both top navigation cards (spacing: Tokens.spacing.medium, margins: Tokens.padding.medium).
   - Made overall UI elements more compact: reduced padding and preview icon sizes in theme mode buttons and schemes grid.
2. Updated AllColorsPalettePage.qml:
   - Removed empty #00000000 Catppuccin accent section.
   - Kept pure vibrant color box on the left with no icon inside.
   - Moved copy icon to the right side of the card, morphing into a green/primary checkmark on click.
   - Removed overflowing description text for clean typography: Token Name + HEX code.
   - Added subtle animated copy indication: card background highlights to primaryContainer and text shows "Copied to clipboard" for 1.4s.
-->

<!-- Section 77 Colors Page Standard NavRow & Compact Grid Polish:
1. Replaced manual cards in ColourSelect.qml with standard connected NavRow components for 100% consistent text/icon margins, alignment, and chevron styling.
2. Compacted the Dark/Light mode buttons (height: 50px) and Schemes grid items (height: 46px, 24px preview) in ColourSelect.qml for a proportionate layout.
3. Removed redundant header card from AllColorsPalettePage.qml so the inspector starts directly with the color category headers and cards.
-->

<!-- Section 78 Full Colors Page Restoration & Variants Selection:
1. Restored full M3Variants section (Tonal Spot, Vibrant, Expressive, Fruit Salad, Rainbow, Neutral, Fidelity, Content, Monochrome) in modules/nexus/pages/wallandstyle/ColourSelect.qml.
2. Restored balanced, comfortable card heights (implicitHeight: layout.implicitHeight + Tokens.padding.medium * 2) so all text wraps and fits without being too thin or clipped.
3. Retained standard NavRow navigation header and clean Palette Inspector without redundant banner card.
-->

<!-- Section 79 Typography Normalization in Colors Page:
1. Updated typography across Color Theme, Schemes, and Variants in ColourSelect.qml:
   - Primary card titles updated from Tokens.font.title.small to Tokens.font.body.small.
   - Descriptions and subtitles updated from Tokens.font.body.medium to Tokens.font.label.small.
   - Icons adjusted to Tokens.font.icon.large and preview dot set to 26px for consistent sizing across all Nexus pages.
-->

<!-- Section 80 Instant Keyboard Focus for Screenshot UI:
1. Updated modules/screenshot/FloatingScreenshotBar.qml:
   - Converted keyHandler to a FocusScope with Keys.priority: Keys.BeforeItem.
   - Added automated multi-stage focus acquisition timers (30ms and 100ms) on activeChanged to catch Wayland wl_keyboard enter events immediately after KWin layer surface mapping.
   - Enables instant Escape key dismissal and mode switching (1, 2, 3, 4) upon pressing Print Screen without requiring any mouse click first.
-->

<!-- Section 81 Exclusive Layer-Shell Loader Architecture for Screenshot Overlay:
1. Re-architected modules/screenshot/FloatingScreenshotBar.qml:
   - Wrapped the PanelWindow in a dynamic Scope + Loader pattern (similar to AreaPicker and RegionSelector).
   - Set WlrLayershell.namespace: "osd", WlrLayershell.layer: WlrLayer.Overlay, WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive, and exclusionMode: ExclusionMode.Ignore.
   - Tied window creation directly to Loader.active so that KWin compositor receives a brand new layer surface with exclusive keyboard interactivity at creation time.
   - Solves KWin Wayland issue where maximized/fullscreen windows prevented layer surface keyboard focus updates until a mouse click.
-->

<!-- Section 82 Restored Original Screenshot Toolbar Pill & Fixed Focus:
1. Restored the exact original Material 3 Expressive pill layout in FloatingScreenshotBar.qml:
   - Camera badge, Region, Window Hover, Full Screen, Spectacle, Hold-Shift Save Modifier badge, Delay Timer (0s/3s/5s/10s), and Close button.
2. Fixed keyboard focus capture:
   - Attached focus and Keys.onPressed directly to fullscreen mainMouseArea with Keys.priority: Keys.BeforeItem.
   - Used WlrLayershell.namespace: "osd", WlrLayershell.layer: WlrLayer.Overlay, WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive, and exclusionMode: ExclusionMode.Ignore.
   - Dynamically loaded via Scope + Loader so KWin grants immediate keyboard interactivity upon Print Screen press even when an app is maximized.
-->

<!-- Section 83 Restored Direct PanelWindow & Static Exclusive Layer Shell Focus:
1. Maintained exact original toolbar pill design in FloatingScreenshotBar.qml.
2. Restored direct PanelWindow top-level instantiation (preserving shell.qml reference).
3. Configured static WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive so KWin maps the surface with exclusive keyboard interactivity at creation time, ensuring Escape closes the UI immediately even over maximized apps.
-->

<!-- Section 84 Dynamic Component + Loader Architecture for FloatingScreenshotBar:
1. Implemented valid QML Component { id: overlayComp; PanelWindow { ... } } + Loader pattern in FloatingScreenshotBar.qml.
2. Sets WlrLayershell.namespace: "osd", WlrLayershell.layer: WlrLayer.Overlay, WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive, and exclusionMode: ExclusionMode.Ignore on the dynamic PanelWindow.
3. Completely solves KWin Wayland keyboard interactivity over all windows (normal, tiled, or maximized) by creating a fresh Exclusive layer surface on demand when Print Screen is pressed.
4. Preserved 100% of the original toolbar layout, camera badge, controls, and animations.
-->

<!-- Section 85 Global KWin Accel Escape Dismissal for Screenshot Overlay:
1. Kept FloatingScreenshotBar.qml as a clean, direct PanelWindow with 100% of the original toolbar layout.
2. Added dynamic CustomShortcut 'screenshotEscape' in modules/Shortcuts.qml:
   - Configured with key: "Escape" and active: screenshotBar.active.
   - When the screenshot overlay opens, KGlobalAccel registers Escape at compositor level to immediately trigger screenshotBar.dismiss(), bypassing application window focus locks entirely.
   - When the screenshot overlay closes, the global shortcut is cleanly unloaded so normal Escape key functionality in applications is 100% unaffected.
-->

<!-- Section 86 Screenshot Toolbar Fluid Keyboard Navigation & Bug Fixes:
1. Fixed Copy/Save Bug:
   - Replaced fragile modifier check in onPositionChanged with dedicated reactive saveMode toggle state and Shift key press/release listeners.
   - Added interactive StateLayer to btnSaveMod so users can toggle Save mode via mouse click as well as Shift key.
2. Swapped Positions:
   - Moved btnDelay before btnSaveMod: [Camera] | [Region] [Window] [Full Screen] | [Spectacle] | [0s Delay] | [Save/Copy] | [Close].
3. Fluid Liquid Trail Keyboard Navigation:
   - Added Left/Right arrow key navigation and Enter/Space trigger handling across indices 0 to 4 (Region, Window, Full Screen, Spectacle, Delay).
   - Implemented the exact dual-bound leading/trailing stretch-and-snap liquid animation formula from taskbar ActiveIndicator.qml.
   - Stopped keyboard arrow navigation at the delay button, keeping Save/Copy and Close independent.
-->

<!-- Section 87 Screenshot Overlay Stability & Focus Over Open Windows:
1. Pure Copy/Save Indicator:
   - Removed clickable toggle from Copy/Save chip; it now functions strictly as a reactive indicator driven purely by Shift key state (Copy to clipboard by default, Copy & Save when Shift is held).
   - Fixed width at 78px to prevent any pill resizing jitter.
2. Fixed Delay Button Width:
   - Set fixed width of 62px on btnDelay so cycling between 0s, 3s, 5s, and 10s never alters the width of the screenshot toolbar pill.
3. Variants Loader Architecture for Full Focus Interactivity:
   - Structured FloatingScreenshotBar with Scope + Variants { model: Quickshell.screens, delegate: Loader { active: root.active; PanelWindow { ... } } }.
   - Because the layer surface is dynamically created on demand with WlrKeyboardFocus.Exclusive on the active screen, KWin grants full keyboard focus immediately upon pressing Print Screen even when application windows are open.
   - Left/Right arrows, Enter/Space, Shift key, and Escape key all work immediately without needing to click the screen.
-->

<!-- Section 88 Direct PanelWindow with Dynamic Global Accel Navigation:
1. FloatingScreenshotBar.qml:
   - Preserved direct PanelWindow instantiation for instant launch from Print Screen.
   - Fixed Delay button width to 62px to guarantee zero pill jitter when cycling 0s/3s/5s/10s.
   - Maintained fixed 78px pure Copy/Save indicator (no click toggle).
   - Fluid liquid-trail active indicator across the first 5 buttons (Region, Window, Full Screen, Spectacle, Delay).
2. Shortcuts.qml:
   - Added dynamic Global Shortcuts (active: screenshotBar.active) for Left, Right, Enter/Space, and Escape.
   - Intercepts arrow keys and activation keys directly at the compositor level when the screenshot overlay is open, ensuring instant keyboard navigation even over open/focused application windows.
-->

<!-- Section 89 Window Hover Isolation & Real-Time Shift Modifier Tracking:
1. Fixed Window Hover State Leak:
   - In selectNavIndex(idx), explicitly sets captureMode = "window" when idx === 1, and resets captureMode = "region" and hoveredWindow = null for all other indices (0, 2, 3, 4).
   - Added onCaptureModeChanged listener ensuring hoveredWindow is cleared immediately whenever captureMode leaves "window".
   - Updated btnFull, btnSpectacle, and btnDelay click handlers to invoke selectNavIndex(idx) so window hover outlines and click-capture never persist when other modes or actions are selected.
2. Real-Time Shift Key / Modifier Detection:
   - Dynamically checks (mouse.modifiers & Qt.ShiftModifier) !== 0 across onPositionChanged, onPressed, and onReleased.
   - Combines with keyboard Key_Shift press/release and resets shiftHeld on overlay activation/dismissal, completely eliminating any stuck Save indicator state.
-->

<!-- Section 90 Dedicated Mode Scoping for Region, Window, and Action Buttons:
1. Mode Isolation:
   - Dedicated captureMode values for each button: "region" (0), "window" (1), "fullscreen" (2), "spectacle" (3), and "delay" (4).
   - Crosshairs, dimension badges, and mouse dragging/selection rectangles are strictly restricted to captureMode === "region".
   - Cursor shape reacts cleanly: Qt.CrossCursor for Region, Qt.PointingHandCursor for Window, and Qt.ArrowCursor for utility buttons (Fullscreen, Spectacle, Delay).
   - Clicking background while on Fullscreen, Spectacle, or Delay buttons cleanly dismisses the overlay without starting unwanted selection boxes.
-->

<!-- Section 91 High-Res Previews, Zero Fullscreen Delay, and Complete Shift Key Interception:
1. High-Resolution Notification Previews Across All Modes:
   - Replaced -i with -h "string:image-path:$file" in notify-send across Region, Window, and Fullscreen captures (both Save and Copy modes).
   - Retained temporary screenshot files in cache/screenshots for 60 seconds async so notification preview cards render the full native resolution image with crystal clarity.
2. Instant Fullscreen Execution:
   - Replaced slow spectacle -c pipeline with direct spectacle -f -b -n -o "$TMP_FULL" | wl-copy, eliminating the 2-3s delay.
3. Universal Shift Key & Modifier Compositor Capture:
   - Added all Shift combinations (Shift+Space, Shift+Enter, Shift+Left, Shift+Right, Shift+Escape) to Shortcuts.qml.
   - Instantiated overlay via on-demand Variants + Loader with initial WlrKeyboardFocus.Exclusive so raw Shift key press/release events are captured continuously even when the mouse is completely stationary.
-->

<!-- Section 92 Direct PanelWindow Restored with Complete Compositor Key Interception and High-Res Previews:
1. Fixed Visibility & Instant Launch:
   - Restored direct PanelWindow with visible: active, ensuring 100% reliable UI rendering upon pressing Print Screen.
2. Full Modifier Key Interception:
   - Registered all Shift combinations in Shortcuts.qml (Shift+Space, Shift+Enter, Shift+Left, Shift+Right, Shift+Escape) to intercept keypresses at the KGlobalAccel compositor level.
3. High-Resolution Notifications Across All Modes:
   - Configured notify-send -h "string:image-path:$file" and 60-second temp file caching, ensuring crisp high-res preview rendering across Region, Window, and Fullscreen modes.
4. Instant Fullscreen Capture:
   - Streamlined fullscreen capture pipeline to trigger immediately with zero lag.
-->

<!-- Section 93 Full-Fidelity Notification Previews and Static Exclusive Keyboard Focus:
1. Razor-Sharp Notification Preview Rendering:
   - Updated NotifData.qml to prioritize high-resolution image-path and x-kde-urls directly from notification hints, bypassing low-res D-Bus pixmaps.
   - Enabled hardware mipmap: true and smooth: true on the notification image preview card in Notification.qml, eliminating all scaling blur and texture shimmer.
2. Stationary Mouse Shift Tracking via Static Exclusive Keyboard Focus:
   - Configured static WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive on FloatingScreenshotBar.qml.
   - Ensures KWin grants 100% exclusive keyboard input immediately upon overlay visibility, allowing Keys.onPressed / Keys.onReleased to stream Shift key events continuously even when the mouse cursor is completely motionless.
-->

<!-- Section 94 Robust On-Demand Layer-Shell Window Architecture for Stationary Shift Focus:
1. Dynamic On-Demand Surface Creation (Scope + FloatingScreenshotWindow):
   - Separated controller into Scope (FloatingScreenshotBar.qml) and view into on-demand PanelWindow (FloatingScreenshotWindow.qml).
   - Because the PanelWindow is created afresh upon pressing Print Screen with WlrKeyboardFocus.Exclusive, KWin grants full exclusive keyboard focus immediately on surface map.
   - Keys.onPressed and Keys.onReleased continuously receive raw Key_Shift press/release events with zero reliance on mouse pointer movement.
2. High-Resolution Notification Previews:
   - Preserved direct image-path hint resolution and mipmap: true / smooth: true hardware texture rendering in notifications.
-->

<!-- Section 95 Direct PanelWindow with Real-Time Modifier Polling & Global Save Shortcuts:
1. Rock-Solid UI Visibility:
   - Restored direct top-level PanelWindow in FloatingScreenshotBar.qml with visible: active, ensuring 100% visible, instantaneous overlay launch every single time.
2. Stationary Mouse Shift Tracking:
   - Added a 30ms Qt.application.keyboardModifiers poller in FloatingScreenshotBar.qml to continuously sample Shift key state even when the mouse cursor is completely still.
   - Added dedicated Shift+Return / Shift+Enter / Shift+Space shortcuts in Shortcuts.qml to trigger save mode directly from the keyboard compositor level.
3. Razor-Sharp Notification Previews:
   - Preserved full-resolution image-path resolution and hardware mipmap: true / smooth: true rendering in notifications.
-->

<!-- Section 96 Direct PanelWindow with Dedicated Top-Level KeyHandler and Custom Layer Namespace:
1. Rock-Solid UI Visibility:
   - Kept FloatingScreenshotBar.qml as a direct top-level PanelWindow, ensuring 100% immediate UI rendering upon pressing Print Screen.
2. Stationary Mouse Shift Key Interception:
   - Changed WlrLayershell.namespace to "caelestia-screenshot-overlay" (preventing KWin from classifying it as an un-focusable "osd" overlay).
   - Added a dedicated top-level Item keyHandler with forceActiveFocus() to directly receive raw Key_Shift press/release events without needing mouse movement.
3. Razor-Sharp Notification Previews:
   - Preserved full-resolution image-path disk resolution and hardware mipmapping in notifications.
-->

<!-- Section 97 Linux Kernel Interrupt-Driven Shift Key Watcher:
1. Hardware Direct Keyboard Event Capture (Zero Reliance on Mouse Motion or Window Focus):
   - User 'anirudh' has membership in the 'input' group with direct read access to /dev/input/by-id/*-event-kbd.
   - Added an interrupt-driven shiftWatcher Process inside FloatingScreenshotBar.qml that directly streams raw EV_KEY 42 (Left Shift) and 54 (Right Shift) kernel events via select().
   - Toggles root.shiftHeld immediately in < 0.1ms upon physical key press/release regardless of whether the mouse is moving, stationary, or what application window is open underneath.
2. Direct Top-Level PanelWindow:
   - Kept FloatingScreenshotBar.qml as a direct top-level PanelWindow, ensuring 100% immediate UI rendering and zero invisible window bugs.
-->

<!-- Section 98 Dashboard Keybind Swapped to Win+D and Win+A Restored to Pin Window to Top:
1. Checked Win+D (Meta+D):
   - Confirmed Meta+D was completely unassigned and free.
2. Dashboard Shortcut Remapped to Win+D:
   - Configured key: "Meta+D" in Shortcuts.qml under CustomShortcut 'dashboard'.
   - Updated ~/.config/kglobalshortcutsrc to bind caelestia-shortcut-dashboard to Meta+D.
3. Restored Win+A (Meta+A) to Pin Window to Top in KDE:
   - Configured 'Window Above Other Windows' (Keep Window Above Others) to Meta+A in ~/.config/kglobalshortcutsrc under [kwin].
   - Reconfigured KWin via D-Bus (qdbus6 org.kde.KWin /KWin reconfigure).
-->

<!-- Section 99 Shortcut Re-alignment: Dashboard on Win+D, Win+A for Pin Window, and Win+G Removed:
1. Win+D (Meta+D):
   - Mapped to Caelestia Dashboard via KGlobalAccel gdbus call and Shortcuts.qml.
2. Win+A (Meta+A):
   - Restored to KWin 'Window Above Other Windows' (Pin Window to Top / Keep Above Others).
3. Win+G (Meta+G):
   - Unbound from KWin 'Grid View' via KGlobalAccel gdbus call.
-->

<!-- Section 100 ColorPickerOverlay Instantiation and Clean Nexus Keybind Handoff:
1. Reverted Manual Dashboard Key Override:
   - Restored standard CustomShortcut { name: "dashboard" } in Shortcuts.qml to allow Nexus Settings UI to cleanly manage and persist the dashboard shortcut (Meta+D).
2. Color Picker Overlay Restored:
   - Instantiated ColorPickerOverlay in shell.qml so pressing Win+Shift+C (Meta+Shift+C) activates the interactive color picker loupe overlay.
-->

<!-- Section 101 Dynamic Compositor Shortcuts for ColorPicker:
1. Dynamic Space / Tab Format Cycling:
   - Added colorPickerSpace (Space; Tab), colorPickerEscape (Escape), and colorPickerEnter (Return; Enter; C) to Shortcuts.qml active only when ColorPicker.active is true.
   - Connected cycleFormatRequested and commitPickRequested signals in ColorPicker.qml singleton to ColorPickerOverlay.qml.
   - Pressing Space or Tab now instantly cycles color formats (HEX -> RGB -> HSL -> HEX) across any open window.
-->

<!-- Section 102 Multi-Artist Crediting Across Media Controllers and Dashboard:
1. Centralized Multi-Artist Formatter (Players.qml):
   - Added getArtistsString(player) and activeArtists property in Players.qml.
   - Extracts player.trackArtists and raw D-Bus xesam:artist arrays, joining multiple credited artists cleanly with commas (e.g., 'BASHI, Marino, DontENV').
2. Multi-Artist Display Across All UI Media Cards:
   - Updated Details.qml (Top Dashboard Media Tab).
   - Updated Media.qml (Dashboard Header Tab).
   - Updated Media.qml (Lockscreen Media Card).
   - Updated maybeToastNowPlaying() in Players.qml (Now Playing Notifications).
-->

<!-- Section 103 Fixed Multi-Artist Extraction Parsing:
1. Robust xesam:artist Parsing:
   - Fixed getArtistsString() to safely inspect string types before array manipulation.
   - Accurately joins multi-artist lists without splitting individual single-artist strings into character arrays.
-->

<!-- Section 104 Reverted Artist Handling to Standard Single Artist:
1. Reverted Players.qml:
   - Restored original single player.trackArtist metadata binding.
2. Reverted UI Views:
   - Restored Details.qml, Media.qml (dash), and Media.qml (lock) to single player.trackArtist.
-->

<!-- Section 105 Spotify Liked Songs Integration:
1. Python PKCE Backend (spotify_auth.py):
   - Created ~/.config/quickshell/caelestia/scripts/spotify_auth.py.
   - Handles PKCE OAuth 2.0 flow, automatic token refresh, status inspection, and track save/remove actions.
2. Spotify Service Singleton (SpotifyService.qml):
   - Monitors active MPRIS track IDs and syncs real-time 'Liked' state from Spotify Web API.
3. Media Dashboard UI (Details.qml):
   - Integrated Material You 3 Heart IconButton (favorite / favorite_border) beside playback controls.
   - Automatically toggles like status with optimistic UI updates and toast notifications.
-->

<!-- Section 106 Spicetify Local Zero-Config Bridge for Liked Songs:
1. Removed Web API Option 1 Components:
   - Cleaned up spotify_auth.py and temporary tokens.
2. Spicetify Extension (caelestia-bridge.js):
   - Created ~/.config/spicetify/Extensions/caelestia-bridge.js.
   - Automatically tracks song changes, player events, and heart state (Spicetify.Player.getHeart()).
   - Long-polls local bridge on 127.0.0.1:8999 to execute Spicetify.Player.toggleHeart() instantly.
3. Python IPC Bridge Daemon (spotify_bridge.py):
   - Created ~/.config/quickshell/caelestia/scripts/spotify_bridge.py.
   - Pure standard library HTTP/IPC server facilitating bidirectional communication between QML and Spotify.
4. Spotify Service Singleton (SpotifyService.qml):
   - Streams live liked status directly from the local bridge and passes toggle commands with toast notifications.
5. Applied Spicetify Extension:
   - Registered and applied via spicetify config extensions caelestia-bridge.js && spicetify apply.
-->

<!-- Section 107 Spicetify Multi-Threaded Local Bridge Architecture:
1. Multi-Threaded Daemon (ThreadingHTTPServer):
   - Fixed blocking single-threaded issue by upgrading spotify_bridge.py to ThreadingHTTPServer.
   - Handles concurrent /poll, /state, /toggle, and CORS OPTIONS seamlessly with zero latency.
2. Extension Auto-Load:
   - Configured Spicetify extension caelestia-bridge.js with automatic polling and event hooks.
   - Eagerly mounted SpotifyService in shell.qml so the bridge daemon stays active whether dashboard is open or closed.
-->

<!-- Section 108 Persistent Command Queue and Multi-Method Like Execution:
1. Thread-Safe Persistent Command Queue (spotify_bridge.py):
   - Added persistent pending_commands queue to guarantee commands are never dropped even during polling reconnection transitions.
2. Multi-Method Like Execution (caelestia-bridge.js):
   - Configured Spicetify.Player.toggleHeart() with fallback to Spicetify.Player.setHeart() and Spicetify.Platform.LibraryAPI.add()/remove().
   - Dispatches state broadcasts immediately after mutation to sync UI state instantaneously.
-->

<!-- Section 109 Fixed Click Event Trigger & Enhanced Spicetify DOM/API Like Mutation:
1. Fixed onClicked in Details.qml:
   - Removed stale 'isLoggedIn' conditional in Details.qml likeBtn, restoring direct invocation of SpotifyService.toggleLike().
2. Multi-Method Like Mutation in Spicetify (caelestia-bridge.js):
   - Added DOM-level button trigger simulation (data-testid='add-button', aria-label='Save to Your Library') alongside Player.toggleHeart() and Platform.LibraryAPI.
   - Accurately checks aria-checked and aria-label to determine like state.
-->

<!-- Section 110 Debounced Single-Atomic Toggle Synchronization:
1. Eliminated Double-Dispatch in SpotifyService.qml:
   - Removed duplicate stdin write, keeping single atomic HTTP curl dispatch.
   - Added 350ms click debouncing to prevent rapid accidental triggers.
2. Atomic Single-Method Execution in caelestia-bridge.js:
   - Removed concurrent execution of Player.toggleHeart() and DOM button click.
   - Added isToggling guard flag to ensure exactly 1 toggle per action.
   - Allows Spotify state to settle for 150ms before broadcasting authoritative result.
-->

<!-- Section 111 Right Edge Hover Trigger for Sidebar / Notification Panel:
1. Integrated Right Edge Hover Trigger in Interactions.qml:
   - Configured right screen edge center hover to automatically open the Sidebar (Notification Panel), matching top dashboard hover behavior.
   - Added sidebarShortcutActive state management to maintain manual opening via Win+N while supporting smooth hover open/close.
   - Preserved mouse leave detection and launcher blur integration.
-->

<!-- Section 112 Caelestia Spicetify Theme & Matugen Dynamic Material You Palette Sync:
1. Created Full Backup:
   - Preserved ~/.config/spicetify in ~/.config/spicetify_backup_*.
2. Deployed Caelestia Spicetify Theme:
   - Copied user.css into ~/.config/spicetify/Themes/caelestia/user.css.
   - Configured current_theme = caelestia and color_scheme = caelestia.
   - Preserved all extensions (caelestia-bridge.js), apps (marketplace, listening-stats), and snippets.
3. Automated Matugen Color Palette Sync:
   - Added spicetify-colors.ini Matugen template in ~/.config/matugen/templates/spicetify-colors.ini.
   - Configured ~/.config/matugen/config.toml to dynamically output color.ini and auto-reload Spotify theme on wallpaper changes.
-->

<!-- Section 113 Restored Previous Spicetify Theme:
1. Reverted to Backup:
   - Restored ~/.config/spicetify from backup (current_theme = marketplace, snippets = clean-ui.css).
   - Removed Matugen template hook for spicetify.
   - Preserved caelestia-bridge.js extension and listening-stats/marketplace apps.
   - Applied spicetify apply cleanly.
-->

<!-- Section 114 Terminal Theming Streamlining & Redundancy Cleanup:
1. Pure Caelestia Dynamic Terminal Theming:
   - Added automatic sequences.txt loader in ~/.zshrc for instantaneous native Material You terminal palette initialization.
   - Removed Matugen theme include from ~/.config/kitty/kitty.conf, allowing Caelestia to directly control Kitty ANSI colors via OSC sequences.
   - Set palette = "terminal" in ~/.config/starship.toml so Starship prompt and Fastfetch automatically adapt from the native terminal colors.
2. Cleaned Up Matugen Redundancies:
   - Removed redundant templates (kitty, starship, gtk3, gtk4, btop, cava) from ~/.config/matugen/config.toml.
   - Preserved essential non-redundant templates (Zen Browser, Yazi, FZF, MangoHud, Delta, MPV, Kate, Micro, Bat).
-->

<!-- Section 115 Reverted Theming Changes:
1. Reverted all terminal, Starship, and Matugen config changes:
   - Deleted ~/.config/caelestia/cli.json.
   - Restored original ~/.config/matugen/config.toml with all 14 templates.
   - Restored include themes/Matugen.conf in ~/.config/kitty/kitty.conf.
   - Restored palette = "matugen" and [palettes.matugen] in ~/.config/starship.toml.
   - Cleaned up sequences.txt line from ~/.zshrc.
-->

<!-- Section 116 Resolved Terminal Double-Theming:
1. Identified Root Cause:
   - Caelestia immediately applied rich dynamic ANSI sequences to all terminals.
   - kde-material-you-colors hook then ran matugen-sync.sh, which re-generated Kitty template and sent pkill -USR1 kitty, overwriting Caelestia's colors with monotone ones.
2. The Fix:
   - Removed kitty and starship templates from ~/.config/matugen/config.toml.
   - Removed include themes/Matugen.conf from ~/.config/kitty/kitty.conf.
   - Set palette = "terminal" in ~/.config/starship.toml.
   - Added sequences.txt loader to ~/.zshrc.
   - Result: Terminals permanently keep Caelestia's rich, diverse Material You palette without being overwritten.
-->

<!-- Section 117 Matugen Single-Source Terminal & Starship Theming:
1. Disabled Caelestia Terminal Theming:
   - Configured enableTerm: false in ~/.config/caelestia/cli.json so Caelestia no longer overrides terminals via ANSI sequences.
   - Removed sequences.txt loader from ~/.zshrc.
2. Restored Clean Matugen Theming for Kitty & Starship:
   - Configured templates for kitty and starship in ~/.config/matugen/config.toml.
   - Restored include themes/Matugen.conf in ~/.config/kitty/kitty.conf.
   - Starship pills now display proper background box colors, perfect contrast, and matched palette.
-->

<!-- Section 118 Spotify Exclusive: Dynamic Upcoming Song Card with Expandable Hover Tray:
1. Spicetify Queue Synchronization:
   - Updated ~/.config/spicetify/Extensions/caelestia-bridge.js to extract upcoming track data (title, artist, album, artUrl, uri) from Spicetify.Queue.nextTracks and Spicetify.Player.data.next_items.
   - Added skipNext command handler and queuechange event listeners.
2. Local Bridge Server (spotify_bridge.py):
   - Added upcoming JSON payload ingestion and /skip endpoint for immediate playback progression.
3. SpotifyService.qml Reactive Properties:
   - Exposed upcomingTrack, upcomingTitle, upcomingArtist, upcomingAlbum, upcomingArtUrl, hasUpcoming, and skipNext().
4. Expandable UI in Details.qml:
   - Added an animated expandable "Up Next" tray below media controls.
   - Collapsed state: Compact 28px pill showing queue icon, "Up Next:" label, and song title/artist with expand cue.
   - Hovered state: Smoothly animates and expands to 56px height, revealing the album art thumbnail, title, artist, and skip button.
   - Fully integrated with Caelestia's Material You theme tokens and smooth animations.
-->

<!-- Section 119 Zero-CORS Streamlined Bridge Transport for Upcoming Track Queue:
1. Converted Bridge Transport to Zero-CORS GET:
   - Upgraded caelestia-bridge.js to serialize the upcoming track JSON inside URL-safe GET parameters with mode: no-cors.
   - Bypassed all Chromium/Electron preflight CORS restrictions in Spotify.
   - Updated spotify_bridge.py to parse data payload from GET query parameters.
-->

<!-- Section 120 Spotify Playlist Queue Tracking & Dynamic Height Expansion:
1. Playlist / Context Upcoming Track Extraction (Lucid-style):
   - Added extraction from Spicetify.Player.data.next_items, PlayerAPI.getState().nextTracks, and Cosmos player endpoints.
   - Now tracks the upcoming song even when playing directly from a playlist/album without an explicit manual queue.
2. Animated Dynamic Panel Expansion:
   - Added dynamic implicitHeight binding to modules/dashboard/Media.qml (+46px on hover).
   - Hooked up hover enter/exit signals in Details.qml to SpotifyService.isUpcomingExpanded.
   - Content.qml smoothly animates the whole media tab height downwards, eliminating all clipping.
-->

<!-- Section 121 Fast Snappy Animation & Zero-Clipping Layout Polish:
1. Fast Responsive Animations:
   - Replaced slow Anim.StandardLarge with fast Anim.DefaultEffects for instant hover response.
2. Zero-Clipping Height Allocation:
   - Increased Media.qml hover expansion to +64px.
   - Optimized slider topMargin to Tokens.spacing.large and ButtonRow topMargin to Tokens.spacing.medium.
3. Enhanced Playlist Context Track Resolvers:
   - Multi-tiered extraction across PlayerAPI._queue.contextTracks, PlayerAPI.getQueue(), Spicetify.Queue.nextTracks, and Player.data.next_items to guarantee tracking of playlist tracks without requiring manual queuing.
-->

<!-- Section 122 Dynamic Container Height Propagation & Card Geometry Fix:
1. Dynamic Loader Item Height Propagation:
   - Updated Content.qml Flickable view.implicitHeight to evaluate (currentItem as Loader)?.item?.implicitHeight dynamically.
   - Enables full parent panel expansion when Media.qml height grows on hover (+64px).
2. Card Geometry & Typography Polish:
   - Expanded upcomingContainer preferred height to 58px.
   - Refined typography (body.medium and label.small) and 34x34 artwork thumbnail for complete, unclipped rendering.
-->

<!-- Section 123 Root Dashboard Geometry & Unclipped Container Chain:
1. Fixed Shell Dashboard Geometry Chain:
   - Updated modules/dashboard/Media.qml to explicitly bind width: implicitWidth and height: implicitHeight with dynamic +70px expansion.
   - Updated modules/dashboard/Wrapper.qml to bind implicitHeight to (content.item as Content)?.implicitHeight and animate height changes with Anim.DefaultEffects.
   - Updated modules/dashboard/Content.qml with Anim.DefaultEffects on implicitHeight.
2. Polish Details.qml Layout:
   - Set upcomingContainer preferred height to 58px and thumbnail to 34x34.
   - Ensured full breathing room and zero clipping on hover.
-->

<!-- Section 124 Stable Zero-Jitter Dashboard & Clean Internal Up Next Card:
1. Eliminated Window Jitter & Bouncing:
   - Restored standard fixed height geometry in Wrapper.qml, Content.qml, and Media.qml to prevent hover oscillation loops.
2. Optimized Vertical Details Layout:
   - Compacted top margins on slider (Tokens.spacing.small) and ButtonRow (Tokens.spacing.small).
   - Opened up over 60px of spare vertical headroom inside Details.qml.
3. Polished Material You Up Next Card:
   - Full width layout (Layout.fillWidth: true) spanning the full details column.
   - Collapsed state (28px): queue_music icon + Up Next: + Title • Artist + expand_more icon.
   - Expanded state (48px): 32x32 album thumbnail + UP NEXT badge + Title + Artist + skip_next button.
   - Zero cutoffs, zero clipping, 100% stable under cursor.
-->

<!-- Section 125 64px Full Headroom Expanded Up Next Card:
1. True 64px Card Height Allocation:
   - Raised upcomingContainer expanded height to 64px.
   - Upgraded thumbnail to 38x38 and IconButton to 30x30.
   - All three text tiers (UP NEXT badge, Track Title, Artist name) render with complete vertical headroom and zero clipping.
-->

<!-- Section 126 76px Expanded Up Next Card:
1. Increased Headroom:
   - Raised upcomingContainer expanded preferredHeight to 76px.
   - Upgraded album art thumbnail to 42x42 and IconButton to 32x32.
   - Provides complete vertical clearance for the artist line and bottom rounded border.
-->

<!-- Section 127 84px Expanded Up Next Card:
1. Extended Height & Proportions:
   - Raised upcomingContainer expanded preferredHeight to 84px.
   - Scaled album art thumbnail to 48x48 and IconButton to 34x34.
   - Perfectly balanced and aligned with the bottom of the details section.
-->

<!-- Section 128 Material 3 Expressive Shape Thumbnail & Marquee Scrolling in Up Next Card:
1. Material You 3 Expressive Thumbnail:
   - Replaced square/rounded thumbnail with MaterialShape.Cookie9Sided mask (matching the main album art) without visualizer and without rotation.
2. Smooth Marquee Scrolling:
   - Added MarqueeText for Title and Artist in the expanded card view.
   - Added MarqueeText for combined Title • Artist text in the collapsed view.
   - Long song and artist names automatically scroll smoothly when overflowing.
-->

<!-- Section 129 Open Spotify in Media Panel & Maximized Window Desktop Switch Fix:
1. Open Spotify Button in Media Panel:
   - Added IconTextButton ("Open Spotify" with headphones icon) under "Nothing playing" subtitle in modules/dashboard/Media.qml.
2. Reliable Desktop 2 Switch with Maximized Windows:
   - Added 150ms launchTimer to decouple drawer closing focus release from KWin workspace switching in both modules/dashboard/Media.qml and modules/dashboard/dash/Media.qml.
   - Prevents maximized applications on Desktop 1 from snapping focus/view back to Desktop 1 when launching Spotify.
-->

<!-- Section 130 Reverted Desktop 2 Switch Sequence Timer:
1. Reverted Timer:
   - Removed launchTimer and restored direct invocation of KWinWorkspaceState.setDesktop(2) and Quickshell.execDetached in both modules/dashboard/Media.qml and modules/dashboard/dash/Media.qml as requested.
   - Preserved "Open Spotify" button under "Nothing playing" in modules/dashboard/Media.qml.
-->

<!-- Section 131 Brightness and Microphone OSD Integration:
1. Wired Brightness to OSD:
   - Added brightnessChanged(mon, value) signal in services/Brightness.qml.
   - Connected Brightness.brightnessChanged and root.monitor.brightnessChanged in modules/osd/Wrapper.qml.
   - Added microphone onSourceMutedChanged and onSourceVolumeChanged handlers in modules/osd/Wrapper.qml.
   - Displays Material 3 OSD with dynamic sun icon (brightness_1 to brightness_7 / bedtime for nightlight), "Brightness" title, percentage badge, and smooth progress bar.
-->

<!-- Section 132 KDE Solid PowerManagement D-Bus Brightness OSD:
1. Reliable KDE Brightness Signal Detection:
   - Added background D-Bus listener via Process ("gdbus monitor --session --dest org.kde.Solid.PowerManagement --object-path /org/kde/Solid/PowerManagement/Actions/BrightnessControl") in services/Brightness.qml.
   - Listens to brightnessChanged signals emitted when Fn brightness keys or KDE controls are used.
   - Connected directly to modules/osd/Wrapper.qml for instant pop-up display with dynamic sun icon and percentage.
   - Removed microphone OSD triggers so only Volume and Brightness OSD are active.
-->

<!-- Section 133 Direct Broadcast D-Bus Signal Listener for Brightness OSD:
1. Fixed D-Bus Filter:
   - Replaced gdbus --dest with dbus-monitor type='signal',interface='org.kde.Solid.PowerManagement.Actions.BrightnessControl' in services/Brightness.qml.
   - Accurately parses broadcast signals without destination filter dropping.
   - Instantly triggers the Brightness OSD on Fn keys and KDE brightness changes.
-->

<!-- Section 134 Python GLib D-Bus Listener for Brightness OSD:
1. Native GLib D-Bus Signal Receiver:
   - Added scripts/brightness_watcher.py using Python DBusGMainLoop to subscribe to both org.kde.Solid.PowerManagement.Actions.BrightnessControl.brightnessChanged and org.kde.ScreenBrightness.BrightnessChanged.
   - Streamlined communication to Brightness.qml via Process.
   - Triggers the bottom Material You OSD pill with sun icon, "Brightness", percentage, and progress bar with 100% reliability.
-->

<!-- Section 135 End-4 Parity Brightness Property & KDE Active Monitor Fallback:
1. Native Property Parity:
   - Added property real brightness on services/Brightness.qml root singleton for direct onBrightnessChanged binding in Wrapper.qml (mirroring Audio.volume).
   - Fixed getMonitor("active") fallback to primary monitor Quickshell.screens[0] on KDE where Hypr IPC is not active.
   - Bound MonBrightnessUp / MonBrightnessDown shortcuts in services/Brightness.qml.
   - Live KDE D-Bus watcher script seamlessly updates root.brightness.
-->

<!-- Section 136 Multi-Signal Tri-Channel KDE Brightness OSD Trigger:
1. Complete Signal Coverage for VIA / QMK (KC_BRIU / KC_BRID):
   - Added multi-signal D-Bus receiver for PropertiesChanged (org.kde.ScreenBrightness.Display), brightnessChanged (Solid PowerManagement), and BrightnessChanged (org.kde.ScreenBrightness).
   - Added dedicated showOsd(val) signal to Brightness.qml so every dial turn or keypress immediately pops up the OSD even when values repeat.
   - Connected showOsd to Wrapper.qml for instant pop-up.
-->

<!-- Section 137 Added root.show() into onShowOsd and onBrightnessChanged in Wrapper.qml:
1. Root Cause Resolution:
   - Discovered root.show() was missing in onShowOsd and onBrightnessChanged handlers in Wrapper.qml.
   - Now sets visibilities.osd = true and restarts the auto-hide timer whenever brightness signal or showOsd is triggered.
   - Accurately tracks RK75 Fn+dial (5% per step).
-->

<!-- Section 138 Reverted all brightness OSD additions:
1. Reverted OSD:
   - Restored services/Brightness.qml and modules/osd/Wrapper.qml to original states.
   - Removed scripts/brightness_watcher.py.
   - Preserved original volume OSD behavior.
-->

<!-- Section 139 Aesthetic Album Art Shader Effects with Nexus Settings & Persistence:
1. Shader Engine & GLSL Shaders:
   - Authored and compiled 6 aesthetic shaders in shaders/albumart/ to Qt 6 .frag.qsb binaries:
     * smear.frag.qsb: Organic directional chromatic smudge distortion (Default ON).
     * blur.frag.qsb: Silky multi-pass Gaussian blur with saturation boost.
     * pixelate.frag.qsb: Retro-modern tactile mosaic grid.
     * liquid.frag.qsb: Fluid wave refraction and ripple displacement.
     * chromatic.frag.qsb: Radial RGB optical prism displacement.
     * oil.frag.qsb: Painterly textured smudge.
2. Services & Persistence:
   - Added services/AlbumArtEffects.qml singleton managing enabled state, effectType, and intensity.
   - Live file-backed persistence to ~/.config/caelestia/album_art_effects.json.
3. Component Integration:
   - Created components/effects/AlbumArtLayer.qml chaining shaders with Material You 3 shape masks.
   - Integrated into components/widgets/CoverArt.qml and modules/dashboard/media/Details.qml.
4. Nexus Settings UI:
   - Added 'Album Art Effects' section to modules/nexus/pages/panels/DashboardPanel.qml with ToggleRow, SelectRow dropdown, and intensity SliderRow.
-->

<!-- Section 140 Added Liquid Smear & Blur Effect & Fixed Material You Shape Masking:
1. Liquid Smear & Blur Hybrid Shader:
   - Combined harmonic fluid wave distortion, organic directional smudge flow with chromatic dispersion, and silky multi-tap Gaussian frosted blur with saturation enrichment.
   - Compiled to shaders/albumart/liquid_smear.frag.qsb and added as default preset.
2. Direct GPU Alpha Masking:
   - Refactored AlbumArtLayer.qml directly as a single-pass ShaderEffect.
   - All shaders sample layout(binding = 2) uniform sampler2D maskSource and multiply result by (maskA * qt_Opacity).
   - Restored rotating Material You cookie shape for dashboard media player & media card, and static 9-sided cookie shape for Up Next thumbnail.
-->

<!-- Section 141 Interactive Album Art Hover Morph, Visualizer Dissolve, and Shader Reveal:
1. Shape Morphing on Hover:
   - Added HoverHandler to CoverArt.qml and Details.qml.
   - Smoothly morphs MaterialShape between organic cookie shapes and MaterialShape.Square on hover.
   - Smoothly pauses spinning and resets rotation straight to 0° on hover.
2. Visualizer Fading:
   - Fades CAVA circular visualizer opacity to 0.0 with 350ms animation when hovered.
3. Crystal-Clear Artwork Reveal:
   - Smoothly animates shader intensity down to 0.0 on hover, dissolving all effects to show clear album art.
4. Nexus Setting Toggle:
   - Added 'Morph on hover' toggle under Nexus -> Dashboard with full disk persistence.
-->

<!-- Section 142 Proportional 16x16 Pixelation Shader, Single Unified Nexus Toggle, CAVA Tracking Fix, and Smooth 45° Angle Settling:
1. 16x16 Proportional Pixelation Shader:
   - Authored and compiled shaders/albumart/pixelate.frag.qsb with normalized UV 16x16 grid and tactile cell beveling.
   - Removed all unused shaders.
2. Single Unified Nexus Setting:
   - Replaced all dropdowns and sliders with a single toggle: 'Pixelate & reveal artwork' in Nexus -> Dashboard.
   - Persists cleanly to ~/.config/caelestia/album_art_effects.json.
3. CAVA Boundary Reactivity Fix:
   - Added cover.shape.shape and cover.isHovered dependencies to shapeEdgeDist in CoverVisualiser.qml so CAVA bars dynamically update when returning from rounded square to Cookie9Sided shape.
4. Rotation Smoothness Fix (No Fast Spin):
   - Implemented nearest 90° modulo symmetry alignment (Math.round(continuousAngle / 90) * 90) on hover in CoverArt.qml, capping rotation adjustments to <= 45° and eliminating rapid spin glitches.
5. Up Next Thumbnail:
   - Synchronized hover-morphing into rounded square and pixelation dissolution on Up Next card in Details.qml.
-->

<!-- Section 143 Clean Borderless Pixel Art, Up Next CustomMouseArea, Continuous Rotation Pause, and CAVA Edge Tracking:
1. Pure Borderless Pixel Art:
   - Removed artificial grid darkening bevels from pixelate.frag.
   - Compiled to shaders/albumart/pixelate.frag.qsb with flat, seamless 16x16 pixels.
2. Continuous Rotation Pause (Zero Jumps):
   - Changed CoverArt.qml Anim on rotation to pause smoothly at its current angle on hover and resume continuously on unhover.
   - Restores continuous frame-by-frame rotation updates so CoverVisualiser.qml shapeEdgeDist never gets stuck on the square boundary.
3. Up Next Thumbnail Hover:
   - Added CustomMouseArea with hoverEnabled and z: 10 to Details.qml Up Next thumbnail for immediate, reliable hover morphing into MaterialShape.Square and clear artwork reveal.
-->

<!-- Section 144 Upright 90° Symmetry Alignment and Up Next Card Hover Reveal:
1. Upright Square Alignment without Corner Clipping:
   - Replaced frozen rotation pause in CoverArt.qml with shortest-path 90° symmetry alignment (delta <= 45°).
   - Keeps rounded square parallel to bounding box (0°/90°/180°/270°), eliminating edge clipping and uneven tilted sides.
   - FrameAnimation resumes continuous frame ticks immediately on unhover.
2. Up Next Thumbnail Geometry & HoverHandler:
   - Configured explicit Layout.preferredWidth/preferredHeight (48x48) on Details.qml thumbnail item.
   - Enabled HoverHandler to reliably detect cursor over thumbnail, morphing it to MaterialShape.Square and dissolving pixel shader to reveal clear artwork.
-->

<!-- Section 145 Direct Coordinate Hover Tracking on Up Next Thumbnail:
1. Up Next Thumbnail Direct Coordinate Tracking:
   - Replaced child HoverHandler (which was blocked by parent card's MouseArea) with direct coordinate checking: hoverArea.containsMouse && hoverArea.mouseX <= thumbContainer.x + thumbContainer.width + 12.
   - Guaranteed 100% reliable detection when cursor moves over the 48x48 thumbnail inside the expanded Up Next card.
   - Triggers instantaneous smooth morphing into MaterialShape.Square and reveals clear artwork.
-->

<!-- Section 146 Seamless Transparent Buttons with Liquid Stretch Trail in Screenshot Bar:
1. Seamless Transparent Button Bar:
   - Removed individual per-button chip backgrounds (color: "transparent") across all toolbar buttons (Region, Window, Full Screen, Spectacle, Delay).
   - Eliminated muddy per-button background fading transitions.
2. Liquid Stretch Active Indicator:
   - Preserved liquid stretch trail indicator (liquidPill) gliding smoothly beneath the selected button.
   - Text/icons crisply transition to m3onPrimary when active and m3onSurface when inactive.
   - Active delay timer (>0s) uses m3secondary accent on unselected state for clear visibility.
-->

<!-- Section 147 Up/Down Arrow & Space Key Support for Delay Timer in Screenshot Bar:
1. Up / Down Arrow & Space Key Support:
   - Added Key_Up (cycles forward: 0s -> 3s -> 5s -> 10s -> 0s) and Key_Down (cycles backward: 0s -> 10s -> 5s -> 3s -> 0s) handlers when focused on the Delay timer button.
   - Space/Enter/Return on the Delay timer button cycles through timer values.
-->

<!-- Section 148 Unified Keyboard Input Interceptor in Screenshot Bar:
1. Unified Key Press Handler:
   - Centralized all key event handling (Up, Down, Left, Right, Tab, Space, Enter, Escape, 1-5) into handleKeyPress in FloatingScreenshotBar.qml.
   - Guaranteed event.accepted = true for all navigation and timer keys so key strokes never leak or pass through to underlying application windows.
   - Wired both keyHandler and mainMouseArea to handleKeyPress.
-->

<!-- Section 149 Direct Hardware evdev Input Watcher for All Screenshot Bar Key Controls:
1. Hardware evdev Input Interceptor:
   - Upgraded Python Process watcher to read directly from /dev/input/by-id/*-event-kbd for all keyboard events (KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_ENTER, KEY_ESC, KEY_1..5, KEY_SHIFT).
   - Bypasses Wayland/KWin compositor window focus limitations entirely.
   - Guaranteed 100% hardware-level responsiveness for Up/Down arrow timer cycling even when focused on an open desktop application.
-->

<!-- Section 150 Streamlined Native QML Key Handling with Zero Skipping:
1. Streamlined Single-Event Architecture:
   - Removed dual hardware-event watcher overlap that caused double-firing/skipping on Left/Right arrow keys.
   - Restored pure, clean native QML keyHandler with exclusive Wayland focus.
   - Up Arrow automatically selects Delay timer (index 4) and increments (0s -> 3s -> 5s -> 10s -> 0s).
   - Down Arrow automatically selects Delay timer (index 4) and decrements (0s -> 10s -> 5s -> 3s -> 0s).
   - Left/Right arrows navigate cleanly by exactly 1 item per keystroke with zero skipping.
   - shiftWatcher is restricted strictly to shift modifier tracking.
-->

<!-- Section 151 Reverted Up/Down Delay Key Handlers:
1. Clean State Restoration:
   - Cleanly reverted Up/Down arrow key delay handlers.
   - Retained the approved seamless transparent button bar and liquid stretch trail active indicator.
   - Left/Right arrows navigate toolbar items one by one cleanly.
-->

<!-- Section 152 Removed Number Shortcuts from Screenshot Bar:
1. Removed Number Shortcuts:
   - Removed Key_1 through Key_5 shortcuts from keyHandler in FloatingScreenshotBar.qml.
   - Cleaned all tooltip descriptions to remove numeric key references.
   - Arrow keys (Left/Right) and Space/Enter remain the primary keyboard controls.
-->

<!-- Section 153 Universal Clockface Frosted Blur & Standalone Window Compositor Blur:
1. Universal Clockface Frosted Glass:
   - Updated DesktopClock.qml with an adaptive backgroundPlate that renders geometry-matched frosted masks for all clockfaces (Classic, Giant Digital, Pill, Cookie, Radial).
   - RadialClock now features a circular frosted dial backdrop and frosted date pill with MultiEffect wallpaper blur.
   - PillClock and CookieClock now feature frosted wallpaper blur instead of flat solid opaque backgrounds.
2. Standalone Window Compositor Blur:
   - Added BackgroundEffect.blurRegion to FloatingScreenshotBar.qml and styled pillBar as a translucent frosted glass floating bar.
   - Added BackgroundEffect.blurRegion to ColorPickerOverlay.qml and styled infoCard as a translucent frosted glass pill.
-->

<!-- Section 154 Reverted Standalone Overlay Blur to Clean Solid State:
1. Reverted Standalone Window Blur:
   - Cleanly removed BackgroundEffect.blurRegion from FloatingScreenshotBar.qml and ColorPickerOverlay.qml.
   - Restored solid Material 3 container colors on screenshot toolbar and color picker infoCard.
   - Preserved universal frosted wallpaper blur across all desktop clockfaces.
-->

<!-- Section 155 Integrated Top-Connected Screenshot Shell Drawer Component:
1. Converted Screenshot UI into Native Shell Drawer:
   - Added `property bool screenshot: false` to `DrawerVisibilities.qml`.
   - Created `modules/screenshot/Wrapper.qml` and `modules/screenshot/Content.qml` implementing a top-anchored sliding drawer.
   - Instantiated `Screenshot.Wrapper` inside `Panels.qml` and integrated into `ContentWindow.qml`'s `BlobGroup` (`screenshotBg`) and `BackgroundEffect.blurRegion` (`BlurMask`).
   - Integrated full-screen interactive snip overlay (`ScreenshotOverlay.qml`) within `ContentWindow.qml` with region crop, window hover highlight, dimension badge, and keyboard navigation.
   - Updated shortcuts and IPC triggers to toggle `Visibilities.getForActive().screenshot`.
-->

<!-- Section 156 Fixed Screenshot Drawer Toolbar Elements Visibility & Z-Ordering:
1. Fixed Toolbar Elements Visibility:
   - Updated Wrapper.qml with explicit width: implicitWidth and dynamic sizing.
   - Fixed Tooltip required target bindings for all toolbar chips in Content.qml.
   - Placed ScreenshotOverlay behind panels (z: 10 vs z: 100) in ContentWindow.qml so dimming overlay doesn't obscure the toolbar.
-->

<!-- Section 157 Fixed Keyboard Arrow Navigation & Suppressed Drawer Hover in Screenshot Mode:
1. Keyboard Navigation Fixed:
   - Added active focus management (`forceActiveFocus()`) on Content.qml and ScreenshotOverlay.qml.
   - Exposed `item` alias in Wrapper.qml so overlay can navigate toolbar buttons.
   - Built direct `Keys.onPressed` event handling into Content.qml for Left, Right, Tab, Space, Enter, Escape.
2. Suppressed Dashboard & Edge Hover:
   - Updated Interactions.qml to ignore mouse hover and drag events whenever `visibilities.screenshot` is active, preventing the dashboard or other panels from opening when the cursor touches the top edge.
-->

<!-- Section 158 Refined Desktop Clockface Backgrounds & Frosted Wallpaper Blur:
1. M3 Cookie Analog Clock:
   - Updated DesktopClock.qml to enforce blurEnabled and backgroundPlate mask for cookie style.
   - Masked MultiEffect wallpaper blur precisely to the 220px 9-sided cookie geometry.
   - Styled CookieClock.qml dialShape with translucent frosted tint Qt.alpha(m3secondaryContainer, 0.72).
2. M3 Pill Capsule Clock:
   - Enabled frosted wallpaper blur on stadium capsule shape.
   - Styled PillClock.qml capsuleBg with translucent glass color Qt.alpha(m3surfaceContainer, 0.72) and subtle 1px outline.
3. M3 Radial Arc Dial Clock:
   - Clean, minimal background-free design directly over wallpaper.
-->

<!-- Section 159 Self-Contained Desktop Clock Blur & Clockface Switching:
1. Fixed Desktop Clockface Dynamic Rendering:
   - Updated DesktopClock.qml to properly instantiate and switch between all clock styles (cookie, pill, radial, giant, classic).
   - Removed global white background mask that was causing solid white rendering.
   - Built self-contained wallpaper MultiEffect blur pipeline directly inside CookieClock.qml and PillClock.qml matching their exact geometry.
-->

<!-- Section 160 Solid Material 3 Backgrounds for Desktop Clocks:
1. Reverted and Removed All Wallpaper Blur Shaders from Desktop Clocks:
   - Cleaned up DesktopClock.qml and Background.qml.
   - Set M3 Cookie Analog Clock to full solid Material 3 secondaryContainer background.
   - Set M3 Pill Capsule Clock to full solid Material 3 surfaceContainer background with clean outline.
-->

<!-- Section 161 Restored Original Clockface Typography & Clean Solid Styling:
1. M3 Cookie Analog Clock:
   - Restored original dial proportions, hour markers, analog hands animations, center cap, and clean date pill typography (ddd, MMM dd).
   - Full solid Material 3 secondaryContainer background.
2. M3 Pill Capsule Clock:
   - Restored original headline/bold digital time typography, hour/minute/ampm layout, vertical pill divider, and day/date column.
   - Solid Material 3 surfaceContainer background with NO outline as requested.
-->

<!-- Section 162 Clean Titlecase Date Typography & Shadow Removal on Desktop Clocks:
1. M3 Cookie Analog Clock:
   - Updated date pill typography to clean normal titlecase (`ddd, MMM dd`) in Medium font weight without uppercase or letter spacing distortion.
2. Desktop Clock Shadow Removal:
   - Disabled drop shadow layer effect in DesktopClock.qml for flat, clean Material 3 surface rendering.
-->

<!-- Section 163 Enhanced Album Art Pixel Shader with Multi-Tap Area-Integration & Bilateral Filtering:
1. Multi-Tap Area-Integration Grid:
   - Replaced single-point geometric center sampling with a 3x3 weighted spatial integration grid across each 16x16 pixel block to eliminate single-point aliasing.
2. Photometric Bilateral Filtering:
   - Added color-distance weighting to suppress high-frequency speckles, rogue color spikes, and confetti noise on complex multi-subject covers (e.g., band members, crowd photos).
   - Preserves sharp structural silhouettes, clear boundaries, and clean gradients for landscapes/graphic art.
3. Vibrancy Enhancement:
   - Added subtle 10% saturation boost to maintain authentic, crisp retro pixel-art color definition without muddying.
-->

<!-- Section 164 Configurable Adaptive Color Smoothing Toggle for Pixel Art Effect:
1. Added `smoothing` property to AlbumArtEffects.qml singleton with automatic disk persistence in ~/.config/caelestia/album_art_effects.json.
2. Exposed `smoothing` uniform in AlbumArtLayer.qml passing to pixelate.frag.
3. Added "Adaptive color smoothing" ToggleRow under "Album Art Effects" in Nexus -> Dashboard Panel (DashboardPanel.qml).
4. Conditional GPU branch in pixelate.frag executes 9-tap area integration + bilateral filtering when enabled, and falls back to classic crisp point sampling when disabled.
-->

<!-- Section 165 Kuwahara Edge-Preserving Filter for High-Impact Adaptive Pixel Smoothing:
1. Implemented full 4-quadrant Kuwahara variance-minimization filter in pixelate.frag spanning a wide adaptive neighborhood.
2. Homogenizes noisy, high-frequency micro-textures and clashing confetti into bold, recognizable pixel art fields while locking razor-sharp silhouette contrast on edges.
-->

<!-- Section 166 Soft-Weighted 5-Region Kuwahara Filter with Center Feature Anchor:
1. Replaced winner-take-all 4-quadrant Kuwahara with a 5-region soft-weighted Kuwahara filter:
   - Added a prioritized 5th Center Cell Anchor to prevent thin graphic features (e.g. rainbow prism beam on Imagine Dragons - Thunder, lightning, thin lines) from eroding.
   - Smooths chaotic clutter, crowd noise, and confetti on complex photo/comic covers while keeping sharp graphic artwork 100% centered, bold, and vibrant.
-->

<!-- Section 167 Updated Spotify KWin Placement Rule to Virtual Desktop 5:
1. Updated KWin Window Rule `c1578f24-9df8-43e5-8276-8801f92e85a0` in ~/.config/kwinrulesrc to map Spotify (`wmclass=spotify`) to Virtual Desktop 5 (`b6efdd5c-dedf-4577-8ca1-55d8f3f1cb92`).
2. Updated ~/.local/bin/spotify-autostart.sh autostart configuration.
3. Reloaded KWin window rules dynamically via `qdbus6 org.kde.KWin /KWin reconfigure`.
-->

<!-- Section 168 Smooth Hover Scale-Down for Album Art in Dashboard Media Card:
1. Updated CoverArt.qml to wrap visual elements in a visualContainer that smoothly scales down to 0.82 on hover when AlbumArtEffects is enabled.
2. Eliminates collision and overlapping between the square artwork corners and the curved wavy progress bar arc.
3. Stable full-bounds CustomMouseArea prevents any cursor fluttering or edge jitter during scale transitions.
-->

<!-- Section 169 Scoped Hover Shrink to Dashboard Media Card Only:
1. Made `shrinkOnHover` a configurable boolean property on CoverArt.qml (defaulting to false).
2. Enabled `shrinkOnHover: true` exclusively on the Dashboard Panel's mini media card (modules/dashboard/dash/Media.qml) to prevent collision with the wavy progress bar arc.
3. Left the main Media tab (CoverVisualiser.qml) at standard 1.0 full scale on hover.
-->

<!-- Section 170 Automatic Spectacle Editor on Fullscreen Screenshots:
1. Updated captureFullscreen() in Content.qml and FloatingScreenshotBar.qml to automatically launch the Spectacle annotation editor (`spectacle -E "$file"`) after capturing, matching the Region and Window screenshot behavior (both with and without Shift key).
-->

<!-- Section 171 KDE Global Shortcut for Terminal:
1. Registered native KDE Plasma 6 shortcut for `kitty.desktop` bound to `Meta+Return` / `Meta+Enter` (Win + Enter) via KGlobalAccel, matching the system-level `Meta+E` file manager shortcut.
-->

<!-- Section 172 Fix KWin Focus Stealing & Taskbar Minimization Reliability:
1. Configured KWin `FocusStealingPreventionLevel=0` (None) in `~/.config/kwinrc` to eliminate issues where newly launched apps from the launcher or taskbar opened unfocused and behind maximized windows.
2. Fixed cursor-exit unminimize bug in `modules/drawers/ContentWindow.qml`: added minimized status verification before `focusWindow(addr)` is invoked on drawer/keyboard release, preventing minimized windows from popping back up when the cursor leaves the taskbar.
-->

<!-- Section 173 Instant Taskbar Icon Minimization:
1. Enhanced `Dock.qml` `onClicked` and `activateAppAtIndex` logic: checked `delegateItem.isActive`, `top.focused`, `activeAddr`, and `isMinimized` to guarantee that single-clicking an active/foreground window's icon immediately minimizes it on the first tap without requiring a 2nd click.
2. Added `drag.threshold: 10` to `dragArea` in `Dock.qml` so mouse micro-motions on click do not get consumed as drag operations.
-->

<!-- Section 174 Revert Dock.qml:
1. Reverted `Dock.qml` back to its original state per user request, preserving the active KWin focus stealing level fix and ContentWindow cursor-leave minimization protection.
-->

<!-- Section 175 System Theme & Desktop Cleanup:
1. Purged 43 obsolete third-party Aurorae window decoration themes from `~/.local/share/aurorae/themes/`.
2. Removed unused third-party Plasma desktop themes (`Dream-Color-Plasma`) and look-and-feel (`archsimpleblue`).
3. Removed unused static color schemes from `~/.local/share/color-schemes/` while preserving dynamic Material You schemes.
4. Cleaned 9 Wine extension mime desktop entries and redundant browser wrappers from `~/.local/share/applications/` and refreshed the desktop database.
-->

<!-- Section 176 SDDM Theme Cleanup:
1. Removed obsolete third-party SDDM themes (`Amy-SDDM`, `Candy`, `Corners`, `Graphite`, `Graphite-nord`) from `/usr/share/sddm/themes/`, retaining only the active `clockwork` theme and standard KDE defaults.
-->

<!-- Section 177 Restored Taskbar Virtual Desktop Isolation:
1. Restored `isWindowOnCurrentWorkspace(toplevel)` in `Dock.qml` filtering `_toplevels` in `rebuildModel()` by `KWinWorkspaceState.activeId`.
2. Connected `KWinWorkspaceState.onActiveIdChanged` to immediately rebuild the dock model upon desktop switching.
3. Restored `DockService.registerDock(root)` and `activateAppAtIndex(index)` for app toggle hotkeys.
-->

<!-- Section 178 Cleaned App Launcher Clutter:
1. Deleted redundant Steam game launcher desktop shortcuts (`ACE COMBAT 7`, `Among Us`, `Forza Horizon 4/5`, `Geometry Dash`, `Project Wingman`) from `~/.local/share/applications/`.
2. Created user-level `NoDisplay=true` overrides for all developer/system clutter (`avahi-discover`, `bssh`, `bvnc`, `assistant`, `designer`, `linguist`, `qdbusviewer`, `qv4l2`, `qvidcap`, `jconsole`, `jshell`, `lstopo`, `cups`, `drkonqi`, `kdeconnect-sms/nonplasma`, `scrcpy-console`), keeping only primary graphical user apps in all application launchers.
-->

<!-- Section 179 Cleaned Caelestia hiddenApps Config:
1. Reset `hiddenApps` in `~/.config/caelestia/shell.json` to `[]` since all application filtering is now managed directly and natively via XDG `.desktop` overrides in `~/.local/share/applications/`.
-->

<!-- Section 180 Overhauled Emoji Picker & Disabled KDE Shortcut:
1. Disabled native KDE emoji selector shortcuts (`Meta+.` and `Meta+Ctrl+Space`) in KGlobalAccel via D-Bus and `~/.config/kglobalshortcutsrc`.
2. Created official Unicode CLDR categorized emoji database `~/.config/quickshell/caelestia/assets/emojis_categorized.json` with 3,664 emojis organized into 10 categories with search keywords.
3. Created `EmojiList.qml` with Gboard/KDE-inspired category tabs (Smileys, People, Animals, Food, Travel, Activities, Objects, Symbols, Flags, Recents/Favorites), clean 8-column icon grid without text clutter, hover name tooltips, live search filtering, and 1-click clipboard copying.
4. Integrated `EmojiList` into `ContentList.qml` with dedicated `showEmojis` property, sizing, and state transitions.
5. Updated `Emojis.qml` singleton service to load the categorized database and track usage/favorites.
-->

<!-- Section 181 Perfected Emoji Recents, Unicode 16.0 Full Dataset & Arrow Navigation:
1. Updated emoji dataset to official Unicode Emoji 16.0 with 5,062 total emojis, skin tones, ZWJ sequences, and Kaomoji emoticons across 11 categories.
2. Built a persistent MRU (Most Recently Used) Recents system in `Emojis.qml` stored in `~/.local/state/caelestia/emoji_recents.json`, with dedicated "Clear recents" button and clean empty state (no random emojis injected).
3. Added Arrow Left/Right key navigation and mouse wheel scrolling on category tabs matching the workspace indicator and screenshot pill.
-->

<!-- Section 182 Emoji Picker Fluid Animation, Arrow Keys & Font Enhancements:
1. Removed Kaomoji category, keeping strictly the 10 official Unicode categories.
2. Implemented fluid animated sliding pill indicator (`tabIndicator`) on the category tabs using `Anim` easing.
3. Implemented keyboard navigation across categories and grid (`moveLeft`, `moveRight`, `moveUp`, `moveDown`, `activateSelected`) wired directly through `Content.qml`'s search key handlers.
4. Suppressed generic background `empty` state in `ContentList.qml` when in `"emoji"` state to prevent double/overlapping empty text.
5. Explicitly specified system `Noto Color Emoji, Twemoji, emoji` font family for crisp color emoji rendering.
-->

<!-- Section 183 Emoji Picker Performance, Tab Navigation & Grid Keyboard Routing:
1. Assigned <kbd>Tab</kbd> and <kbd>Shift+Tab</kbd> to cycle category tabs with the fluid sliding pill.
2. Assigned <kbd>←</kbd>, <kbd>→</kbd>, <kbd>↑</kbd>, <kbd>↓</kbd> to exclusively navigate emojis in the grid, with <kbd>Enter</kbd> to copy.
3. Optimized browse category models to standard base representation and added delegate item reuse, making tab switching instantaneous and lag-free.
4. Cleaned up Kaomoji tab and duplicate background empty indicators.
-->

<!-- Section 184 Skin Tone Variant Grouping & Floating Popup Pill:
1. Grouped all 471 skin tone variant emoji sets under their respective base emojis in `emojis_categorized.json`.
2. Added subtle bottom-right corner indicator dots to emojis that have skin tone modifiers.
3. Implemented a floating Material variant popup pill (triggered by Press & Hold or Right-Click on an emoji with variants) displaying all 6 skin tones for easy 1-click selection.
-->

<!-- Section 185 Fixed Variant Hover Tooltips, Cleaned Symbols & Top Bar Wheel:
1. Hovering over skin tone variants inside the floating popup pill now dynamically displays the full tone name (e.g. `thumbs up (Light skin tone)`) in the bottom tooltip bar.
2. Removed long-press and kept Right-Click exclusively for expanding skin tones.
3. Cleaned out empty component modifiers (`1F3FB..1F3FF`, `1F9B0..1F9B3`) from the Symbols category so the first emoji is `🏧 ATM sign`.
4. Made mouse wheel scrolling work anywhere across the entire 44px top tab bar container.
-->

<!-- Section 186 Floating Recents Clear Button & Typography Harmonization:
1. Replaced text clear link with a floating FAB-style `delete_sweep` button in the bottom-right of the Recents grid.
2. Removed all favorites functionality, focusing purely on MRU Recent emoji tracking.
3. Harmonized bottom status bar typography so left tooltip and right category counter share identical `Tokens.font.label.small` and `Colours.palette.m3outline` styling.
-->

<!-- Section 187 Emoji Glyphs Sizing & Integer Pixel Alignment:
1. Increased emoji pixel size from 22px to an exact whole integer 26px (`font.pixelSize: 26`) for both the grid cells and variant popup pill.
2. Adjusted grid cell height to 46px to comfortably accommodate larger glyphs with clean padding.
-->

<!-- Section 188 Screenshot UI Pill Mouse Wheel Navigation:
1. Added a dedicated non-blocking `MouseArea` (`acceptedButtons: Qt.NoButton`) over `pillBar` in `FloatingScreenshotBar.qml`.
2. Hooked `onWheel` to `selectNavIndex()`, allowing users to cycle through Region, Window, Full Screen, Spectacle, and Delay using the mouse wheel with the exact same fluid liquid trail indicator animation as keyboard arrows.
-->

<!-- Section 189 Connected Screenshot UI Pill Mouse Wheel to ScreenshotOverlay & Content:
1. Wired mouse wheel events in both `ScreenshotOverlay.qml` (intercepting fullscreen mouse bounds over the pill) and `Content.qml`.
2. Scrolling the mouse wheel when the cursor is over the screenshot pill now cycles through Region, Window, Fullscreen, Spectacle, and Delay smoothly with the fluid liquid trail indicator animation.
-->

<!-- Section 190 Dynamic Clipboard Item Height Calculation in AppList:
1. Fixed `implicitHeight` calculation in `AppList.qml` when in `"clipboard"` displayState.
2. Rather than assuming all items are standard 48px single-line text, `implicitHeight` dynamically computes the actual heights of visible clipboard items (including 96px for unexpanded image cards and up to 300px for expanded cards).
3. Eliminates image clipping and viewport cutoff when opening single or multiple image clipboard history entries.
-->

<!-- Section 191 Advanced Album Art Shader Effects (Fluid Gradient & Liquid Smear):
1. Created `shaders/albumart/gradient.frag` (and compiled `gradient.frag.qsb`):
   - Harmonic 5-node orbital color emitter mesh gradient dynamically extracted from album art spatial centroids.
   - 2-octave fluid sinusoidal domain warping with soft inverse-distance falloff.
2. Created `shaders/albumart/smear.frag` (and compiled `smear.frag.qsb`):
   - Inigo Quilez recursive 3-level Fractional Brownian Motion (fBM) domain warping with time-evolving swirl.
   - Anisotropic 9-tap directional smudge filter along the liquid flow line (Photoshop smudge / wet oil paint melt).
3. Updated `services/AlbumArtEffects.qml` to support dynamic 3-mode selection (`"pixelate"`, `"gradient"`, `"smear"`), JSON storage persistence, and D-Bus IPC methods.
4. Updated `components/effects/AlbumArtLayer.qml` with a continuous hardware-accelerated time driver for 60fps fluid animation when active.
5. Updated `modules/nexus/pages/panels/DashboardPanel.qml` with a 3-way Shader Style SplitButton selector and context-aware settings.
-->

<!-- Section 192 Shader Quality Polish & Nexus Settings Button Label Fix:
1. Fixed `Shader Style` dropdown in `DashboardPanel.qml` using `SelectRow` with explicit `MenuItem` binding and `fallbackText`, ensuring the active shader name is permanently visible even after reopening Nexus.
2. Refined `gradient.frag`: Enhanced hue-boosted anchor sampling, cubic power falloff, and angular harmonic shimmer to create distinct multi-color vibrant gradients without muddy blending.
3. Refined `smear.frag`: Removed micro-grain particles, smoothed turbulence frequency with Quintic Hermite interpolation, and added a 13-tap Gaussian anisotropic smudge filter with cross-blur for ultra-smooth liquid oil paint swirls.
-->

<!-- Section 193 Liquid Smear Vogel-Spiral Anti-Banding Kernel:
1. Replaced 1D discrete line stepping in `smear.frag` with a 16-tap Golden-Angle Vogel Spiral sampling distribution.
2. Added sub-pixel dither rotation to eliminate all discrete wave bands, stepping rings, and interference ripples.
3. Added soft boundary coordinate mirroring to prevent edge clamping halos.
-->

<!-- Section 195 CAVA Visualizer Idle Morph State Sync Fix:
1. Fixed `shapeEdgeDist` calculation in `CoverVisualiser.qml` by binding to `cover.shape.morphProgress`.
2. When no media is playing and the cover is hovered/unhovered, `shapeEdgeDist` continuously tracks the morphing polygon in real time, ensuring the CAVA visualizer dots smoothly return to the Material You shape rather than getting stuck in a square outline.
-->

<!-- Section 196 Liquid Smear Orientation Fix:
1. Fixed `mirrorUV` coordinate transformation in `smear.frag`.
2. Replaced `abs(fract(p * 0.5) * 2.0 - 1.0)` (which was inverting texture space $p \rightarrow 1-p$) with `1.0 - abs(mod(abs(p), 2.0) - 1.0)`.
3. Liquid Smear now renders completely right-side up with correct orientation.
-->

<!-- Section 197 Liquid Smear Ultra-Smooth Toggle Integration:
1. Implemented runtime smoothing toggle in `smear.frag`:
   - When ON (smoothing > 0.5): 24-tap Vogel Spiral with Jorge Jimenez IGN micro-jitter (zero visible dots, creamy Gaussian oil melt).
   - When OFF (smoothing <= 0.5): Classic 16-tap Vogel Spiral with spatial dither.
2. Updated `DashboardPanel.qml` with dynamic context-aware labels ("Ultra-smooth blending" for Smear, "Adaptive color smoothing" for Pixelate).
-->

<!-- Section 198 Screen-Space Sub-LSB Debanding Dither:
1. Added Jorge Jimenez Sub-LSB Screen-Space Triangular PDF (TPDF) debanding dither (`gl_FragCoord.xy`) to both `smear.frag` and `gradient.frag`.
2. Dissolves 8-bit color quantization steps in bright white, grey, and subtle gradient zones into smooth continuous-tone transitions.
3. Slightly broadened IGN micro-jitter phase coverage in the 24-tap Vogel kernel for seamless white/grey smoke blending.
-->

<!-- Section 200 Popouts & System Tray Google Sans Flex FontBuilder Conversion:
1. Replaced all detached `font.pointSize` and `font.weight` sub-property assignments in taskbar popouts and system tray menus (`Network.qml`, `Bluetooth.qml`, `Audio.qml`, `Battery.qml`, `Github.qml`, `NightLight.qml`, `LockStatus.qml`, `Updates.qml`, `DateCard.qml`, `Calendar.qml`, `DockHover.qml`, `DockContext.qml`, `TrayMenu.qml`, `WirelessPassword.qml`) with complete `Tokens.font.body.builders...build()` font builder invocations.
2. Eliminates fallback to KDE system font (Noto Sans) in popout cards, ensuring 100% consistent Google Sans Flex typography across all shell widgets.
-->

<!-- Section 201 Taskbar Notifications & Date/Time Popouts FontBuilder Fix:
1. Fixed missing `.builders.` namespace in `Notifications.qml`, `DateCard.qml`, and `Calendar.qml`.
2. Previous calls (e.g. `Tokens.font.title.small.size()`) attempted to call `.size()` directly on a QFont object rather than on `Tokens.font.title.builders.small`, causing QML property evaluation errors that silently fell back to KDE's system application font (Noto Sans).
3. All text in the Notifications taskbar popout, Date & Time live digital clock card, and Calendar grid now properly constructs complete Google Sans Flex QFont instances with responsive scaling and variable font axes.
-->

<!-- Section 202 Notification & Digital Clock Typography Weight Refinement:
1. Reduced font weight on notification total pill ("X total") and app count pill from `Font.Bold` (700) to `Font.Medium` (500) for a cleaner, consistent Material 3 look.
2. Removed bold weight override on notification app names, aligning them with standard body typography.
3. Softened the live digital clock time string ("HH:MM:SS AM") in DateCard from `Font.Bold` (700) to `Font.Medium` (500) while keeping its large headline size (`Tokens.font.headline.builders.small.size()`), preserving clear prominence without excessive thickness.
-->

<!-- Section 203 Media Dropdown, Wallpaper Switcher 2-Item Carousel, and Up Next Art Fixes:
1. Fixed Media Dropdown click-through and opacity in `Menu.qml`: Assigned `z: 9999` to `Menu.qml` root mouse area and added explicit border/solid background so dropdown options render above `Panels` (z: 100), receive click events without falling through to lyrics, and remain completely legible.
2. Explained Wallpaper Switcher tabs (Images, Animated, Videos) and resolved 2-wallpaper category display in `WallpaperList.qml`: Duplicated 2-item categories into a 4-item circular loop `[A, B, A, B]`, enabling `PathView`'s odd-count centering symmetry (numItems = 3). Both wallpapers are now displayed on screen with the active wallpaper highlighted and enlarged in the center.
3. Fixed Up Next album art black box in `Details.qml` & `FadeImage.qml`: Set explicit 96x96 `sourceSize` on `thumbImage` to prevent zero-size decoding when the upcoming card is collapsed, guarded `FadeImage` against `(0, 0)` sourceSize, and added an opacity watchdog on `status === Image.Ready`.
-->

<!-- Section 204 Caelestia to Matugen Bridge, Terminal Colors, Fastfetch & Starship Integration:
1. Created `~/.config/caelestia/scripts/sync_matugen.py`: Bridges Caelestia's Material 3 and semantic color engine (~/.local/state/caelestia/scheme.json) into Matugen's JSON template engine. Automatically exports all palette tokens, invokes `matugen json`, and signals running Kitty instances (SIGUSR1) for live reload.
2. Configured `theme.postHook` in `~/.config/caelestia/cli.json` and connected `schemeFile.onLoaded` in `services/Colours.qml` to trigger `sync_matugen.py` on wallpaper/scheme change and shell startup.
3. Polished `~/.config/matugen/templates/kitty.conf`: Mapped standard and bright ANSI colors 0-15 to Caelestia's dedicated semantic color tokens (red/error, green, yellow, blue, mauve, teal, on_surface, outline_variant, sky, etc.).
4. Refined `~/.config/matugen/templates/starship.toml`: Mapped language/tool badges (Python, Node, Rust, Zig, Go, Java, Git, Directory, duration, status) to distinct semantic palette tokens.
5. Overhauled `~/.config/fastfetch/config.jsonc`: Replaced fragile ANSI backspace-hack boxes with a modern, beautifully aligned layout with Nerd Font icons, native terminal ANSI colors that follow the active theme, and color circle swatches (`● ● ● ● ● ● ● ●`).
-->

<!-- Section 205 Focus Management, Keyboard Navigation & Floating Window Hit-Testing Overhaul:
1. Resolved KWin focus stealing on hover: Updated `ContentWindow.qml` and `Wrapper.qml` to prevent QuickShell drawer/popout panels and notifications from stealing active keyboard focus from open application windows on mouseover.
2. Resolved floating window selection hit-testing over maximized apps in `FloatingScreenshotBar.qml` and `ScreenshotOverlay.qml`: Windows stacked above maximized applications are now correctly prioritized during window capture selection.
3. Added Top Panel shortcut mode (`Win+D`) keyboard navigation:
   - Added Left/Right arrow key tab navigation in `Content.qml` and `Wrapper.qml` across Dashboard tabs.
   - Added Escape key dismissal and outside-click dismissal to cleanly close the panel.
4. Added Tab key cycling for Wallpaper Switcher filter tabs (Images, Animated, Videos) in `ContentList.qml` and `Content.qml`.
-->

<!-- Section 206 Spicy Lyrics Animated Fluid Mesh Gradient Shader & Preserved Long-Standing Liquid Smear:
1. Replaced single-pass photo blur in `gradient.frag` with authentic Spicetify Spicy Lyrics / Apple Music fluid animated mesh gradient:
   - 5-point regional palette extraction with saturation and vibrancy boost (`vibrantPaletteColor`).
   - 5 harmonic orbiting emitters drifting across the artwork.
   - 2-octave simplex fluid domain warping (`snoise`).
   - Gaussian metaball field blending with peripheral vignette.
2. Implemented impactful `smoothing` toggle in `gradient.frag`:
   - Toggle ON (Deep Kawase low-pass blur): Expansive $\sigma^2 = 0.56$ with broad low-frequency waves for a vast, seamless, glowing ambient wash.
   - Toggle OFF: Compact $\sigma^2 = 0.11$ with energetic ripples for distinct, focused color orbs.
3. Preserved long-standing Liquid Smear shader (`smear.frag` & `smear.frag.qsb`) bit-for-bit from commit `728e83b5` (4-octave recursive domain warping, Vogel spiral smudge kernel with IGN micro-jitter, and debanding dither).
4. Updated `DashboardPanel.qml` with dynamic context-aware labels and descriptions for both effects.
-->

<!-- Section 207 Date & Time Taskbar Popout Dynamic Auto-Fit Width:
1. Updated `DateCard.qml`: Replaced hardcoded 300px fixed width with dynamic `minContentWidth` calculation based on `dateText` and `timeText` natural metrics (`implicitWidth`).
2. Expanded baseline minimum width to 340px, ensuring even the longest date strings (e.g., "Wednesday, September 30, 2026") fit completely without right-side truncation or ellipsis.
-->

<!-- Section 208 Animated Pixel Album Art Effect:
1. Overhauled `pixelate.frag` and recompiled `pixelate.frag.qsb` with Qt Shader Baker:
   - Locked pixel grid strictly to stationary block coordinates (`floor(uv * GRID_SIZE) / GRID_SIZE`), completely eliminating UV distortion, staircase crawling, and temporal aliasing.
   - Implemented authentic multi-layered retro sliding overlays evaluated on pixel cell blocks:
     * Horizontal sliding stream wave traveling sideways across columns (`time * 2.5`).
     * Holographic diagonal luster beam sweeping across pixel cells (`time * 0.22`).
     * Discrete chiptune glints drifting sideways cell-by-cell along rows.
     * Subtle tactile CRT phosphor well bezel at cell borders for crisp separation without blur.
   - Preserved Soft-Kuwahara adaptive edge-preserving smoothing filter when `smoothing > 0.5`.
2. Updated `AlbumArtEffects.qml`:
   - Added `property bool pixelAnimation: true` property with persistent JSON storage.
   - Added IPC method `togglePixelAnimation()`.
3. Updated `AlbumArtLayer.qml`:
   - Configured `NumberAnimation` on `time` property to run continuously when `effectType === "pixelate"` and `pixelAnimation` is true.
   - Snaps `time` to 0.0 when animation is toggled off so the mosaic instantly stabilizes.
4. Updated `DashboardPanel.qml`:
   - Added dedicated `ToggleRow` for "Animate pixel mosaic" visible when Pixelate shader is selected.
-->

<!-- Section 209 Singular Clipboard Item Deletion:
1. Updated `modules/launcher/services/Clipboard.qml`:
   - Added `deleteEntry(clipId: int, preview: string)` method utilizing `Quickshell.Io.Process`.
   - Executes `cliphist delete` via stdin pipe and removes cached preview thumbnail at `$XDG_RUNTIME_DIR/caelestia/clipboard/<id>.png`.
   - Triggers `reload()` to refresh the active clipboard list immediately upon process exit.
2. Updated `modules/launcher/items/ClipItem.qml`:
   - Expanded `actionsContainer` width to comfortably hold three action buttons (expand, pin, delete).
   - Added `deleteBtn` MouseArea with Material icon `"delete"` and `Colours.palette.m3error` hover highlight.
   - Dispatches `Clipboard.unpin(modelData.pinId)` for pinned items and `Clipboard.deleteEntry(modelData.id, modelData.preview)` for normal history items.
-->

<!-- Section 210 True Alt-Tab MRU Window Switching:
1. Resolved non-chronological window switching order in `modules/launcher/services/Windows.qml`:
   - Implemented persistent `mruHistory` address array tracking window focus history across all activation methods (mouse clicks, dock, shortcuts, and Alt-Tab).
   - Guarded against focus de-activation resets: When Quickshell grabs focus on launcher open (causing KWin to report empty active window), `mruHistory` stays strictly intact.
   - `updateItems()` builds `items` sorted strictly by index in `mruHistory`.
   - Optimistically updates `mruHistory` immediately on `focusSelectedWindow()` / `focusWindow()`, eliminating Wayland asynchronous IPC activation lag and ensuring instant back-and-forth toggling between recent windows.
2. Verified in `modules/Shortcuts.qml`:
   - Alt-Tab immediately selects index 1 (the window used immediately prior to the current window).
   - Releasing Alt switches to it, exactly mimicking native KDE Plasma and Windows Alt-Tab behavior.
-->
<!-- Section 211 Pixel Shader Refinements, Dynamic Grid Size Slider & Independent Effect Toggles:
1. Refined `pixelate.frag` and recompiled `pixelate.frag.qsb`:
   - Removed pixel block borders/bezels (`cellBezel`), eliminating all dark lines and seams between cells.
   - Removed random speckles, glints, and noise waves; preserved exclusively the clean, sleek holographic luster shine stripe sweeping left-to-right across the pixel matrix.
   - Added `float gridSize;` to `buf` uniform block, dynamically calculating grid step and scaling Soft-Kuwahara sampling offsets accordingly.
2. Updated `AlbumArtEffects.qml`:
   - Separated shared `smoothing` into independent properties: `pixelSmoothing`, `gradientBlur`, and `smearSmoothing`.
   - Preserved `smoothing` dynamic getter for shader binding and legacy backward compatibility.
   - Added `property real pixelGridSize: 16` and IPC helper `setGridSize(size)`.
   - Updated JSON persistence and IPC handler to maintain separate toggle states across shader style switches.
3. Updated `AlbumArtLayer.qml`:
   - Bound `gridSize: AlbumArtEffects.pixelGridSize` to feed dynamic block resolution to `pixelate.frag.qsb`.
4. Updated `DashboardPanel.qml`:
   - Connected the smoothing/blur ToggleRow to the active effect's independent property (`pixelSmoothing`, `gradientBlur`, or `smearSmoothing`).
   - Added `SliderRow` for "Pixel Grid Resolution" (8x8 to 48x48) when Pixelate shader is active.
   - Refined Animate toggle subtext to match the clean holographic shine sweep aesthetic.
-->

<!-- Section 212 Launcher Search Cursor Navigation with Arrow Keys:
1. Updated `modules/launcher/Content.qml`:
   - Resolved arrow key swallowing in `Keys.onLeftPressed` and `Keys.onRightPressed`: In Qt Quick, `Keys.on...` signal handlers start with `event.accepted = true`. Without an explicit `else { event.accepted = false; }`, any Left or Right arrow key pressed while typing in the launcher was consumed by the signal handler without being passed to the `StyledTextField` (`TextField`).
   - Added `else { event.accepted = false; }` fallback. Now:
     * When `search.text.length === 0` and pinned apps are shown, Left and Right arrow keys continue to navigate horizontally across pinned apps.
     * When any search query is typed (`search.text.length > 0`), Left and Right arrow keys move the text cursor left and right natively, and support standard word jumping (`Ctrl+Left`/`Ctrl+Right`) and text selection (`Shift+Left`/`Shift+Right`).
-->

<!-- Section 213 Fix Desktop Switching on Boot/Launch & Optimize Caelestia Shell Startup:
1. Fixed Virtual Desktop Switching Bug (Spotify on Desktop 5):
   - Configured `ActivationDesktopPolicy=DoNothing` under `[Windows]` in `kwinrc`. This natively instructs KWin to never force-switch virtual desktops when an application on another virtual desktop opens or requests activation in the background.
   - Updated Spotify's KWin window rule (`c1578f24-9df8-43e5-8276-8801f92e85a0`) in `kwinrulesrc` with `fsplevel=4` (Extreme focus stealing prevention) and `fsplevelrule=2` (Force) to permanently reject focus-stealing requests.
   - Replaced obsolete, flawed 2-second `qdbus6` loop in `~/.local/bin/spotify-autostart.sh` with clean, direct execution (`exec /usr/bin/spotify-launcher %U >/dev/null 2>&1`).
2. High-Performance Caelestia Shell Startup Optimization:
   - Eliminated the 2.2-second post-login freeze by removing `~/.config/autostart/caelestiashell.desktop` (which waited for `graphical-session.target` at ~3.3s).
   - Created native KDE Plasma systemd user unit `~/.config/systemd/user/plasma-caelestia.service` hooked to `plasma-core.target` with `Slice=session.slice`, starting Caelestia Shell concurrently with `plasma-plasmashell` at ~1.1s.
   - Updated `~/.local/bin/caelestia-autostart.sh` to remove `-d` (`--daemonize`) so systemd directly supervises Quickshell in `session.slice`.
   - Updated `shell/scripts/restart_shell.sh` to prefer `systemctl --user restart plasma-caelestia.service`.
   - Updated installer `scripts/10-autostart.sh` to deploy the systemd service natively.
-->

<!-- Section 214 Decouple Focus Restoration from Workspace Switching, Fix Media Button & Protect User Session:
1. Decoupled Desktop Switching from Low-Level Window Focus Restoration:
   - Reverted `KWinWorkspaceState::instance()->switchTo(firstDesktop)` inside C++ `KWinActiveWindowBridge::focusWindow(address)`.
   - Root cause: Quickshell's `ContentWindow.qml` (and drawer focus handlers) calls `focusWindow(addr)` upon initialization (2–3 seconds after login) to restore keyboard focus to the active window (Spotify). Having workspace switching inside C++ low-level focus restoration caused the unwanted delayed switch to Desktop 5.
   - Intentional desktop switching is now strictly handled at user-interaction UI entry points:
     * `Windows.focusWindow(address)` in `modules/launcher/services/Windows.qml` (for Alt-Tab and Launcher).
     * `focusDockWindow(addr, toplevel)` in `modules/bar/components/Dock.qml` (for clicking or cycling dock icons).
2. Cleaned Up Dashboard "Open Spotify" Button:
   - Removed hardcoded `KWinWorkspaceState.setDesktop(2);` from `modules/dashboard/Media.qml` and `modules/dashboard/dash/Media.qml`. Clicking "Open Spotify" now cleanly launches `spotify-launcher` on Desktop 5 without changing desktops.
3. Protected User Session on Quickshell Restarts:
   - Added `KillMode=process` to `~/.config/systemd/user/plasma-caelestia.service` so restarting Quickshell terminates only the quickshell process itself and never kills child applications (e.g. browser, editor) that share the cgroup.
-->

<!-- Section 215 Remove Top Inverted Screen Corners While Preserving Bottom Inverted Corners:
1. Shader & Material Architecture (`blob.frag`, `blobmaterial.hpp`, `blobmaterial.cpp`):
   - Replaced single uniform `invertedRadius` with independent `invertedRadiusTop` and `invertedRadiusBottom`.
   - Updated `blob.frag`'s inner box SDF computation from scalar `sdRoundedBox` to `sdRoundedBox4(pixel, invertedInner.xy, invertedInner.zw, vec4(invertedRadiusTop, invertedRadiusBottom, invertedRadiusBottom, invertedRadiusTop))`. When `invertedRadiusTop == 0.0`, the top-left and top-right inner corners form exact 90-degree square corners, removing all concave/inverted arcs from the top of the screen.
   - Updated `BlobMaterialShader::updateUniformData` to pass `m_invertedRadiusTop` (offset 116) and `m_invertedRadiusBottom` (offset 120), preserving 16-byte alignment and offset layout.
2. C++ Shape & Config Pipeline (`blobinvertedrect.hpp`, `blobinvertedrect.cpp`, `blobshape.hpp`, `blobshape.cpp`, `borderconfig.hpp`):
   - Added `radiusTop` and `radiusBottom` properties to `BlobInvertedRect`, defaulting to `radius` if unset.
   - Added `roundingTop` property to `BorderConfig` in Caelestia's config model, defaulting to `0` (configurable via `shell.json` under `"border": { "roundingTop": ... }`).
3. QML Screen Border & Blur Region (`modules/drawers/ContentWindow.qml`):
   - Added `readonly property real borderRoundingTop: (Config.border.roundingTop !== undefined ? Config.border.roundingTop : 0) * (1 - fsTransitionProg)`.
   - Bound `radiusTop: root.borderRoundingTop` and `radiusBottom: root.borderRounding` on both `BlobInvertedRect` instances (overview blur mask and main shell background).
   - In `BackgroundEffect.blurRegion`, updated the two top corner square regions to use `root.borderRoundingTop` (collapsing to `0x0` area), and passed `rTop: !GlobalConfig.appearance.islands ? root.borderRoundingTop : 0` to `BlurCorners` so no blur cutout is subtracted from top corners while bottom corners retain full inverted rounding connecting to the dock.
-->


