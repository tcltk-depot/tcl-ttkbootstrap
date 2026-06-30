# Installation

No installation required! ttkbootstrap for Tcl/Tk is a self-contained package that runs directly with tclkit.

## Requirements

- **tclkit 9.0.3** or later (with Tk 9.0.3 built in)
- Linux x86-64, macOS, or Windows

> **Note:** Requires Tk 9.0+. Older Tk 8.6.x is not supported — this port
> uses Tk 9's SVG image rendering and updated ttk element APIs.

## Download

Download the latest release zip from the project page:

```
ttkbootstrap-tcl-1.5.0.zip
```

## Setup

1. Unzip the archive:
```bash
unzip ttkbootstrap-tcl-1.5.0.zip
cd ttkbootstrap-tcl-1.5.0
```

2. Make tclkit executable (Linux/macOS):
```bash
chmod +x tclkit-9.0.3-Linux64-intel-tk
```

3. Run the widget showcase:
```bash
./tclkit-9.0.3-Linux64-intel-tk gallery/showcase.tcl
```

## Using in Your Own Scripts

### Option 1 — From the package directory

Place your script inside the `ttkbootstrap-tcl-1.5.0` folder:

```tcl
package require Tk
lappend auto_path [file dirname [info script]]
package require ttkbootstrap

ttkbootstrap::Window -themename flatly -title "Hello" -size {400 300}
# ... your widgets ...
vwait forever
```

### Option 2 — Absolute path

```tcl
package require Tk
lappend auto_path /path/to/ttkbootstrap-tcl-1.5.0
package require ttkbootstrap

ttkbootstrap::Window -themename darkly -title "Hello" -size {600 400}
vwait forever
```

### Option 3 — Environment variable

```bash
export TCLLIBPATH=/path/to/ttkbootstrap-tcl-1.5.0
./tclkit-9.0.3-Linux64-intel-tk your_script.tcl
```

## Running Gallery Apps

All gallery apps run standalone:

```bash
./tclkit-9.0.3-Linux64-intel-tk gallery/showcase.tcl       # Full widget showcase
./tclkit-9.0.3-Linux64-intel-tk gallery/mdi.tcl             # MDI desktop
./tclkit-9.0.3-Linux64-intel-tk gallery/calculator.tcl      # Calculator
./tclkit-9.0.3-Linux64-intel-tk gallery/stopwatch.tcl       # Stopwatch
./tclkit-9.0.3-Linux64-intel-tk gallery/media_player.tcl    # Media Player
./tclkit-9.0.3-Linux64-intel-tk gallery/file_search_engine.tcl  # File Search
./tclkit-9.0.3-Linux64-intel-tk gallery/text_reader.tcl     # Text Reader
./tclkit-9.0.3-Linux64-intel-tk gallery/data_entry.tcl      # Data Entry Form
./tclkit-9.0.3-Linux64-intel-tk gallery/equalizer.tcl       # Equalizer
./tclkit-9.0.3-Linux64-intel-tk gallery/pc_cleaner.tcl      # PC Cleaner
./tclkit-9.0.3-Linux64-intel-tk gallery/back_me_up.tcl      # Backup Tool
```

## Directory Structure

```
ttkbootstrap-tcl-1.5.0/
├── ttkbootstrap.tcl          # Main package loader
├── pkgIndex.tcl              # Package index
├── everything_bagel.tcl      # Single-file full widget demo
├── test_all.tcl              # Test suite
├── widgets/                  # 35+ widget implementations
│   ├── window.tcl            # ttkbootstrap::Window
│   ├── meter.tcl             # Circular meter gauge
│   ├── floodgauge.tcl        # Flood-fill gauge
│   ├── toggleswitch.tcl      # iOS-style toggle switch
│   ├── scrolled.tcl          # ScrolledFrame / ScrolledText
│   ├── filechooser.tcl       # Pure-Tk file chooser (no WM)
│   ├── dateentry.tcl         # Date picker
│   ├── sidebar.tcl           # Collapsible sidebar
│   ├── card.tcl              # Bootstrap-style card
│   ├── badge.tcl             # Badge / pill label
│   ├── sparkline.tcl         # Mini inline chart
│   ├── ratingbar.tcl         # Star rating widget
│   ├── timeline.tcl          # Vertical timeline
│   ├── breadcrumb.tcl        # Breadcrumb navigator
│   ├── stepprogress.tcl      # Step progress indicator
│   └── ...
├── gallery/                  # Demo applications
│   ├── showcase.tcl          # Main widget showcase (11 sections)
│   ├── mdi.tcl               # MDI desktop environment
│   ├── calculator.tcl
│   ├── stopwatch.tcl
│   ├── media_player.tcl
│   ├── data_entry.tcl
│   ├── file_search_engine.tcl
│   ├── text_reader.tcl
│   ├── equalizer.tcl
│   ├── pc_cleaner.tcl
│   ├── back_me_up.tcl
│   └── ...
└── docs/                     # Documentation
    ├── gettingstarted/       # Installation and tutorial
    ├── styleguide/           # Per-widget style reference
    ├── api/                  # API reference
    └── cookbook/             # How-to recipes
```
