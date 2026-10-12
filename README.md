# DCLab - Interactive IT Infrastructure Simulator

[![Godot](https://img.shields.io/badge/Godot-4.7.2-blue)](https://godotengine.org)
[![Version](https://img.shields.io/badge/version-v0.4.0-green)](gdVer.dclver)

WEBSITE - [Visit DCLab](https://skye7x.github.io/DCLab)

DCLab is an interactive network topology simulator for IT education and experimentation. Place network devices on a canvas, cable them together, power them on, and work with them through real terminal commands - routers, switches, firewalls, PCs, servers and NAS storage all behave like miniature real machines.

## Table of Contents
- [Features](#features)
- [Controls & Shortcuts](#controls--shortcuts)
- [Terminal Commands](#terminal-commands)
- [Versioning & Update Check](#versioning--update-check)
- [Project Structure](#project-structure)
- [Building & Running](#building--running)

## Features

### Devices & Topology
- **6 device types**: Router, Switch, Firewall, PC, Server, NAS/Storage - each with its own pictogram, status badge and colour.
- **Device Library palette** (left panel): click a device, then click the canvas to place it; ghost preview follows the cursor; snap-to-grid placement.
- **Drag to move** devices with grid snapping; **rubber-band selection** on empty canvas; Shift/Ctrl+click multi-select; Select All.
- **Auto Layout** re-arranges devices in layers (routers → firewalls → switches → servers/NAS → PCs).
- **Cables**: click-to-connect with auto port allocation (switches/routers grow new ports when full); cables animate colour by state/usage; click a cable to edit bandwidth, latency, packet loss and enable/disable it.
- **Connection line hit-testing** and per-link **Link Configuration** dialog.
- **Undo/redo** for adds, moves and deletes (command-history pattern).

### Tools Panel (next to the Inspector)
- **Pointer (V)** - select & move mode (default).
- **Connector (C)** - click source, click target to cable them.
- **Delete (X)** - click a device to remove it.
- **C-key quick connect**: select a device → press **C** → click the target device. **Esc** cancels.
- Cursor changes per tool (arrow / crosshair / forbidden).

### Simulation Engine
- **Start / Pause / Stop** simulation with speed control (0.5x - 10x) and simulated clock display.
- **Packets animate** along cables (packet visuals with colour coding).
- Device/link counters and live zoom percentage in the toolbar.

### Networking
- **DHCP** on routers: link-up devices request addresses automatically (pool .100-.199).
- **Static IPs** via dialog or `ip addr add` in the terminal; `dhclient` for DHCP requests.
- **Routing tables** on routers, **static routes** dialog, automatic route learning.
- **Firewall** device with traffic filtering.
- **DNS service**: records (`dns add/rm/list`), `nslookup`, `dig` resolution.
- **ARP table**, `traceroute`, `nat`, `arp` commands.
- **Ethernet links** with bandwidth, latency, packet loss and utilization stats.
- **Packet Capture** tool: record and inspect traffic between devices.
- **Subnet Calculator** tool: ranges, broadcast, mask math.

### Operating System Simulation (per device)
- **DCLinux-like OS** with processes, users, environment variables, aliases, cron jobs.
- **Virtual file system**: `ls`, `cd`, `cat`, `mkdir`, `touch`, `rm`, `echo`, `tail`, permissions.
- **Users & auth**: `useradd`, `userdel`, `passwd`, `su`, `users`, `groups` - terminal prompts follow the current user (root `#` vs user `$`).
- **Services**: HTTP, SSH, Database, Email, FTP - start/stop/restart/status via `service` or right-click menu.
- **Process Manager** dialog, `ps`, `kill`, CPU/RAM/storage usage meters in the Inspector.
- **Power on/off/restart** per device; status badge on canvas.

### Terminal
- **Open anywhere**: double-click a device, right-click → Open Terminal, **Ctrl+T**, or the Inspector button.
- **Tabbed sessions** (up to 8 tabs): Ctrl+T new, Ctrl+W close, Ctrl+Shift+W close window, Ctrl+Tab/Ctrl+PgUp/PgDn cycle.
- **60+ commands** (full list below), Tab autocomplete, ↑/↓ history, Ctrl+L clear, `$VAR`/`${VAR}` expansion, aliases.
- **ssh `<user>@<ip>`** jumps between devices with a session stack (`exit` returns).
- **Logs toggle**: show simulator events for the device inside the terminal.
- **Embedded window** - stays inside the main app window (cannot be dragged out as a separate OS window).

### NAS / Storage
- **Shares dialog**: create/remove shares with size limits; `shares`, `share add/rm`, `mount` in the terminal.
- **Format** wipes data; disk usage via `df`.

### Web & Email
- **Web Content Editor** dialog for HTTP servers; `curl http://<ip>/` fetches pages.
- **Email service**: `email send/list` with a working mail queue between devices.

### UI / UX
- **Dark theme** with custom-drawn cards, pictograms and hairline chrome.
- **Resizable layout**: menu bar, toolbar, Device Library, canvas viewport, Tools panel, Inspector and bottom console are all drag-resizable splits; window starts maximized and stretches with the screen (**F11** fullscreen).
- **Inspector** (right): live device state - hardware, OS, services, interfaces/IPs, actions (Open Terminal, Configure, Power, Connect Cable).
- **Bottom console**: Console / Logs / Debug tabs (Ctrl+L toggles).
- **Menu bar**: File (New/Open/Save/Save As/Exit), Edit (Undo/Redo/Delete/Select All), View (grid, snap, zoom, layout, tools, fullscreen), Simulation (Start/Pause/Stop), Tools (Subnet Calculator, Packet Capture), Help (Instructions, About).
- **Context menus** for devices and canvas; **rename / duplicate** devices.
- **Hints**: blue toast hints appear as you learn the app - **closing a hint with × dismisses it permanently** (stored in `user://hints.cfg`, never shown again).
- **Start screen** with New Project / Open Project / sample "Small Office" topology.
- **Instructions window** (Help → Instructions): complete guide with every shortcut and terminal command.

## Controls & Shortcuts

### Canvas & tools
| Key | Action |
|---|---|
| **C** | Connect: select device → press C → click target |
| **V** | Pointer tool (select/move) |
| **X** | Delete tool (click device to remove) |
| **Del / Backspace** | Delete selection |
| **Ctrl+A** | Select all |
| **Shift/Ctrl+click** | Multi-select |
| **Ctrl+Z / Ctrl+Y** | Undo / Redo |
| **Ctrl+S / Ctrl+O** | Save / Open project |
| **Ctrl+D** | Delete selection |
| **Ctrl+L** | Toggle bottom log panel |
| **Ctrl+T** | Terminal for selected device |
| **Esc** | Cancel cable / placement / leave tool / deselect |

### View
| Key | Action |
|---|---|
| **Mouse wheel** | Zoom at cursor |
| **Middle-drag / Space+drag** | Pan |
| **Arrow keys** | Pan |
| **+ / −** | Zoom in / out |
| **F** | Zoom to fit all devices |
| **0** | Reset view |
| **G** | Toggle grid |
| **N** | Toggle snap-to-grid |
| **F11** | Fullscreen on/off |

### Terminal
| Key | Action |
|---|---|
| **Ctrl+T** | New tab |
| **Ctrl+W** | Close tab |
| **Ctrl+Shift+W** | Close terminal window |
| **Ctrl+Tab / Ctrl+Shift+Tab** | Next / previous tab |
| **Ctrl+PgUp / Ctrl+PgDn** | Cycle tabs |
| **Tab** | Autocomplete |
| **↑ / ↓** | Command history |
| **Ctrl+L** | Clear screen |
| **exit** | Return from `ssh` session |

## Terminal Commands

```
Files:      help clear pwd ls cd cat mkdir touch rm echo tail
System:     whoami hostname ps kill df mount env journalctl
Users:      useradd <name> userdel <name> passwd <name> <pass>
            su <name> [pass] users groups
Network:    ip ifconfig route arp nat traceroute
            ip addr add <ip>/<cidr> dev <iface>
            ip addr del dev <iface>
            ping <ip> [-c n]
DNS:        nslookup <host> dig <host> [type]
            dns add <host> <ip> | dns rm <host> | dns list
DHCP:       dhclient <iface>
Services:   service <name> <start|stop|restart|status>
            curl http://<ip>/
            email send <to> <subject> <body> | email list
NAS:        shares | share add <name> <MB> | share rm <name> | mount <share>
Shell:      ssh <user>@<ip> exit alias unalias export unset apt crontab pcap
```

## Versioning & Update Check

- **In-game version** is shown in the toolbar (e.g. `v0.4.0`), in the window title and in **Help → About**.
- `gdVer.dclver` - the version the running game reads (`res://gdVer.dclver`, JSON: `{"version": "0.4.0"}`).
- `version.json` - the published version on GitHub
  ([raw](https://raw.githubusercontent.com/skye7x/DCLab/main/version.json)).
- **On every launch** the game fetches `version.json` from GitHub and compares it with `gdVer.dclver`.
  While they differ, an **"Update available"** dialog appears each launch, showing both versions
  and a button that opens the repository.
- To release a new version: bump **both** files, commit and push to `main`.

## Project Structure
- **Engine**: Godot 4.7.2 · **Language**: GDScript
- **Main scene**: `res://scenes/main.tscn` (UI built in code by `scenes/main.gd`)
- **Workspace**: `scenes/workspace/` - canvas, selection, tools, placement, camera (`workspace.gd`, `camera_controller.gd`, `grid_renderer.gd`)
- **Devices**: `devices/` - `DeviceFactory` + Router/Switch/Firewall/Computer/Server/Storage classes; visuals in `scenes/devices/device_node.gd`
- **Panels**: `scenes/panels/` - `toolbar.gd`, `toolbox.gd`, `inspector.gd`, `tools_panel.gd`, `console_panel.gd`
- **Terminal**: `scenes/terminal/` - `terminal_window.gd`, `terminal_tab.gd`, `command_processor.gd` (60+ commands), `terminal_theme.gd`
- **Services**: `services/` - HTTP, SSH, Database, Email, FTP, DNS
- **Networking**: `networking/` - EthernetLink, Packet, Subnet, IPv4Address, RoutingTable, ArpTable, NetworkInterface, NetworkSimulator
- **OS simulation**: `operating_systems/` - filesystem, users, processes, cron, LinuxSystem
- **Dialogs**: `scenes/dialogs/` - device/link/IP/routes/shares/packet-capture/subnet-calc/web-content/process-manager
- **Core**: `core/` - `hint_manager.gd` (permanent-dismiss hints), `app_info.gd` (version), simulation engine, event bus, logging
- **Projects**: `projects/` - ProjectManager, ProjectSerializer (`.dclabproj`)
- **Pictograms**: single source of truth in `tools/pictograms.json` (24x24 grid, monoline). Run `python3 tools/gen_pictograms.py` to regenerate `scenes/devices/pictogram_shapes.gd` (Godot) and `dclab-web/components/pictogramShapes.js` (site). `DevicePictograms` renders them at any size.

## Building & Running
- Run directly from the Godot 4.7.2 editor (open `project.godot`, press F5).
- Or export as a desktop application via Project → Export (add `gdVer.dclver` and `version.json` as non-resource export filters).
