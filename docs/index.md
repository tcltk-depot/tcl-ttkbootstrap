# ttkbootstrap for Tcl/Tk

A native Tcl/Tk port of the ttkbootstrap theme extension — bringing modern flat
Bootstrap-inspired themes and 64 widgets to Tcl/Tk 9.

**Version 1.5.0** — 27 Original widgets + 37 SVG widgets · 18 themes · Auto-scaling

## Documentation

| Section | Description |
|---------|-------------|
| [Getting Started](gettingstarted/installation.md) | Installation and requirements |
| [Tutorial](gettingstarted/tutorial.md) | Step-by-step guide with examples |
| [Widget Reference](widgets.md) | All 64 widgets with API and examples |
| [SVG Widgets Guide](gettingstarted/svg-widgets.md) | SVG widget architecture and usage |
| [Themes](themes/index.md) | 18 built-in themes (13 light, 5 dark) |
| [Style Guide](styleguide/index.md) | Bootstyle colours and styling patterns |
| [Auto-Scaling](gettingstarted/scaling.md) | HiDPI and large display support |
| [API Reference](api/index.md) | Core functions and procedures |
| [Cookbook](cookbook/index.md) | Short focused recipes |
| [Gallery](gallery/index.md) | Demo applications |
| [License](license.md) | MIT License |

## Quick Start

```tcl
source ttkbootstrap.tcl

ttkbootstrap::Window -themename litera -title "My App" -size {800 600}

ttk::button .btn -text "Hello" -style "primary.TButton" \
    -command {puts "Hello World!"}
pack .btn -pady 20

# Or use an SVG pill button
ttkbootstrap::PillButton .pill -text "Click Me" \
    -bootstyle success -command {puts "Clicked!"}
pack .pill -pady 10
```

## Run the Showcase

```bash
./tclkit-9.0.3-Linux64-intel-tk gallery/showcase.tcl
```
