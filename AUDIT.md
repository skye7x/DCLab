# DCLab audit and redesign notes

Scope: static review of the Godot project (69 scripts, ~9.4k lines) and the Next.js site.
**Not verified at runtime**: Godot and `npm` were not available, so nothing here was run in the
editor or built. Open the project in Godot 4.7.2 once and check the Output panel.

## Errors found

| Sev | Where | Problem | Status |
|---|---|---|---|
| Critical | `scenes/panels/toolbox.gd` | Inner class `PaletteButton` contained only `_init`; `_gui_input`, `_notification`, `_draw` were at file level but used `_pressed`, `_hovered`, `pressed.emit()`. Also `icon._draw = ...` (cannot assign to a virtual) and Godot 3 `update()`. Would not parse. | Rewritten |
| High | `dclab-web/app/page.jsx` | `<img src="/icon.svg">` ignores `basePath: "/DCLab"`, so the logo 404s on GitHub Pages. | Fixed (`NEXT_PUBLIC_BASE_PATH`) |
| Medium | `scenes/devices/device_node.gd` | Local `var draw_rect` shadows `CanvasItem.draw_rect()` (SHADOWED warning, fragile). Also two status indicators (ColorRect + pictogram LED), red/green only. | Fixed |
| Medium | `project.godot` | No clear colour set, canvas falls back to Godot's default grey. | Set to #0a0a0a |
| Medium | `app/globals.css` `.statement` | Body text colour `--hair` (#ebebeb on #fafafa), about 1.1:1 contrast, unreadable. | `--mute` |
| Medium | `app/globals.css` | Nav links all hidden at <=640px with no menu. | "Features" kept; add a menu trigger next |
| Low | `components/Hero.jsx` | Unused `next/dynamic` import. | Removed |
| Low | `package.json` | `three` and `typescript` are installed but never imported. | Left alone (changing deps needs a new lockfile, CI uses `npm ci`) |
| Low | `page.jsx` | `f.c` / `f.star` read from FEATURES but never defined. | Left alone |
| Low | workflow | Error text referenced `next.config.ts`; file is `.js`. | Fixed |
| Hygiene | repo root | `_smoke_*.gd/.tscn/.uid`, `_f23/24/25_out/err.txt`, `log_output.txt`, `temp_git_log.txt` are committed debug output. `_f24_err.txt` is UTF-16. | Added to `.gitignore`; run the `git rm` below |

The old logs show two parse errors in `terminal/command_processor.gd` (lines 1298, 1333). Both are
already fixed in the current source.

```
git rm --cached _smoke_* _f2*_out.txt _f2*_err.txt log_output.txt temp_git_log.txt
```

## Pictograms

- `tools/pictograms.json` is the single source. `tools/gen_pictograms.py` writes the Godot data
  and the web data, so the app and site show the same six icons (router, switch, firewall, server, PC, storage).
- Old pictograms used hard-coded pixel offsets (3px, 12px, ...), so they broke at the 20px toolbox size.
  New ones scale from the 24-unit grid; stroke is 1.5 units, one ink colour, device colour only tints fills.
- The skill `design-taste-frontend` says never hand-roll icons. These are domain pictograms
  (a brick-wall firewall, Cisco-style router arrows) that no icon library ships, so they are drawn
  once, on one grid, and generated rather than hand-copied.
- `tools/pictograms_preview.svg` is a contact sheet.

## Design (Vercel / Geist tokens)

Palette `#0a0a0a / #111 / #1a1a1a`, hairline `#2e2e2e`, ink `#ededed`, body `#a1a1a1`, mute `#6b6b6b`,
accent `#3291ff`. App chrome radius 6, cards 10, popups 8. Grid is neutral white at 4.5% / 9%.
Node status is a shape as well as a colour: filled dot = running, hollow ring = off.

Design read used: *developer-tool app + landing page for students/self-taught sysadmins, calm
Geist-style minimal language, official-system-free (Godot Theme + Next.js)*.
The taste skill targets landing pages, so for the Godot app only its colour, icon and
"no default-template" rules were used.

## Not done

- Live Web Interface Guidelines text could not be fetched (no network). The review above used the
  guidelines from memory, not the current file, so re-run `/web-design-guidelines` against `dclab-web/` once online.
- No mobile menu trigger yet, no dark-mode contrast check of `.btn.p`.
- ~9.4k lines of GDScript were scanned mechanically (indentation, block bodies, missing resources,
  dangling signal targets, Godot 3 APIs), not read line by line.
