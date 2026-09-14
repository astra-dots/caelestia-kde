# Astra Caelestia KDE Shell

A technical desktop shell for KDE Plasma 6 and Quickshell.

This repository is a downstream fork of [ladybug-me/caelestia-dots-kde](https://github.com/ladybug-me/caelestia-dots-kde). It contains architectural refinements, performance enhancements, and user interface improvements.

---

## 1. System Specifications

| Parameter | Specification |
| :--- | :--- |
| **Compositor** | KWin 6 (Wayland) |
| **Shell Framework** | Quickshell (Qt 6.7+ / KF6) |
| **Plugin Layer** | C++20 with Qt D-Bus and KF6 bindings |
| **Color System** | Matugen (Material Design 3 algorithmic palette) |
| **Configuration Ecosystem** | [astra-dots/dotfiles](https://github.com/astra-dots/dotfiles) |
| **Active Branch** | `custom-modifications` |
| **License** | GPL-3.0-or-later |

---

## 2. Architectural Modifications

This fork includes over 70 commits of customizations and technical corrections:

### 2.1 Taskbar and Window Management
- **Show Desktop Active Indicator:** Added visual state tracking to the taskbar Show Desktop control. The button displays a single clean overlay when the desktop is active. Clicking the button again unminimizes open windows.
- **Unpinned Item Ordering:** Corrected window order logic in the taskbar for running applications that are not pinned.
- **Shader Pipeline:** Added debanding shaders to eliminate color banding on gradient panels and blurred backgrounds.

### 2.2 Application Launcher
- **Reveal on Hover:** Action buttons (Pin to Taskbar, Favorite, Hide) remain hidden by default. The controls smoothly appear when the cursor hovers over an application row.
- **Integrated Search:** Keyboard input routes directly to application and command filters without manual field selection.

### 2.3 Clipboard Manager
- **Format Support in C++ Plugin:** Corrected the regular expression pattern in `clipboardmanager.cpp` (`^\[\[ binary data .* \]\]$`). The manager now parses and caches clipboard images formatted in Bytes, KiB, and MiB without data loss.
- **Expandable Item View:** Added an expand control to clipboard history rows. Text items expand into a scrollable container for long multiline strings. Image items expand into a centered preview lightbox.
- **Hover Visibility:** Pin and expand controls appear only when the cursor enters the item row.

### 2.4 Audio Subsystem and Media
- **Flyout Audio Mixer:** Implemented dedicated volume sliders for individual audio applications and audio sinks.
- **Smoothed Audio Decay:** Changed visualizer pause behavior from an abrupt stop to a calibrated 350-millisecond animated decay curve.
- **Syllable-Synchronized Lyrics:** Implemented word-by-word synchronized lyric rendering connected to Spotify via Spicetify.

### 2.5 System Controls and Configuration
- **Quick Settings Power Toggle:** Added a cyclic power profile control (Performance, Balanced, Power-Saver) directly into the quick settings flyout.
- **Nexus Settings Typography:** Replaced unconstrained font styling with a strict typographic hierarchy. All labels, subtitles, and setting values now use consistent scale and contrast tokens.
- **Minimal Session Drawer:** Replaced dynamic mascot graphics with a minimal three-button layout (Log Out, Restart, Shut Down). The drawer supports direct keyboard navigation with the Tab and Arrow keys.
- **Notification Drawer:** Removed auxiliary minigames to maximize vertical space for notification cards.

---

## 3. Visual Overview

Screenshots captured directly from the live environment:

### Desktop Shell (Warm Palette)
![Desktop Shell Warm](https://raw.githubusercontent.com/astra-dots/dotfiles/main/assets/screenshots/desktop_warm.png)

### Desktop Shell (Cool Palette)
![Desktop Shell Cool](https://raw.githubusercontent.com/astra-dots/dotfiles/main/assets/screenshots/desktop_cool.png)

### Application Launcher Grid
![Application Launcher Grid](https://raw.githubusercontent.com/astra-dots/dotfiles/main/assets/screenshots/launcher_grid.png)

### Terminal and Shell Theming
![Terminal and Fastfetch](https://raw.githubusercontent.com/astra-dots/dotfiles/main/assets/screenshots/terminal_fastfetch.png)

---

## 4. Keybindings

The shell defines global shortcuts through the KWin global shortcut service and `Shortcuts.qml`:

| Key Combination | Target Action |
| :--- | :--- |
| `Super + D` | Toggle desktop view (minimizes or restores all windows) |
| `Super` | Toggle application launcher |
| `Super + Enter` | Start Kitty terminal |
| `Super + Tab` | Open KWin window overview |
| `Super + B` | Toggle notification sidebar |
| `Super + V` | Toggle clipboard history |
| `Super + Shift + S` | Select area for screenshot |
| `Super + Shift + C` | Start color picker |
| `Super + Ctrl + S` | Start or stop screen recording |
| `Super + 1` to `5` | Switch to workspace 1 through 5 |

---

## 5. Build and Installation Procedure

### 5.1 System Dependencies

Install required libraries and compilers on Arch Linux:

```bash
sudo pacman -S --needed \
    base-devel \
    cmake \
    extra-cmake-modules \
    qt6-base \
    qt6-declarative \
    plasma-workspace \
    kirigami \
    layer-shell-qt
```

Install Quickshell:

```bash
yay -S --needed quickshell-git
```

### 5.2 Build the C++ Shell Plugin

The repository includes a custom C++ plugin that provides native D-Bus and system interfaces:

```bash
cd /path/to/caelestia-kde/shell
cmake -B build -S plugin -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

### 5.3 Deploy the Shell Configuration

Create a symbolic link from this repository to your Quickshell configuration directory:

```bash
mkdir -p ~/.config/quickshell
ln -sfn /path/to/caelestia-kde/shell ~/.config/quickshell/caelestia
```

Restart the background user service:

```bash
systemctl --user restart plasma-caelestia.service
```

If you do not use systemd user services, run Quickshell directly:

```bash
quickshell -p ~/.config/quickshell/caelestia
```

---

## 6. Upstream Synchronization

To synchronize this fork with changes from upstream:

```bash
# Fetch latest commits from upstream
git fetch upstream

# Rebase the custom branch on top of upstream main
git checkout custom-modifications
git rebase upstream/main
```

Resolve any merge conflicts in QML files, re-run the plugin build, and test the shell.

---

## 7. Credits and Attributions

This project builds upon the work of the open-source community:

- **Original Caelestia Shell:** [Caelestia Dots](https://github.com/caelestia-dots)
- **KDE Plasma Port:** [ladybug-me](https://github.com/ladybug-me) and [0xSolanaceae](https://github.com/0xSolanaceae)
- **Quickshell Framework:** [outfoxxed](https://github.com/outfoxxed)
- **JSON Library:** [nlohmann/json](https://github.com/nlohmann/json)
- **Icon Assets:** [Haidir](https://bitbucket.org/dirn-typo/yet-another-monochrome-icon-set)

---

## 8. License

This repository is licensed under the **GNU General Public License v3.0 or later** ([GPL-3.0-or-later](LICENSE)).
