# Changelog

## 1.5.0 (2026-06-02)

### New Features
- **Outer-path accessors for input widgets** — `SVGEntry`, `SVGCombobox`,
  `SVGSpinbox`, `SVGSearchBar`, and `SVGFormField` now provide
  `Widget::get`, `Widget::set`, `Widget::clear`, and `Widget::widget`
  subcommands so you no longer need to reach into child paths
  (`.e.ent`). `SVGCombobox::values` reads or sets the dropdown list.
  Child paths still work, so existing code is unaffected.

### Improvements
- **Range validation with auto-correction** — `SVGScale` now swaps a
  reversed `-from`/`-to` range (and widens an empty one) with a warning
  instead of rendering oddly; `SVGMeter` guards against a zero or negative
  `-amounttotal`. Warnings go to stderr via a new internal `_warn` helper
  and never crash the app.

### Documentation
- Added a **Gotchas & Common Pitfalls** section to the widget reference,
  man page, and HTML docs.
- Softened the input-widget gotcha now that outer-path accessors exist.
- Bumped all version strings to 1.5.0.

### Testing
- Added accessor and range-validation tests; full suite verified on
  tclkit 9.0.3 (Linux64).

## 1.4.5 (2026-05-18)

### New Features
- **Square Toggle Switches** — added `Square.TCheckbutton` style demos to the
  Buttons page of the widget showcase, alongside the existing round iOS-style toggles
- **Rounded Buttons** — added `Round.TButton` and `Outline.Round.TButton` demo
  rows to the Buttons page
- **Theme Selector in Navbar** — live theme switcher now visible in the top-right
  of every showcase page (no longer requires navigating to Settings)
- **MDI Close Button** — added × close button to the MDI desktop menu bar
- **MDI Stays Open** — closing the MDI window (× or WM close) now returns to the
  showcase instead of closing the entire application
- **Gallery App Keyboard Focus** — entry fields in gallery apps now receive
  keyboard input correctly using `wm attributes -type dialog`
- **Media Player Redesign** — blue buttons with white SVG icons; popup tooltip
  shows which control was pressed

### Bug Fixes
- Fixed Z-order stacking in MDI — dragged windows now always appear on top
- Fixed MDI windows going behind other windows when clicked
- Fixed `_close_gallery` in MDI apps not returning to showcase
- Fixed `wm descendants` error (not available in this tclkit build)
- Fixed `namespace delete` causing "deleted interpreter" errors when closing
  gallery apps
- Fixed global proc dispatch for button `-command` scripts running at global scope
- Fixed `tk_messageBox`, `tk_getOpenFile`, `tk_chooseDirectory` using WM dialogs
  inside MDI (now uses themed pure-Tk dialogs)
- Fixed `ttk::scale -command` firing before proc is defined (media player)
- Fixed `pack propagate` on MDI body frames causing windows to shrink to content size
- Fixed showcase closing when individual gallery app is closed

### Documentation
- Updated all docs to version 1.4.5
- Rewrote Getting Started tutorial with detailed examples covering:
  buttons, toggle switches, forms, progress bars, meters, scrolled frames,
  MDI desktop, theming custom widgets, and a complete task manager app
- Updated installation guide with full directory structure and gallery app list
- Removed requirement for Tcl/Tk 8.6+ (now requires 9.0+ only)

## 1.4.4 (2025-06-01)

### New Features
- MDI Desktop (`gallery/mdi.tcl`) — full rewrite using single-interp namespace
  isolation; eliminates two-window Z-order problems of the previous architecture
- Widget showcase updated with 11 navigation sections
- Splash screen support
- MouseWheel fix for Tk 9 on X11 (`<MouseWheel>` D=±120)

### Bug Fixes
- Fixed border tracking in Floodgauge widget
- Fixed Meter number positioning and subtext sizing
- Fixed pure-Tk file chooser dialogs staying on top

## 1.4.3 (2025-03-15)

### New Widgets
- ToggleSwitch (iOS-style round toggle)
- StepProgress indicator
- Breadcrumb navigator
- Timeline widget
- SparkLine mini chart
- RatingBar (interactive and read-only)
- Badge / pill label
- Card container

## 1.4.2 (2024-12-01)

### New Features
- Automatic DPI/HiDPI scaling (`ttkbootstrap::_sp`, `_sf`, `_sp2`, `_sp4`)
- 18 built-in themes (13 light, 5 dark)
- DateEntry and DateRangePicker widgets
- TimePicker widget
- ScrolledFrame and ScrolledText
- StatusBar widget
- Sidebar navigation widget
