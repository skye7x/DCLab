# DCLab - Interactive IT Infrastructure Simulator

## Overview
DCLab is an interactive network topology simulator for IT education and experimentation. Place network devices (routers, switches, firewalls, PCs, servers) on a canvas and connect them to simulate real IT infrastructure with working network services.

## Features
The simulator includes 50+ features across these categories:
ing

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
