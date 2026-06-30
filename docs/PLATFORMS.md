# Platform Support

ttkbootstrap-tcl targets Tcl/Tk 9.0+ on Linux, macOS, and Windows.

## Tested

| Platform | Status | Notes |
|----------|--------|-------|
| Linux / X11 | ✅ Fully tested | Primary development platform |
| macOS / aqua | ⚠️ Code paths hardened, not yet hardware-tested | See notes below |
| Windows / win32 | ⚠️ Code paths hardened, not yet hardware-tested | See notes below |

## Platform-specific behaviour

All platform-specific code is wrapped in `catch` and degrades gracefully.

### OS theme auto-detection (`autoTheme`, `_detectOSTheme`)
- **Linux:** GNOME (`gsettings`), XFCE (`xfconf-query`), KDE (`kreadconfig6`/`kreadconfig5`)
- **macOS:** `defaults read -g AppleInterfaceStyle`
- **Windows:** registry `AppsUseLightTheme`
- **Fallback:** returns `light` if detection fails on any platform.

### Pop-up windows (tooltips, notifications, dialogs, date/time pickers)
- Use `wm overrideredirect` + `-topmost`.
- **Windows:** `-transparentcolor` is honoured, giving clean rounded corners.
- **macOS:** uses `-type utility`; notification banner uses sharp corners
  (`r=0`) so the rectangular toplevel never shows background through rounded
  corners (X11 limitation worked around the same way).
- **X11:** sharp-cornered notification card fills the toplevel exactly.

### Fonts
- `_safeFont` falls back to `TkDefaultFont` if a named font is unavailable,
  so font handling is consistent across platforms.

## Known limitations
- nanosvg (Tk 9's SVG renderer) does not support gradients, filters, drop
  shadows, or clip paths. All such effects are emulated with layered shapes.
- Animated/`overrideredirect` windows may show a brief flicker on some
  window managers; this is cosmetic.

## Verified on Tcl/Tk 9.0.3 (this release)

This release was run against the official **tclkit 9.0.3 (Linux64)** under a
headless X server:

- **Test suite:** 292 / 292 assertions passing.
- **Showcase:** all 11 pages build without error.
- **Interactive smoke tests:** modal dialog, notification banner, toggle
  animation, treeview expand/collapse, gradient-button press, and an
  18-theme switch stress test all pass.
- **Image-handle leak:** fixed — repeated create/destroy cycles now leave the
  image count stable (per-instance images are released on `<Destroy>`).
