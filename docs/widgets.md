# ttkbootstrap-tcl Widget Reference

**Version 1.5.0** — 64 widgets (27 Original + 37 SVG) + 32 SVG Icons

## Table of Contents

- [Getting Started](#getting-started)
- [Original Widgets](#original-widgets)
- [SVG Widgets](#svg-widgets)
- [Core Functions](#core-functions)
- [Themes](#themes)
- [Auto-Scaling](#auto-scaling)
- [Gotchas & Common Pitfalls](#gotchas--common-pitfalls)



## Platform Support

The library targets Tcl/Tk 9.0+ on Linux (X11), macOS (Aqua), and Windows.

Platform-specific behaviour, all gracefully degraded:
- **Popups** (tooltips, dropdowns, notifications, dialogs) request `-topmost` so they stay above the app window on macOS/Windows; X11 window managers that ignore this still work.
- **Notification banner** attempts `-transparentcolor` (effective on Windows) and falls back to sharp corners elsewhere.
- **OS theme auto-detect** (`autoTheme`) reads GNOME/KDE/XFCE settings on Linux, `defaults` on macOS, and the registry on Windows — every probe is guarded and defaults to light if detection fails.
- **Mouse wheel** scrolling uses the correct delta convention per platform (win32 ÷120, aqua small floats, x11 Button-4/5).


## API Conventions

All widget methods follow a consistent `Widget::method` namespace convention:

```tcl
ttkbootstrap::SVGProgress::set $w 50
ttkbootstrap::SVGProgressRing::set $w 75
ttkbootstrap::SVGProgressRing::spin $w
ttkbootstrap::SVGBadge::set $w "NEW"
ttkbootstrap::SVGSparkLine::push $w 42
ttkbootstrap::SVGStepProgress::next $w
ttkbootstrap::SVGTreeview::insert $w "" "Root"
```

For backward compatibility, the older underscore forms (e.g. `SVGProgress_set`, `SVGBadge_set`, `SVGProgressRing_spin`) remain valid and call the same code.

### Input-widget accessors (1.5.0+)

The composite input widgets expose `Widget::method` accessors so you do not
have to reach into child paths:

| Method | SVGEntry | SVGCombobox | SVGSpinbox | SVGSearchBar | SVGFormField |
|--------|:--------:|:-----------:|:----------:|:------------:|:------------:|
| `::get $w` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `::set $w value` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `::clear $w` | ✓ | ✓ | ✓ | ✓ | ✓ |
| `::widget $w` (child path) | ✓ | ✓ | ✓ | ✓ | ✓ |
| `::values $w ?list?` | | ✓ | | | |

```tcl
ttkbootstrap::SVGEntry .e ; pack .e
ttkbootstrap::SVGEntry::set .e "hello"
puts [ttkbootstrap::SVGEntry::get .e]      ;# -> hello
ttkbootstrap::SVGEntry::clear .e

ttkbootstrap::SVGCombobox .cb -values {Red Green Blue} ; pack .cb
ttkbootstrap::SVGCombobox::set .cb "Green"
ttkbootstrap::SVGCombobox::values .cb {X Y Z}          ;# replace the list
```

`SVGFormField` also keeps its original `::isValid` and `::getValue` methods.
Passing `-textvariable` at creation remains the simplest option of all.

### Composite widgets are not `ttk` widgets

Most `SVG*` widgets are **composite widgets** built from a Tk `frame`, `label`,
or `canvas` rather than being native `ttk` widgets. Two practical consequences:

- They do **not** support `ttk`-style introspection or invocation such as
  `$w invoke`, `$w state`, or `$w cget -<ttk-option>`. Interact with them
  through their documented options, bound `-variable`s, and `Widget::method`
  subcommands instead.
- To change state programmatically, set the widget's `-variable` (for stateful
  widgets like `SVGToggleSwitch`, `SVGCheck`, `SVGRadio`, `SVGRatingBar`) or
  call its subcommand (e.g. `SVGProgress::set`). Reading state means querying
  that same variable.

For example, `SVGToggleSwitch` is flipped by clicking it or by setting its
`-variable`; calling `.sw invoke` on it has no effect.

---

## Gotchas & Common Pitfalls

These are verified behaviours that commonly trip people up.

### Input widgets wrap a real entry in a child path

`SVGEntry`, `SVGCombobox`, `SVGSpinbox`, `SVGSearchBar`, and `SVGFormField`
are composite widgets: the actual editable control is a **child** of the path
you created.

**As of 1.5.0 the easy way is the `Widget::get`/`set`/`clear` accessors**
(see *API Conventions → Input-widget accessors*), e.g.:

```tcl
ttkbootstrap::SVGEntry::set .e "hello"
puts [ttkbootstrap::SVGEntry::get .e]
```

If you call the raw Tk methods instead, remember they go on the **child**, not
the outer path — calling `get`/`insert`/`delete` on the outer path raises
*"bad option ... must be cget or configure"*. The child paths are:

| Widget | Outer path | Editable child to call `get`/`insert`/`delete` on |
|--------|-----------|----------------------------------------------------|
| `SVGEntry .e` | `.e` | `.e.ent` |
| `SVGCombobox .cb` | `.cb` | `.cb.cb` |
| `SVGSpinbox .sp` | `.sp` | `.sp.sp` |
| `SVGSearchBar .sb` | `.sb` | `.sb.ent` |
| `SVGFormField .ff` | `.ff` | `.ff.ent.ent` |

```tcl
ttkbootstrap::SVGEntry .e ; pack .e
.e.ent insert 0 "hello"          ;# correct
puts [.e.ent get]                ;# -> hello
# .e get   ;# WRONG: raises "bad option get"
```

The easiest way to read/write these is to pass `-textvariable` at creation and
work with that variable instead of widget paths.

### Composite widgets are not `ttk` widgets

As noted under *API Conventions*, `SVG*` widgets are built from `frame`,
`label`, or `canvas`. They do not respond to `$w invoke`, `$w state`, or
`ttk`-style `cget`. Drive them through `-variable`, `-command`, and
`Widget::method` subcommands.

### Errors are raised, not returned

The library fails fast with clear messages rather than silently doing nothing:

- `setTheme badname` → *"Unknown theme … Valid themes: …"*
- `getColor badkey` → *"Unknown color key …"*
- a bad `-bootstyle` → *"… invalid -bootstyle … must be one of: …"*

Wrap calls in `catch` if you are passing user-supplied values.

### Widget paths must be unique

Creating a second widget at a path that already exists raises *"window name
… already exists in parent"* (standard Tk behaviour). Destroy the old widget
first, or use a fresh path. This is the single most common cause of errors
when rebuilding UI dynamically.

### Animated widgets clean themselves up

`SVGProgressRing` (spinning), `SVGSkeleton`, and `SVGToggleSwitch` schedule
`after` timers and create per-instance images. Destroying them mid-animation
is safe — a `<Destroy>` handler cancels timers and releases images, so there
is no leak and no "invalid command" error from a stale callback.

### `-bootstyle light` / `dark` are valid but low-contrast

`light` and `dark` are accepted bootstyle values, but on a matching theme they
can blend into the background (e.g. a `light` button on a light theme). They
exist for completeness; prefer `primary`/`secondary`/etc. for visible accents.

### Numeric options are not range-checked

Values like `SVGScale -from 10 -to 0` (reversed), `SVGMeter -amounttotal 0`,
or a fractional `SVGRatingBar` value are accepted without error. They will not
crash, but they may render oddly. Validate ranges yourself if the values come
from user input.

### Run-time locale for the test suite

The bundled `tests/test_suite.tcl` prints Unicode box-drawing characters. On a
non-UTF-8 locale this raises *"error writing stdout: invalid or incomplete
multibyte"*. Run it with a UTF-8 locale:

```sh
LANG=en_US.UTF-8 DISPLAY=:0 ./tclkit-9.0.3-Linux64-intel-tk tests/test_suite.tcl
```

---

## Getting Started

```tcl
# Load the package
source ttkbootstrap.tcl

# Create a themed window
ttkbootstrap::Window -themename litera -title "My App" -size {800 600}

# Use any widget
ttk::button .btn -text "Click me" -style "primary.TButton"
pack .btn -pady 10
```

All widgets support the `-bootstyle` option for colour variants: `primary`, `secondary`, `success`, `info`, `warning`, `danger`.

---

## Original Widgets

These are feature-rich Tcl/Tk widgets built on top of ttk, located in `widgets/*.tcl`.

### 1. AutocompleteEntry

Entry with live-filtered suggestion dropdown.

```tcl
ttkbootstrap::AutocompleteEntry .ac \
    -values {Apple Banana Cherry Date Elderberry} \
    -bootstyle primary
pack .ac
```

**Options:** `-values` list, `-bootstyle`, `-maxitems` int (default 8)

---

### 2. Badge

Small label for counts or status indicators.

```tcl
ttkbootstrap::Badge .b -text "NEW" -bootstyle danger
pack .b
```

**Options:** `-text`, `-bootstyle`

---

### 3. Breadcrumb

Navigation path with clickable items and separators.

```tcl
ttkbootstrap::Breadcrumb .bc \
    -items {Home Settings Users} \
    -bootstyle primary \
    -command {puts "Clicked item $idx"}
pack .bc
```

**Options:** `-items` list, `-bootstyle`, `-command`
**Subcommands:** `Breadcrumb::load $w $items`, `Breadcrumb::get $w`

---

### 4. Card

Content card with title bar, body, and footer sections.

```tcl
set c [ttkbootstrap::Card .c -title "Summary" -bootstyle primary -padding 10]
set body [ttkbootstrap::Card::body $c]
ttk::label $body.l -text "Card content here"
pack $body.l
pack $c
```

**Options:** `-title`, `-bootstyle`, `-padding`
**Subcommands:** `Card::body $w`, `Card::footer $w`

---

### 5. CollapsingFrame

Accordion-style collapsible sections.

```tcl
set cf [ttkbootstrap::CollapsingFrame .cf]
# Create the section's body frame as a child of the CollapsingFrame,
# fill it with content, then register it with a title.
set body [ttk::frame $cf.s1]
ttk::label $body.l -text "Content 1"
pack $body.l
ttkbootstrap::CollapsingFrame::add $cf $body "Section 1"
pack $cf
```

**Subcommands:** `CollapsingFrame::add $w $child $title ?bootstyle?` — `$child`
is a frame you create under `$w` and fill with content; `$title` is the header
label. Returns nothing.

---

### 6. DateEntry

Entry with calendar popup for date selection.

```tcl
ttkbootstrap::DateEntry .de \
    -bootstyle primary \
    -dateformat "%Y-%m-%d" \
    -textvariable ::mydate
pack .de
```

**Options:** `-bootstyle`, `-dateformat`, `-textvariable`, `-firstweekday` (0=Sun), `-command`

---

### 7. DateRangePicker

Two linked calendars for selecting a date range.

```tcl
ttkbootstrap::DateRangePicker .drp -bootstyle primary
pack .drp
```

**Options:** `-bootstyle`, `-dateformat`, `-command`

---

### 8. EditableTableview

Tableview with double-click in-place cell editing.

```tcl
set tv [ttkbootstrap::EditableTableview .tv \
    -coldata {
        {text "Name" stretch 1}
        {text "Email" stretch 1}
    } \
    -rowdata {
        {Alice alice@example.com}
        {Bob   bob@example.com}
    } \
    -bootstyle primary \
    -editcolumns {0 1}]
pack $tv -fill both -expand 1
```

**Options:** inherits all Tableview options plus `-editcolumns` list
**Subcommands:** `EditableTableview::getdata $w`, `EditableTableview::getcell $w $row $col`, `EditableTableview::setcell $w $row $col $val`

---

### 9. Floodgauge

Progress bar with text overlay showing percentage.

```tcl
ttkbootstrap::Floodgauge .fg \
    -bootstyle primary \
    -variable ::progress \
    -text "Loading..."
pack .fg
set ::progress 65
```

**Options:** `-bootstyle`, `-variable`, `-text`, `-mask` (format string), `-width`, `-height`

---

### 10. Meter

Circular gauge displaying a value within a range.

```tcl
ttkbootstrap::Meter .m \
    -bootstyle primary \
    -amountused 75 \
    -amounttotal 100 \
    -subtext "CPU"
pack .m
```

**Options:** `-bootstyle`, `-amountused`, `-amounttotal`, `-metersize`, `-meterthickness`, `-subtext`, `-showvalue`, `-textright`

---

### 11. NotificationBanner

Slide-in notification banner.

```tcl
ttkbootstrap::NotificationBanner::show \
    -title "Success" -message "File saved." \
    -bootstyle success -duration 3000
```

**Options:** `-title`, `-message`, `-bootstyle`, `-duration` (ms)

---

### 12. ProgressDialog

Modal dialog with progress bar.

```tcl
ttkbootstrap::ProgressDialog::show \
    -title "Processing" -maximum 100
# Update: ttkbootstrap::ProgressDialog::update 50
# Close: ttkbootstrap::ProgressDialog::close
```

---

### 13. RatingBar

Clickable star rating widget.

```tcl
ttkbootstrap::RatingBar .rb \
    -variable ::rating \
    -maximum 5 \
    -bootstyle warning
pack .rb
```

**Options:** `-variable`, `-maximum`, `-bootstyle`, `-readonly`

---

### 14. ScrolledFrame

Frame with automatic scrollbars.

```tcl
set sf [ttkbootstrap::ScrolledFrame .sf -autohide 1]
pack $sf -fill both -expand 1
# Pack children into the interior
set interior [$sf.interior]
```

**Options:** `-autohide`, `-bootstyle`, `-padding`

---

### 15. Sidebar

Navigation sidebar with selectable items.

```tcl
set sb [ttkbootstrap::Sidebar .sb -bootstyle primary]
ttkbootstrap::Sidebar::add $sb home "Home" -icon "🏠" -command {show_home}
ttkbootstrap::Sidebar::add $sb settings "Settings" -icon "⚙"
ttkbootstrap::Sidebar::select $sb home
pack $sb -fill y -side left
```

**Options:** `-bootstyle`, `-width`
**Subcommands:** `Sidebar::add $w $key $label ?-icon? ?-command?`, `Sidebar::select $w $key`

---

### 16. SparkLine

Mini inline chart (line or bar).

```tcl
ttkbootstrap::SparkLine .sl \
    -data {10 25 15 30 20 35} \
    -bootstyle primary \
    -type line
pack .sl
```

**Options:** `-data`, `-bootstyle`, `-type` (line|bar), `-width`, `-height`

---

### 17. SplashScreen

Application splash screen with progress.

```tcl
ttkbootstrap::SplashScreen::show -title "MyApp" -message "Loading..."
# ttkbootstrap::SplashScreen::close
```

---

### 18. StatusBar

Bottom status bar with message display.

```tcl
set sb [ttkbootstrap::StatusBar .sb -bootstyle primary]
pack $sb -fill x -side bottom
ttkbootstrap::StatusBar::msg $sb "Ready" -clear 3000
```

**Options:** `-bootstyle`
**Subcommands:** `StatusBar::msg $w $text ?-clear ms?`

---

### 19. StepProgress

Horizontal step indicator (wizard-style).

```tcl
set sp [ttkbootstrap::StepProgress .sp \
    -steps {Account Profile Payment Done} \
    -bootstyle primary \
    -complete success]
pack $sp -fill x
# Navigate: StepProgress::next $sp / StepProgress::prev $sp
```

**Options:** `-steps` list, `-bootstyle`, `-complete` (done colour), `-size`, `-current`, `-command`
**Subcommands:** `StepProgress::next`, `StepProgress::prev`, `StepProgress::goto $w $idx`

---

### 20. Tableview

Feature-rich data table with sorting, filtering, pagination.

```tcl
set tv [ttkbootstrap::Tableview .tv \
    -coldata {
        {text "Name" stretch 1}
        {text "Status" stretch 0 width 100}
    } \
    -rowdata {
        {Alice Active}
        {Bob   Inactive}
    } \
    -bootstyle primary \
    -searchable 1 \
    -stripecolor [ttkbootstrap::getColor light]]
pack $tv -fill both -expand 1
```

**Options:** `-coldata`, `-rowdata`, `-bootstyle`, `-searchable`, `-stripecolor`, `-pagesize`, `-height`, `-selectmode`

---

### 21. TagEntry

Entry that converts text into removable pill tags.

```tcl
ttkbootstrap::TagEntry .te \
    -tags {Python Tcl Go} \
    -bootstyle primary \
    -command {puts "Tags changed"}
pack .te -fill x
```

**Options:** `-tags` list, `-bootstyle`, `-command`, `-maxitems`
**Subcommands:** `TagEntry::_dispatch $w get`, `TagEntry::_dispatch $w add $tag`, `TagEntry::_dispatch $w remove $tag`, `TagEntry::_dispatch $w clear`

---

### 22. Timeline

Vertical timeline with dots, connectors, and content.

```tcl
set tl [ttkbootstrap::Timeline .tl -bootstyle primary]
ttkbootstrap::Timeline::add $tl \
    -title "Deployed" -timestamp "14:32" \
    -body "All services running." -bootstyle success -icon "✓"
pack $tl
```

**Options:** `-bootstyle`
**Subcommands:** `Timeline::add $w -title -timestamp -body -bootstyle -icon`

---

### 23. TimePicker

Entry with clock popup for time selection.

```tcl
ttkbootstrap::TimePicker .tp \
    -bootstyle primary \
    -textvariable ::mytime \
    -timeformat "%H:%M"
pack .tp
```

**Options:** `-bootstyle`, `-textvariable`, `-timeformat`, `-seconds` (show seconds), `-ampm`

---

### 24. Toast

Temporary notification popup.

```tcl
ttkbootstrap::Toast::show -title "Info" -message "Task complete" \
    -bootstyle info -duration 2000
```

---

### 25. ToggleSwitch

On/off toggle switch.

```tcl
ttkbootstrap::ToggleSwitch .ts \
    -variable ::enabled \
    -bootstyle success \
    -text "Enable feature"
pack .ts
```

**Options:** `-variable`, `-bootstyle`, `-text`, `-shape` (round|square)

---

### 26. Tooltip

Hover tooltip for any widget.

```tcl
ttkbootstrap::Tooltip .mybutton "Click to submit" -bootstyle dark
```

**Options:** `-bootstyle`, `-delay` (ms), `-wraplength`

---

### 27. Window

Configure the root window with theme and title.

```tcl
ttkbootstrap::Window \
    -themename litera \
    -title "My Application" \
    -size {800 600}
```

**Options:** `-themename`, `-title`, `-size` {w h}, `-icon`

---

## SVG Widgets

SVG-rendered widgets using Tk 9's native SVG support. Crisp at any DPI, auto-scaling, theme-aware.

### 1. SVGButton

Rounded-rectangle button with customisable radius.

```tcl
ttkbootstrap::SVGButton .btn \
    -text "Click Me" -bootstyle primary \
    -radius 6 -outline 0 \
    -command {puts "Clicked!"}
pack .btn
```

**Options:** `-text`, `-bootstyle`, `-radius` (0=square, default=rounded, 6=rounded), `-outline` (0|1), `-command`, `-width`, `-height`

---

### 2. PillButton

Fully rounded (pill-shaped) button — wrapper around SVGButton.

```tcl
ttkbootstrap::PillButton .pill \
    -text "Submit" -bootstyle success \
    -outline 1 \
    -command {puts "Submitted"}
pack .pill
```

**Options:** same as SVGButton (radius auto-set to height/2)

---

### 3. SVGCheck

Checkbox with SVG rounded-rect and polyline checkmark.

```tcl
ttkbootstrap::SVGCheck .ck \
    -text "Accept terms" \
    -variable ::accepted \
    -bootstyle primary
pack .ck
```

**Options:** `-text`, `-variable`, `-bootstyle`, `-command`

---

### 4. SVGRadio

Radio button with SVG circles.

```tcl
ttkbootstrap::SVGRadio .r1 -text "Option A" -variable ::choice -value a -bootstyle primary
ttkbootstrap::SVGRadio .r2 -text "Option B" -variable ::choice -value b -bootstyle primary
pack .r1 .r2
```

**Options:** `-text`, `-variable`, `-value`, `-bootstyle`, `-command`

---

### 5. SVGEntry

Entry field with SVG pill-shaped border and focus highlight.

```tcl
ttkbootstrap::SVGEntry .ent \
    -bootstyle primary \
    -textvariable ::name \
    -width 20
pack .ent
```

**Options:** `-bootstyle`, `-textvariable`, `-width` (chars), `-height`, `-radius`, `-state`, `-placeholder`

---

### 6. SVGProgress

Rounded progress bar with clipped fill.

```tcl
ttkbootstrap::SVGProgress .pb \
    -bootstyle success -value 65 \
    -maximum 100 -length 300
pack .pb
```

**Options:** `-bootstyle`, `-value`, `-maximum`, `-length`, `-height`, `-radius`, `-variable`, `-offset` (for indeterminate)
**Subcommands:** `SVGProgress_set $w $value`

---

### 7. SVGScale

Canvas slider with SVG circle thumb and rounded track.

```tcl
ttkbootstrap::SVGScale .sc \
    -from 0 -to 100 \
    -variable ::vol \
    -bootstyle primary \
    -command {puts "Value: $::vol"}
pack .sc
```

**Options:** `-from`, `-to`, `-variable`, `-bootstyle`, `-command`, `-length`, `-height`

---

### 8. SVGMeter

Circular gauge with SVG arc ring.

```tcl
ttkbootstrap::SVGMeter .m \
    -bootstyle primary \
    -amountused 75 -amounttotal 100 \
    -subtext "CPU"
pack .m
```

**Options:** `-bootstyle`, `-amountused`, `-amounttotal`, `-metersize`, `-meterthickness`, `-subtext`, `-showvalue`, `-textright`

---

### 9. SVGFloodgauge

Progress bar with text overlay.

```tcl
ttkbootstrap::SVGFloodgauge .fg \
    -bootstyle primary -value 45 -maximum 100 \
    -text "Uploading..."
pack .fg
```

**Options:** `-bootstyle`, `-value`, `-maximum`, `-text`, `-mask`, `-width`, `-height`, `-radius`, `-variable`
**Subcommands:** `SVGFloodgauge_set $w $value`

---

### 10. SVGBadge

Pill-shaped badge with SVG background.

```tcl
ttkbootstrap::SVGBadge .b -text "99+" -bootstyle danger
pack .b
```

**Options:** `-text`, `-bootstyle`
**Subcommands:** `SVGBadge_set $w $text`

---

### 11. SVGRatingBar

Clickable 5-point star rating with SVG stars.

```tcl
ttkbootstrap::SVGRatingBar .rb \
    -variable ::rating -maximum 5 \
    -bootstyle warning \
    -readonly 0
pack .rb
```

**Options:** `-variable`, `-maximum`, `-bootstyle`, `-readonly`, `-size`

---

### 12. SVGSparkLine

Mini chart (line or bar) with streaming data support.

```tcl
set sl [ttkbootstrap::SVGSparkLine .sl \
    -data {10 25 15 30 20} \
    -bootstyle primary -type line]
pack $sl

# Push new data point:
ttkbootstrap::SVGSparkLine_push .sl 42
```

**Options:** `-data`, `-bootstyle`, `-type` (line|bar), `-width`, `-height`
**Subcommands:** `SVGSparkLine_push $w $value`, `SVGSparkLine_set $w $datalist`

---

### 13. SVGStepProgress

Step indicator with SVG circles and canvas text.

```tcl
set sp [ttkbootstrap::SVGStepProgress .sp \
    -steps {Account Profile Payment Done} \
    -bootstyle primary -complete success]
pack $sp -fill x

# Navigate:
ttkbootstrap::SVGStepProgress::next $sp
ttkbootstrap::SVGStepProgress::prev $sp
ttkbootstrap::SVGStepProgress::goto $sp 2
```

**Options:** `-steps`, `-bootstyle`, `-complete`, `-size`, `-current`, `-command`
**Subcommands:** `SVGStepProgress::next`, `SVGStepProgress::prev`, `SVGStepProgress::goto $w $idx`, `SVGStepProgress::current $w`

---

### 14. SVGScrollbar

Canvas-based scrollbar with SVG pill-shaped thumb.

```tcl
ttkbootstrap::SVGScrollbar .sb -orient vertical -bootstyle primary \
    -command {.text yview}
.text configure -yscrollcommand {ttkbootstrap::SVGScrollbar_set .sb}
pack .sb -side right -fill y
```

**Options:** `-orient` (vertical|horizontal), `-bootstyle`, `-command`, `-width`
**Subcommands:** `SVGScrollbar_set $w $first $last`

---

### 15. SVGTimeline

Vertical timeline with SVG dots (circle/square), connectors, and content.

```tcl
set tl [ttkbootstrap::SVGTimeline .tl]
ttkbootstrap::SVGTimeline::add $tl \
    -title "Deployed v2.1" -timestamp "14:32" \
    -body "All services updated." \
    -bootstyle success -icon "✓" -shape circle
ttkbootstrap::SVGTimeline::add $tl \
    -title "Code review" -timestamp "10:15" \
    -bootstyle primary -icon "✔" -shape square
pack $tl
```

**Options:** `-bootstyle`
**Subcommands:** `SVGTimeline::add $w -title -timestamp -body -bootstyle -icon -shape`
**Shapes:** `circle` (default), `square`

---

### 16. SVGBreadcrumb

Breadcrumb navigation with SVG chevron separators.

```tcl
ttkbootstrap::SVGBreadcrumb .bc \
    -items {Home Documents Reports} \
    -bootstyle primary \
    -command {puts "Clicked item $::idx"}
pack .bc
```

**Options:** `-items`, `-bootstyle`, `-command`
**Subcommands:** `SVGBreadcrumb::load $w $items`, `SVGBreadcrumb::get $w`

---

### 17. SVGCard

Card container with SVG rounded border and coloured title bar.

```tcl
set c [ttkbootstrap::SVGCard .c \
    -title "Summary" -bootstyle primary \
    -width 200 -height 150]
set body [ttkbootstrap::SVGCard::body $c]
ttk::label $body.l -text "Content here"
pack $body.l
pack $c
```

**Options:** `-title`, `-bootstyle`, `-padding`, `-width`, `-height`
**Subcommands:** `SVGCard::body $w`

---

### 18. SVGShadowCard

Card with layered SVG drop shadow for a raised effect.

```tcl
set c [ttkbootstrap::SVGShadowCard .c \
    -title "Dashboard" -bootstyle primary \
    -shadow 10 -width 220 -height 160]
set body [ttkbootstrap::SVGShadowCard::body $c]
ttk::label $body.l -text "Active users: 1,247"
pack $body.l
pack $c
```

**Options:** `-title`, `-bootstyle`, `-padding`, `-width`, `-height`, `-shadow` (number of layers, default 10)
**Subcommands:** `SVGShadowCard::body $w`

---

### 19. SVGTooltip

Hover tooltip with SVG rounded background.

```tcl
ttkbootstrap::SVGTooltip .mybutton "Click to submit" \
    -bootstyle dark -delay 400
```

**Options:** `-bootstyle`, `-delay` (ms, default 500), `-wraplength`

---

### 20. SVGDateEntry

Entry with SVG calendar icon and calendar popup with SVG day highlights.

```tcl
ttkbootstrap::SVGDateEntry .de \
    -bootstyle primary \
    -dateformat "%Y-%m-%d" \
    -textvariable ::mydate
pack .de
```

**Options:** `-bootstyle`, `-dateformat`, `-textvariable`, `-firstweekday`

---

### 21. SVGTimePicker

Entry with SVG clock icon and hour/minute popup.

```tcl
ttkbootstrap::SVGTimePicker .tp \
    -bootstyle primary \
    -textvariable ::mytime \
    -timeformat "%H:%M"
pack .tp
```

**Options:** `-bootstyle`, `-textvariable`, `-timeformat`

---

### 22. SVGSidebar

Navigation sidebar with active/hover highlighting.

```tcl
set sb [ttkbootstrap::SVGSidebar .sb -bootstyle primary -width 200]
ttkbootstrap::SVGSidebar::add $sb home "Home" -icon "🏠" -command {show_home}
ttkbootstrap::SVGSidebar::add $sb settings "Settings" -icon "⚙"
ttkbootstrap::SVGSidebar::select $sb home
pack $sb -fill y -side left
```

**Options:** `-bootstyle`, `-width`
**Subcommands:** `SVGSidebar::add $w $key $label ?-icon? ?-command?`, `SVGSidebar::select $w $key`

---



---

### 23. SVGToggleSwitch

Animated toggle switch with SVG track and sliding thumb.

```tcl
set ::darkmode 0
ttkbootstrap::SVGToggleSwitch .ts \
    -text "Dark mode" \
    -variable ::darkmode \
    -bootstyle success \
    -shape round \
    -command {puts "Dark mode: $::darkmode"}
pack .ts

# Square shape
ttkbootstrap::SVGToggleSwitch .ts2 \
    -text "Notifications" \
    -variable ::notify \
    -bootstyle primary \
    -shape square
pack .ts2
```

**Options:** `-text`, `-variable`, `-bootstyle`, `-command`, `-shape` (round|square)

> **Note:** `SVGToggleSwitch` is a *frame*-based composite widget, not a
> `ttk` button, so it does **not** respond to `$w invoke`. To change its
> state programmatically, set its `-variable` (the switch redraws and the
> `-command` fires automatically); to read its state, query that same
> variable. The user toggles it by clicking the switch.
>
> ```tcl
> set ::wifi 0
> ttkbootstrap::SVGToggleSwitch .sw -variable ::wifi -bootstyle success \
>     -command {puts "WiFi now: $::wifi"}
> pack .sw
> set ::wifi 1      ;# turns it on programmatically (command fires)
> puts $::wifi      ;# reads current state -> 1
> ```

---

### 24. SVGProgressRing

Circular progress indicator with determinate and indeterminate (spinning) modes.

```tcl
# Determinate ring at 75%
ttkbootstrap::SVGProgressRing .pr \
    -bootstyle primary -value 75 -size 44
pack .pr

# Update value
ttkbootstrap::SVGProgressRing_set .pr 90

# Indeterminate spinner
set spinner [ttkbootstrap::SVGProgressRing .spin \
    -bootstyle info -size 44]
ttkbootstrap::SVGProgressRing_spin $spinner
pack $spinner

# Stop spinning
ttkbootstrap::SVGProgressRing_stop $spinner
```

**Options:** `-bootstyle`, `-value` (0-100), `-size` (pixels), `-thickness`
**Subcommands:** `SVGProgressRing_set $w $value`, `SVGProgressRing_spin $w`, `SVGProgressRing_stop $w`

---

### 25. SVGCombobox

Combobox with SVG pill-shaped border and focus highlight.

```tcl
set ::colour ""
ttkbootstrap::SVGCombobox .cb \
    -values {Red Green Blue Yellow Purple} \
    -bootstyle primary \
    -textvariable ::colour \
    -width 18
pack .cb
```

**Options:** `-values` list, `-bootstyle`, `-textvariable`, `-width`, `-height`, `-radius`

---

### 26. SVGSpinbox

Spinbox with SVG pill-shaped border and focus highlight.

```tcl
ttkbootstrap::SVGSpinbox .sp \
    -from 1 -to 100 \
    -bootstyle primary \
    -width 8 \
    -wrap 1
pack .sp
```

**Options:** `-from`, `-to`, `-bootstyle`, `-textvariable`, `-width`, `-height`, `-radius`, `-wrap`, `-format`

---

### 27. SVGFormField

Form field with label, SVG entry, and live validation message.

```tcl
set ::email ""
ttkbootstrap::SVGFormField .ff \
    -label "Email Address" \
    -bootstyle primary \
    -textvariable ::email \
    -width 30 \
    -validate {regexp {.+@.+\..+} $value} \
    -validmsg "\u2713 Valid email" \
    -invalidmsg "\u2717 Invalid email address"
pack .ff

# Check validity
puts [ttkbootstrap::SVGFormField::isValid .ff]
puts [ttkbootstrap::SVGFormField::getValue .ff]
```

**Options:** `-label`, `-bootstyle`, `-textvariable`, `-width`, `-validate` (script), `-validmsg`, `-invalidmsg`, `-placeholder`
**Subcommands:** `SVGFormField::isValid $w` → 1/0/-1, `SVGFormField::getValue $w` → string

---

### 28. SVGColourPicker

Colour palette with 32 clickable SVG swatches (Material Design colours).

```tcl
set ::mycolour "#2196F3"
ttkbootstrap::SVGColourPicker .cp \
    -variable ::mycolour \
    -bootstyle primary \
    -columns 8
pack .cp
# Clicking a swatch updates ::mycolour
```

**Options:** `-variable`, `-bootstyle`, `-columns` (swatches per row, default 8)

---

### 29. SVGNotificationBanner

Slide-in notification with SVG rounded corners, shadow, and coloured accent bar.

```tcl
ttkbootstrap::SVGNotificationBanner::show \
    -title "Success" \
    -message "File saved successfully." \
    -bootstyle success \
    -duration 3000 \
    -position topright
```

**Options:** `-title`, `-message`, `-bootstyle`, `-duration` (ms, 0=permanent), `-position` (topright|topleft)

---

## SVG Icon Library

32 built-in SVG icons that scale with DPI and support custom colours.

```tcl
# Get an icon image
set img [ttkbootstrap::SVGIcon home -size 24 -colour "#333"]
label .l -image $img
pack .l

# List all available icons
puts [ttkbootstrap::SVGIconNames]
# → bell calendar check chevron_d chevron_l chevron_r chevron_u
#   clock close database download edit error file folder heart
#   home info lock logout mail minus plus refresh save search
#   settings star trash upload user warning
```

**Proc:** `ttkbootstrap::SVGIcon $name ?-size pixels? ?-colour hex?`
**Proc:** `ttkbootstrap::SVGIconNames` → list of all icon names
**Proc:** `ttkbootstrap::SVGIconFlush` → clear the icon cache (call after theme change to regenerate with new colours)

**Icons are cached** — same name/size/colour returns the cached image.

**Background handling:** Icons have transparent backgrounds. Use `ttk::label` (recommended) so the background automatically matches the theme. If using plain `label`, set `-bg` explicitly:

```tcl
# Recommended — background auto-themes
ttk::label .icon -image [ttkbootstrap::SVGIcon home -size 24]

# Manual background control
label .icon2 -image [ttkbootstrap::SVGIcon home -size 24] \
    -bg [ttkbootstrap::getColor bg] -bd 0

# After theme change, flush cache and recreate
ttkbootstrap::SVGIconFlush
set img [ttkbootstrap::SVGIcon home -size 24 \
    -colour [ttkbootstrap::getColor primary]]
```

---

## OS Theme Auto-Detect

Detects the operating system's dark/light preference and applies a matching theme.

```tcl
# Auto-detect and apply (defaults: litera for light, darkly for dark)
set preference [ttkbootstrap::autoTheme]
puts "OS prefers: $preference"

# Specify which themes to use
ttkbootstrap::autoTheme -light cosmo -dark solar

# Just detect without applying
set mode [ttkbootstrap::_detectOSTheme]
# → "light" or "dark"
```

**Supported:** GNOME (gsettings), KDE (kreadconfig5), XFCE (xfconf-query), macOS (defaults), Windows (registry)

---

## Package Loading

```tcl
# Via pkgIndex.tcl
lappend auto_path /path/to/ttkbootstrap-tcl
package require ttkbootstrap

# Or source directly
source /path/to/ttkbootstrap.tcl
```


---

### 30. SVGSearchBar

Pill-shaped search entry with magnifying glass icon and clear button.

```tcl
ttkbootstrap::SVGSearchBar .sb \
    -bootstyle primary -placeholder "Search..." \
    -width 30 -command {puts "Search: $query"}
pack .sb
```

**Options:** `-bootstyle`, `-placeholder`, `-width`, `-command` (receives `$query`), `-textvariable`

---

### 31. SVGAvatar

Circular avatar displaying initials in a coloured circle.

```tcl
ttkbootstrap::SVGAvatar .av -text "JD" -bootstyle primary -size 48
pack .av
```

**Options:** `-text` (initials), `-bootstyle`, `-size` (pixels)

---

### 32. SVGChip

Material Design chip with optional close button.

```tcl
ttkbootstrap::SVGChip .ch -text "Python" -bootstyle primary \
    -closeable 1 -command {puts "Removed"}
pack .ch
```

**Options:** `-text`, `-bootstyle`, `-icon`, `-closeable` (0|1), `-command`

---

### 33. SVGDialog

Modal dialog with coloured title bar and action buttons.

```tcl
set result [ttkbootstrap::SVGDialog::show \
    -title "Confirm" -message "Are you sure?" \
    -bootstyle primary -buttons {Cancel OK} -default OK]
puts "User clicked: $result"
```

**Options:** `-title`, `-message`, `-bootstyle`, `-buttons` list, `-default`
**Returns:** the text of the button that was clicked.

---

### 34. SVGTabNotebook

Tabbed notebook with SVG rounded tab headers.

```tcl
set nb [ttkbootstrap::SVGTabNotebook .nb -bootstyle primary]
ttkbootstrap::SVGTabNotebook::add $nb "Tab 1" \
    -create {ttk::label %f.l -text "Page 1"; pack %f.l}
ttkbootstrap::SVGTabNotebook::add $nb "Tab 2" \
    -create {ttk::label %f.l -text "Page 2"; pack %f.l}
ttkbootstrap::SVGTabNotebook::select $nb 0
pack $nb -fill both -expand 1
```

**Options:** `-bootstyle`
**Subcommands:** `SVGTabNotebook::add $w $title -create $script` (`%f` = page frame), `SVGTabNotebook::select $w $index`


---

### 35. SVGGradientButton

Button with a faked vertical gradient (layered stripes) and hover effect.

```tcl
ttkbootstrap::SVGGradientButton .gb -text "Click Me" \
    -bootstyle primary -command {puts "clicked"}
pack .gb
```

**Options:** `-text`, `-bootstyle`, `-command`, `-radius`, `-width`

---

### 36. SVGSkeleton

Animated shimmer placeholder for loading states.

```tcl
# Text lines variant
set sk [ttkbootstrap::SVGSkeleton .sk -width 300 -lines 3]
pack $sk
ttkbootstrap::SVGSkeleton::start .sk
# When content is ready:
ttkbootstrap::SVGSkeleton::stop .sk

# Card variant (avatar + lines)
ttkbootstrap::SVGSkeleton .sk2 -width 300 -shape card
```

**Options:** `-width`, `-height`, `-lines`, `-shape` (lines|card)
**Subcommands:** `SVGSkeleton::start $w`, `SVGSkeleton::stop $w`

---

### 37. SVGTreeview

Tree with SVG expand/collapse chevrons, hover highlight, and selection.

```tcl
set tv [ttkbootstrap::SVGTreeview .tv -bootstyle primary -height 240]
set root [ttkbootstrap::SVGTreeview::insert $tv "" "Documents" -open 1]
ttkbootstrap::SVGTreeview::insert $tv $root "report.pdf"
set sub [ttkbootstrap::SVGTreeview::insert $tv $root "Images" -open 0]
ttkbootstrap::SVGTreeview::insert $tv $sub "photo.png"
pack $tv -fill both -expand 1

# Get selected node id
set sel [ttkbootstrap::SVGTreeview::selection $tv]
```

**Options:** `-bootstyle`, `-height`
**Subcommands:** `SVGTreeview::insert $w $parent $text ?-open 0|1?` → node id, `SVGTreeview::selection $w` → selected id

---

## Theme Swatch Helper

Returns a small SVG image previewing a theme's colour palette (for theme pickers).

```tcl
set img [ttkbootstrap::themeSwatch darkly -width 120 -height 44]
label .l -image $img
```

**Proc:** `ttkbootstrap::themeSwatch $themeName ?-width pixels? ?-height pixels?`


## API Naming

Widgets expose methods in two equivalent forms. The **canonical** form is `Widget::method`; the **legacy** underscore form (`Widget_method`) remains supported for backward compatibility.

```tcl
# Canonical (preferred)
ttkbootstrap::SVGProgress::set .pb 50
ttkbootstrap::SVGProgressRing::spin .ring
ttkbootstrap::SVGBadge::set .badge "9+"
ttkbootstrap::SVGSparkLine::push .spark 42

# Legacy (still works)
ttkbootstrap::SVGProgress_set .pb 50
ttkbootstrap::SVGProgressRing_spin .ring
```

Affected widgets: SVGProgress, SVGProgressRing, SVGBadge, SVGFloodgauge, SVGScrollbar, SVGSparkLine. Container/composite widgets (SVGCard, SVGDialog, SVGTreeview, SVGTabNotebook, SVGFormField, etc.) already use the `Widget::method` form throughout.


## Platform Support

ttkbootstrap-tcl targets Tcl/Tk 9 on Linux (X11), macOS (Aqua), and Windows (Win32). Most widgets are pure SVG-on-canvas and behave identically everywhere. A few features have platform-specific behaviour:

| Feature | Linux/X11 | macOS/Aqua | Windows |
|---------|-----------|------------|---------|
| OS theme auto-detect (`autoTheme`) | gsettings / xfconf / kreadconfig | `defaults read -g AppleInterfaceStyle` | registry `AppsUseLightTheme` |
| Popup transparency (notifications) | sharp corners (no transparency) | sharp corners | `-transparentcolor` honoured |
| Overlay popups (tooltip, dialog, calendar) | `-topmost` + raise | `-topmost` + raise | `-topmost` + raise |

All platform-specific calls are wrapped in `catch`, so an unsupported feature degrades gracefully rather than erroring. `_detectOSTheme` returns `"light"` as a safe default when detection isn't possible.

**Testing status:** the test suite and showcase are exercised on Linux/X11. The macOS and Windows code paths are written to Tk 9's documented cross-platform API but have not been continuously integration-tested; report any platform-specific issues.

## Core Functions

### Theme Management

```tcl
ttkbootstrap::setTheme darkly           ;# Switch theme
ttkbootstrap::getColor primary           ;# Get colour hex value
ttkbootstrap::getColors                  ;# Get all colours as dict
ttkbootstrap::themeNames                 ;# List all themes
ttkbootstrap::lightThemes                ;# List light themes
ttkbootstrap::darkThemes                 ;# List dark themes
```

### DPI Scaling

```tcl
ttkbootstrap::_sp 10         ;# Scale 10px for current DPI
ttkbootstrap::_sf 12         ;# Scale font size 12 for current DPI
ttkbootstrap::_sp2 8 4       ;# Scale padding {8 4}
ttkbootstrap::_sp4 4 8 4 8   ;# Scale padding {4 8 4 8}
ttkbootstrap::scaleFactor     ;# Get current scale factor (1.0, 2.0, etc.)
```

### Colour Utilities

```tcl
ttkbootstrap::_contrastFg $hex    ;# Black or white for best contrast
ttkbootstrap::_darken $hex 15     ;# Darken colour by 15%
ttkbootstrap::_lighten $hex 15    ;# Lighten colour by 15%
ttkbootstrap::_safeFont $name     ;# Validate font, fallback to TkDefaultFont
ttkbootstrap::_fontPad 10         ;# Compute {hPad vPad} from font metrics
```

---

## Themes

18 built-in themes, all using TkDefaultFont for consistent text positioning.

### Light Themes
`cerculean`, `cosmo`, `flatly`, `journal`, `litera`, `lumen`, `minty`, `morph`, `pulse`, `sandstone`, `simplex`, `united`, `yeti`

### Dark Themes
`cyborg`, `darkly`, `solar`, `superhero`, `vapor`

### Usage
```tcl
ttkbootstrap::setTheme solar     ;# Switch at runtime
```

---

## Auto-Scaling

All widgets automatically scale for HiDPI and large displays:

- **DPI-based**: `tk scaling` detects HiDPI (e.g., 192 DPI → 2× scaling)
- **Screen-size-based**: screens larger than 1920×1080 at 96 DPI scale proportionally
- **Font-metric-based**: widget heights computed from `font metrics -linespace`
- **`_sp`/`_sf`**: all pixel sizes and font sizes pass through DPI-aware scaling functions

Test with Xephyr:
```bash
# Simulate 4K HiDPI
sudo Xephyr :20 -screen 3840x2160 -dpi 192
DISPLAY=:20 ./tclkit gallery/showcase.tcl

# Simulate large screen at standard DPI
sudo Xephyr :20 -screen 3840x2160
DISPLAY=:20 ./tclkit gallery/showcase.tcl
```
