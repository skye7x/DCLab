# DCLab - Interactive IT Infrastructure Simulator

## Overview
DCLab is an interactive network topology simulator for IT education and experimentation. Place network devices (routers, switches, firewalls, PCs, servers) on a canvas and connect them to simulate real IT infrastructure with working network services.

## Features
The simulator includes 50+ features across these categories:

### Network Layer (F1-F22, verified)
- **F1**: Traceroute with `find_path` and `get_link_between`
- **F2**: VLAN-aware BFS pathfinding
- **F3**: Subnet calculator dialog
- **F4**: NAT on routers (masquerade, WAN iface)
- **F5**: DNS service with nslookup/dig commands
- **F6**: Packet capture with static buffer
- **F7**: Link configuration dialog (bandwidth/latency/loss)
- **F8**: Link congestion with utilization tracking
- **F9**: Static routes editor (add/del syntax)
- **F10**: ARP table with serialization
- **F11**: Topology auto-layout
- **F12**: ICMP unreachable error types
- **F13**: User management (remove_user, set_password, authenticate)
- **F14**: Process manager UI dialog
- **F15**: APT simulator
- **F16**: Cron/scheduled tasks
- **F17**: SSH between devices
- **F18**: Multi-tab terminal (independent sessions)
- **F19**: Shell aliases
- **F20**: Environment variables
- **F21**: Web content editor dialog
- **F22**: journalctl/tail commands

### Additional Features (F23-F50)
- FTP service, groups/access control, email server, website builder
- Load balancer, reverse proxy, monitoring graphs, NAS backup
- Firewall rule tester, IDS device, VPN tunnel, password audit
- Attack simulator, certificates/HTTPS, copy/paste, minimap
- Theme toggle, export PNG, report export, project templates
- DHCP lease viewer, link outage drill, time-based events, lab scenarios
- iperf bandwidth testing

## Project Structure
- **Engine**: Godot 4.7.2
- **Language**: GDScript
- **Main scene**: `res://scenes/main.tscn`
- **Devices**: `scenes/devices/` - RouterDevice, SwitchDevice, FirewallDevice, Computer/Server, StorageDevice
- **Terminal**: `scenes/terminal/` - terminal_window.gd, terminal_tab.gd
- **Commands**: `terminal/command_processor.gd` - 70+ terminal commands
- **Dialogs**: `scenes/dialogs/` - configuration dialogs for devices/links/routes
- **Pictograms**: single source of truth in `tools/pictograms.json` (24x24 grid, monoline). Run `python3 tools/gen_pictograms.py` to regenerate `scenes/devices/pictogram_shapes.gd` (Godot) and `dclab-web/components/pictogramShapes.js` (site). `DevicePictograms` renders them at any size.

## Building & Running
- Run directly from Godot 4.7.2 editor
- Or export as desktop application via Project > Export

## Recent Fixes
- Parse errors fixed in `_cmd_groups` and `_cmd_email` (replaced `match` with `if/else`)
- Device configuration dialogs now support `setup()` before or after `add_child()`
- Terminal crash prevention with `_pending_text` buffer and null checks
- Pictograms replaced generic icons using `DevicePictograms.draw_device()`

## Controls
- **Ctrl+T**: New terminal tab
- **Ctrl+W**: Close current terminal tab
- **Double-click device**: Open terminal
- **Right-click device**: Configuration options
- Drag devices to place on canvas
- Connect devices with links to create network topology