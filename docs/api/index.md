# API Reference

## Core procedures

### ttkbootstrap::Window

Sets up the root window with theme, title, and size.

```tcl
ttkbootstrap::Window ?options?

Options:
  -themename  name    Theme to apply (default: litera)
  -title      string  Window title
  -size       {w h}   Window size as {width height}
  -minsize    {w h}   Minimum window size
  -resizable  {x y}   Resizable flags (default: {1 1})
  -alpha      float   Window transparency 0.0-1.0
```

### ttkbootstrap::setTheme

Switch to a different theme at runtime.

```tcl
ttkbootstrap::setTheme name
```

### ttkbootstrap::currentTheme

Returns the name of the active theme.

```tcl
set theme [ttkbootstrap::currentTheme]
```

### ttkbootstrap::themeNames

Returns a list of all available theme names.

```tcl
set names [ttkbootstrap::themeNames]
```

### ttkbootstrap::bootstyle

Converts keyword arguments into a ttk style string.

```tcl
ttkbootstrap::bootstyle ?color? ?type? widget_class

# Examples
ttkbootstrap::bootstyle success TButton           ;# -> success.TButton
ttkbootstrap::bootstyle info outline TButton      ;# -> info.Outline.TButton
ttkbootstrap::bootstyle primary round TCheckbutton ;# -> primary.Round.TCheckbutton
ttkbootstrap::bootstyle striped TProgressbar      ;# -> Striped.Horizontal.TProgressbar
```

### ttkbootstrap::getColor

Returns the hex color value for a named theme color.

```tcl
ttkbootstrap::getColor name

# Color names: primary secondary success info warning danger light dark
#              bg fg inputbg inputfg selectbg selectfg border
set hex [ttkbootstrap::getColor primary]
```

## Widget constructors

### ttkbootstrap::Meter

```tcl
ttkbootstrap::Meter path ?options?

Options:
  -metersize    int      Diameter in pixels (default: 200)
  -amountused   int      Current value (default: 0)
  -amounttotal  int      Maximum value (default: 100)
  -subtext      string   Label below the number
  -bootstyle    color    Color keyword
  -interactive  bool     Allow mouse interaction (default: 0)
  -metertype    type     "full" or "semi" (default: full)
  -stripethickness int   Stripe width for dashed style (default: 0)
```

### ttkbootstrap::DateEntry

```tcl
ttkbootstrap::DateEntry path ?options?

Options:
  -bootstyle    color    Color keyword
  -startdate    date     Earliest selectable date (YYYY-MM-DD)
  -enddate      date     Latest selectable date (YYYY-MM-DD)
  -firstweekday int      0=Monday ... 6=Sunday (default: 6)
```

### ttkbootstrap::Floodgauge

```tcl
ttkbootstrap::Floodgauge path ?options?

Options:
  -bootstyle    color    Color keyword
  -value        int      Current value 0-100
  -text         string   Label text on the gauge
  -orient       h|v      horizontal or vertical (default: horizontal)
```

### ttkbootstrap::toast

```tcl
ttkbootstrap::toast message ?bootstyle? ?duration?

# message   - Text to display
# bootstyle - Color keyword (default: primary)
# duration  - Milliseconds to show (default: 3000)

ttkbootstrap::toast "Saved!" success 2000
ttkbootstrap::toast "Error occurred" danger 5000
```

### ttkbootstrap::ToolTip

```tcl
ttkbootstrap::ToolTip widget ?options?

Options:
  -text       string   Tooltip text
  -bootstyle  color    Color keyword
  -delay      int      Delay before showing in ms (default: 500)
```

## Scaling utilities

These procedures are used internally by ttkbootstrap and are available for use
in your own application code when you need to place pixel values that should
adapt to the display DPI.

### ttkbootstrap::scaleFactor

Returns the current DPI scale factor as a float. The value is 1.0 at the
96 dpi baseline, 2.0 at 192 dpi, and so on.

```tcl
set sf [ttkbootstrap::scaleFactor]   ;# e.g. 1.0, 1.5, 2.0
```

### ttkbootstrap::_updateScale

Re-reads `tk scaling` and updates the internal scale factor. Called
automatically by `setTheme` and `Window`. Call manually if your application
changes `tk scaling` at runtime.

```tcl
tk scaling 2.6678
ttkbootstrap::_updateScale
```

### ttkbootstrap::_sp

Scale a pixel value to the current DPI. Returns an integer.

```tcl
ttkbootstrap::_sp 10    ;# 10 at 1×,  20 at 2×,  30 at 3×
ttkbootstrap::_sp 200   ;# 200 at 1×, 400 at 2×, 600 at 3×
```

Use this for canvas dimensions, explicit widget `-width`/`-height`, and any
`pack`/`grid` geometry values that are in pixels rather than characters.

> Do **not** use `_sp` for font sizes passed to a canvas `create text` item.
> Canvas point sizes are already scaled by Tk via `tk scaling`. Use plain
> point sizes on canvas items.

### ttkbootstrap::_sf

Scale a font point size to the current DPI. Returns an integer (minimum 6).

```tcl
ttkbootstrap::_sf 10    ;# 10 at 1×,  20 at 2×,  30 at 3×
ttkbootstrap::_sf 8     ;# 8 at 1×,   16 at 2×,  24 at 3×
```

Use this for explicit `-font` options on **classic Tk widgets** (label, text,
listbox, entry) and **ttk widgets where `-font` is set directly on the widget**
(not through a style). Do **not** use it for `canvas create text` items.

```tcl
# Correct uses of _sf:
label .lbl -font [list Helvetica [ttkbootstrap::_sf 10]]
text  .txt -font [list Helvetica [ttkbootstrap::_sf 10]]
ttk::label .tl -font [list Helvetica [ttkbootstrap::_sf 14] bold]

# Wrong — double-scales on a canvas:
$c create text 50 50 -font [list Helvetica [ttkbootstrap::_sf 12]]

# Correct on a canvas — plain point size, Tk scales it:
$c create text 50 50 -font {Helvetica 12}
```

### ttkbootstrap::_sp2

Scale a two-value padding list `{x y}`. Returns a list of two integers.

```tcl
ttkbootstrap::_sp2 10 5    ;# {10 5} at 1×, {20 10} at 2×
```

### ttkbootstrap::_sp4

Scale a four-value padding list `{left top right bottom}`. Returns a list of
four integers.

```tcl
ttkbootstrap::_sp4 10 5 10 5   ;# {10 5 10 5} at 1×, {20 10 20 10} at 2×
```


## Color utilities

```tcl
# Get complementary foreground for a background color
ttkbootstrap::_contrastFg hexcolor  ;# returns #000000 or #ffffff

# HSV color manipulation
ttkbootstrap::update_hsv hexcolor -hue dh -sat ds -val dv

# Check if color is dark
ttkbootstrap::isDark hexcolor  ;# returns 1 if dark
```

---

## New widgets (1.4.3)

### ttkbootstrap::CollapsingFrame

A vertical stack of titled, collapsible accordion sections. Each section has
a coloured header bar; clicking the header or the arrow button shows or hides
the child frame below it.

```tcl
ttkbootstrap::CollapsingFrame path ?-bootstyle color?

# Create the accordion container
set cf [ttkbootstrap::CollapsingFrame .cf -bootstyle primary]
pack $cf -fill both -expand 1

# Add a collapsible section
set pane [ttk::frame $cf.pane -padding 10]
# ... populate $pane ...
ttkbootstrap::CollapsingFrame::add $cf $pane "Section title" primary

# Open/close programmatically
ttkbootstrap::CollapsingFrame::open   $cf $pane
ttkbootstrap::CollapsingFrame::close  $cf $pane
ttkbootstrap::CollapsingFrame::toggle $cf $pane
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-bootstyle` | `primary` | Default colour for sections added without an explicit colour |

**CollapsingFrame::add** `cf child title ?bootstyle?`

Add a collapsible section. `child` must be a frame that is a descendant of
`cf`. `title` is the text shown in the header. `bootstyle` overrides the
container default for this section.

**CollapsingFrame::toggle / open / close** `cf child`

Show or hide the section. `open` always shows; `close` always hides;
`toggle` flips the current state.

---

### ttkbootstrap::ToggleSwitch

An iOS-style sliding on/off toggle. Uses the `Round.TCheckbutton` image style
so it renders a pill-shaped indicator that slides between states.

```tcl
ttkbootstrap::ToggleSwitch path ?options?

set myvar 0
ttkbootstrap::ToggleSwitch .ts \
    -text      "Enable notifications" \
    -variable  myvar \
    -bootstyle success \
    -command   { puts "toggled: $myvar" }
pack .ts
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-text` | `{}` | Label shown to the right of the toggle |
| `-variable` | (internal) | Global variable to link (0=off, 1=on) |
| `-onvalue` | `1` | Value written when on |
| `-offvalue` | `0` | Value written when off |
| `-bootstyle` | `primary` | Colour of the toggle when on |
| `-command` | `{}` | Script called on every state change |
| `-state` | `normal` | `normal` or `disabled` |

**Methods** — invoke as `$w method ?args?`

| Method | Description |
|--------|-------------|
| `get` | Returns the current value |
| `set value` | Sets value and fires `-command` |
| `toggle` | Flips state |
| `configure ?opts?` | Change options after creation |
| `cget option` | Read an option |

---

### ttkbootstrap::StatusBar

A thin strip docked to the bottom of a window. It has a left status-text
zone, an optional progress bar (shown on demand), and up to three right-hand
label slots plus an optional sizegrip.

```tcl
set sb [ttkbootstrap::StatusBar . ?options?]

# Returns the bar frame path.  Use StatusBar:: commands to update it.
ttkbootstrap::StatusBar::msg      $sb "Ready"
ttkbootstrap::StatusBar::msg      $sb "Copying..." -progress 40
ttkbootstrap::StatusBar::msg      $sb "Done"       -progress 100 -clear 3000
ttkbootstrap::StatusBar::right    $sb "42 items"        ;# right slot 0
ttkbootstrap::StatusBar::right    $sb "Line 12" 1       ;# right slot 1
ttkbootstrap::StatusBar::progress $sb 75
ttkbootstrap::StatusBar::clear    $sb
```

**Constructor options**

| Option | Default | Description |
|--------|---------|-------------|
| `-bootstyle` | `secondary` | Progress bar colour |
| `-sizegrip` | `1` | Show a sizegrip in the bottom-right corner |

**StatusBar::msg** `sb message ?options?`

Set the left status message. Options:

| Option | Description |
|--------|-------------|
| `-progress int` | Show progress bar at this value (0-100) |
| `-bootstyle color` | Override progress bar colour for this update |
| `-clear ms` | Auto-clear after this many milliseconds |

**StatusBar::right** `sb text ?index?`

Set a right-hand label. `index` is 0, 1, or 2 (default 0).

**StatusBar::progress** `sb value`

Update the progress bar value (0-100). Shows the bar if hidden.

**StatusBar::clear** `sb`

Clear the message and hide the progress bar.

---

### ttkbootstrap::AutocompleteEntry

An entry widget with a live-filtered suggestion dropdown. As the user types,
suggestions matching the current text appear in a positioned popup; selecting
one completes the entry.

```tcl
ttkbootstrap::AutocompleteEntry path ?options?

# Static value list
ttkbootstrap::AutocompleteEntry .ac \
    -values      {Apple Banana Cherry Mango Peach} \
    -bootstyle   primary \
    -command     { puts "selected: [.ac get]" }
pack .ac -fill x

# Dynamic lookup via callback
ttkbootstrap::AutocompleteEntry .dyn \
    -valuescmd   { db_lookup [.dyn get] } \
    -maxitems    10
pack .dyn -fill x
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-values` | `{}` | Static list of suggestion strings |
| `-valuescmd` | `{}` | Script called with current text; must return a list |
| `-textvariable` | (internal) | Variable linked to the entry text |
| `-bootstyle` | `primary` | Entry and dropdown highlight colour |
| `-completevalue` | `1` | If 1, Tab/Return selects the first match |
| `-maxitems` | `8` | Maximum rows shown in the dropdown |
| `-command` | `{}` | Called when the user selects a value |
| `-width` | `20` | Entry width in characters |
| `-state` | `normal` | `normal`, `disabled`, or `readonly` |

**Keyboard navigation**

| Key | Action |
|-----|--------|
| Type | Filters suggestions |
| Down | Move focus into the dropdown |
| Return / Tab | Select first match (if `-completevalue 1`) |
| Escape | Close dropdown |

---

### ttkbootstrap::ProgressDialog

A themed modal dialog with a title, message, progress bar, and an optional
Cancel button. The caller drives progress via the returned dialog path.

```tcl
# Determinate progress
set pd [ttkbootstrap::ProgressDialog . \
    -title   "Copying files" \
    -message "Please wait..." \
    -maximum 100]

for {set i 0} {$i <= 100} {incr i 5} {
    ttkbootstrap::ProgressDialog::update $pd $i "Copied $i of 100 files"
    update
    after 50
}
ttkbootstrap::ProgressDialog::close $pd

# Indeterminate (spinner)
set pd [ttkbootstrap::ProgressDialog . \
    -title "Connecting..." \
    -mode  indeterminate]
ttkbootstrap::ProgressDialog::start $pd
# ... do work ...
ttkbootstrap::ProgressDialog::close $pd

# With cancel button
set cancelled 0
set pd [ttkbootstrap::ProgressDialog . \
    -title     "Processing" \
    -cancelvar cancelled]
# Poll $cancelled in your work loop
```

**Constructor options**

| Option | Default | Description |
|--------|---------|-------------|
| `-title` | `"Progress"` | Dialog window title |
| `-message` | `{}` | Initial message shown above the bar |
| `-maximum` | `100` | Maximum progress value |
| `-mode` | `determinate` | `determinate` or `indeterminate` |
| `-bootstyle` | `primary` | Progress bar colour |
| `-cancelvar` | `{}` | Variable name; set to 1 when Cancel clicked |
| `-width` | (scaled 360) | Dialog width in pixels |

**Commands**

| Command | Description |
|---------|-------------|
| `ProgressDialog::update pd value ?message?` | Set value and optional message |
| `ProgressDialog::message pd text` | Update message label only |
| `ProgressDialog::start pd` | Start indeterminate animation |
| `ProgressDialog::stop pd` | Stop indeterminate animation |
| `ProgressDialog::close pd` | Release grab and destroy the dialog |

---

### ttkbootstrap::TagEntry

An entry widget that converts typed text into removable pill-shaped tags.
Press comma (or the configured separator), Return, or Tab to create a tag.
Press Backspace on an empty entry to remove the last tag.

```tcl
ttkbootstrap::TagEntry path ?options?

ttkbootstrap::TagEntry .te \
    -bootstyle primary \
    -tags      {Python Tcl} \
    -command   { puts "tags: [.te get]" }
pack .te -fill x

# Programmatic control
ttkbootstrap::TagEntry::_dispatch .te add "Go"
ttkbootstrap::TagEntry::_dispatch .te remove "Tcl"
ttkbootstrap::TagEntry::_dispatch .te clear
set tags [ttkbootstrap::TagEntry::_dispatch .te get]
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-tags` | `{}` | Initial tag list |
| `-bootstyle` | `primary` | Pill colour |
| `-separator` | `,` | Characters that trigger tag creation |
| `-maxitems` | `0` | Maximum tags (0 = unlimited) |
| `-command` | `{}` | Called with current tag list on every change |
| `-width` | `30` | Approximate widget width in characters |

**Commands** (via `ttkbootstrap::TagEntry::_dispatch widget cmd ?args?`)

| Command | Description |
|---------|-------------|
| `get` | Returns list of current tags |
| `add tag` | Add a tag programmatically |
| `remove tag` | Remove a tag |
| `clear` | Remove all tags |
| `configure opts` | Change `-bootstyle` or `-command` |

---

### ttkbootstrap::NotificationBanner

A persistent coloured strip that docks inside the application layout and
stays until dismissed. Unlike `Toast`, it does not disappear automatically.

```tcl
ttkbootstrap::NotificationBanner parent ?options?

set nb [ttkbootstrap::NotificationBanner . \
    -message   "Your session will expire in 10 minutes." \
    -bootstyle warning \
    -position  top \
    -dismiss   1 \
    -command   { puts "dismissed" }]

# Update or control later
ttkbootstrap::NotificationBanner::msg    $nb "5 minutes remaining."
ttkbootstrap::NotificationBanner::hide   $nb
ttkbootstrap::NotificationBanner::show   $nb
ttkbootstrap::NotificationBanner::restyle $nb danger
```

**Constructor options**

| Option | Default | Description |
|--------|---------|-------------|
| `-message` | `{}` | Banner text |
| `-bootstyle` | `info` | Banner colour |
| `-position` | `top` | `top` or `bottom` |
| `-dismiss` | `1` | Show a × dismiss button |
| `-command` | `{}` | Called when banner is dismissed |

**Commands**

| Command | Description |
|---------|-------------|
| `NotificationBanner::msg nb text` | Update message text |
| `NotificationBanner::show nb` | Make the banner visible |
| `NotificationBanner::hide nb` | Hide (does not destroy) |
| `NotificationBanner::restyle nb ?bootstyle?` | Re-apply colours |

> **Note:** `NotificationBanner::msg` is the update command. The name `set`
> is avoided because it would shadow Tcl's built-in `set` command inside
> the namespace.

---

## New widgets (1.4.4)

> **API naming note:** Several widget namespaces define a public `set`-like command.
> To avoid shadowing Tcl's built-in `set` command, these are named descriptively:
> `StepProgress::goto`, `SparkLine::load`, `Breadcrumb::load`, `Badge::msg`,
> `StatusBar::msg`, `NotificationBanner::msg`. Each provides a `set` compatibility
> alias so older code continues to work.

---

### ttkbootstrap::Sidebar

A collapsible navigation panel for multi-page applications. Displays icon+label
navigation items, separators, and badge counts. Supports expand/collapse to an
icon-only mode.

```tcl
set sb [ttkbootstrap::Sidebar .sb \
    -bootstyle   dark \
    -width       200 \
    -minwidth    48 \
    -collapsible 1]
pack $sb -side left -fill y

# Add navigation items
ttkbootstrap::Sidebar::add $sb home     "Home"     -icon home     -command { show_home }
ttkbootstrap::Sidebar::add $sb reports  "Reports"  -icon chart-bar -badge 5
ttkbootstrap::Sidebar::add $sb users    "Users"    -icon users    -command { show_users }
ttkbootstrap::Sidebar::separator $sb
ttkbootstrap::Sidebar::add $sb settings "Settings" -icon settings

# Select, collapse, badge
ttkbootstrap::Sidebar::select   $sb home
ttkbootstrap::Sidebar::collapse $sb
ttkbootstrap::Sidebar::expand   $sb
ttkbootstrap::Sidebar::toggle   $sb
ttkbootstrap::Sidebar::badge    $sb reports 12
set key [ttkbootstrap::Sidebar::current $sb]
```

**Constructor options**

| Option | Default | Description |
|--------|---------|-------------|
| `-bootstyle` | `dark` | Background colour keyword |
| `-width` | `200` | Expanded width in pixels |
| `-minwidth` | `48` | Collapsed (icon-only) width |
| `-collapsible` | `1` | Show the collapse toggle button |

**Sidebar::add** `sb key label ?options?`

| Option | Default | Description |
|--------|---------|-------------|
| `-icon` | `{}` | Icon name (mapped to Unicode fallback) |
| `-command` | `{}` | Script called when item is clicked |
| `-badge` | `{}` | Badge text shown on right (empty to hide) |
| `-state` | `normal` | `normal` or `disabled` |

**Commands**

| Command | Description |
|---------|-------------|
| `Sidebar::select sb key` | Highlight item and fire its command |
| `Sidebar::separator sb` | Add a horizontal divider line |
| `Sidebar::collapse sb` | Shrink to icon-only mode |
| `Sidebar::expand sb` | Restore full width |
| `Sidebar::toggle sb` | Flip collapsed/expanded state |
| `Sidebar::badge sb key text` | Update or clear a badge (`{}` clears) |
| `Sidebar::current sb` | Return the currently selected key |

---

### ttkbootstrap::Card

A titled content panel with an accent stripe, header, body, and optional footer.

```tcl
set c [ttkbootstrap::Card .c \
    -title     "Summary" \
    -subtitle  "Last 30 days" \
    -bootstyle primary \
    -padding   12]
pack $c -fill both -expand 1

# Populate the body
set body [ttkbootstrap::Card::body .c]
ttk::label $body.l -text "Content goes here"
pack $body.l

# Add a footer with action buttons
set foot [ttkbootstrap::Card::footer .c]
ttk::button $foot.ok -text "Confirm" -style "primary.TButton"
pack $foot.ok -side right
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-title` | `{}` | Header title text |
| `-subtitle` | `{}` | Muted sub-title below the title |
| `-bootstyle` | `primary` | Accent stripe colour (`{}` = no stripe) |
| `-padding` | `10` | Body padding in pixels |
| `-relief` | `flat` | Border style: `flat`, `groove`, `solid` |
| `-borderwidth` | `1` | Border width |

**Commands**

| Command | Description |
|---------|-------------|
| `Card::body c` | Returns the body frame path |
| `Card::footer c` | Returns (creating if needed) the footer frame |
| `Card::title c ?text?` | Get or set the title label text |

---

### ttkbootstrap::Badge

A small coloured pill label for counts and status indicators. Can be standalone
or attached as a floating overlay on any existing widget.

```tcl
# Standalone badge
ttkbootstrap::Badge .b -text "42" -bootstyle danger
pack .b

# Floating badge attached to a button
set btn [ttk::button .b1 -text "Messages"]
pack .b1
ttkbootstrap::Badge::attach .b1 "5" -bootstyle danger

# Update or clear
ttkbootstrap::Badge::msg   .b1 "12"
ttkbootstrap::Badge::clear .b1
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-text` | `{}` | Badge text |
| `-bootstyle` | `danger` | Badge colour |
| `-font` | (scaled 8pt bold) | Override font |
| `-width` | `0` | Minimum character width (0 = auto) |

**Commands**

| Command | Description |
|---------|-------------|
| `Badge::attach widget text ?-bootstyle color?` | Create floating badge on widget |
| `Badge::msg widget text` | Update the attached badge text |
| `Badge::clear widget` | Hide the attached badge |

> `Badge::set` is a compatibility alias for `Badge::msg`.

---

### ttkbootstrap::StepProgress

A horizontal step indicator for wizards and multi-step forms. Shows numbered
circles with done/active/pending states and labels.

```tcl
set sp [ttkbootstrap::StepProgress .sp \
    -steps     {"Account" "Profile" "Payment" "Done"} \
    -current   0 \
    -bootstyle primary \
    -complete  success \
    -command   { puts "Step: [ttkbootstrap::StepProgress::current .sp]" }]
pack $sp -fill x -padx 20

# Navigate
ttkbootstrap::StepProgress::next    .sp     ;# advance one step
ttkbootstrap::StepProgress::prev    .sp     ;# go back one step
ttkbootstrap::StepProgress::goto    .sp 2   ;# jump to step index 2
set i [ttkbootstrap::StepProgress::current .sp]
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-steps` | `{}` | List of step label strings |
| `-current` | `0` | Initial 0-based step index |
| `-bootstyle` | `primary` | Active step colour |
| `-complete` | `success` | Completed step colour |
| `-size` | `28` | Circle diameter in pixels |
| `-command` | `{}` | Called with current index on change |

**Commands**

| Command | Description |
|---------|-------------|
| `StepProgress::goto sp index` | Jump to step index (clamped to valid range) |
| `StepProgress::next sp` | Advance one step |
| `StepProgress::prev sp` | Go back one step |
| `StepProgress::current sp` | Return current 0-based index |

> `StepProgress::set` is a compatibility alias for `StepProgress::goto`.

---

### ttkbootstrap::RatingBar

A clickable star rating widget. Clicking the current value resets to 0 (toggle).
Supports half-star read-only display and an optional readonly mode.

```tcl
set ::rating 3
ttkbootstrap::RatingBar .r \
    -variable  ::rating \
    -maximum   5 \
    -bootstyle warning \
    -command   { puts "Rating: $::rating" }
pack .r

# Read-only display (supports 0.5 increments)
ttkbootstrap::RatingBar .r2 -value 3.5 -readonly 1
pack .r2
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-variable` | (internal) | Global variable linked to rating value |
| `-value` | `0` | Initial value (if no `-variable`) |
| `-maximum` | `5` | Number of stars |
| `-bootstyle` | `warning` | Filled star colour |
| `-symbol` | `★` | Character used for each star |
| `-size` | `20` | Star font size in points |
| `-readonly` | `0` | Disable clicking |
| `-command` | `{}` | Called when rating changes |

---

### ttkbootstrap::SplashScreen

A borderless startup window with title, version, message, and optional progress
bar. Closed on click, after a timeout, or programmatically.

```tcl
set ss [ttkbootstrap::SplashScreen \
    -title     "My Application" \
    -version   "v2.1.0" \
    -message   "Loading modules..." \
    -bootstyle dark \
    -progress  1 \
    -width     400 -height 240]

ttkbootstrap::SplashScreen::progress $ss 40  "Loading plugins..."
ttkbootstrap::SplashScreen::progress $ss 100 "Ready"
after 1500
ttkbootstrap::SplashScreen::close $ss
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-title` | `"Application"` | Large title text |
| `-version` | `{}` | Version string shown below title |
| `-message` | `"Loading..."` | Status message (updatable) |
| `-bootstyle` | `dark` | Background colour |
| `-progress` | `1` | Show progress bar |
| `-width` | `420` | Window width in pixels |
| `-height` | `240` | Window height in pixels |
| `-image` | `{}` | Optional `photo` image for logo |
| `-alpha` | `0.95` | Window transparency (0.0–1.0) |
| `-duration` | `0` | Auto-close after ms (0 = manual) |
| `-parent` | `{}` | Window to centre on (default: centres on screen) |

**Commands**

| Command | Description |
|---------|-------------|
| `SplashScreen::progress ss value ?message?` | Update progress bar and message |
| `SplashScreen::message ss text` | Update message only |
| `SplashScreen::close ss` | Destroy the splash window |

---

### ttkbootstrap::Breadcrumb

A clickable navigation path showing location within a hierarchy. Each segment
except the last fires a `-command` callback when clicked.

```tcl
ttkbootstrap::Breadcrumb .bc \
    -items     {"Home" "Settings" "Users"} \
    -bootstyle primary \
    -separator "›" \
    -command   { puts "Clicked: $idx $label" }
pack .bc

# Update the path
ttkbootstrap::Breadcrumb::load .bc {"Home" "Files" "Documents"}
ttkbootstrap::Breadcrumb::push .bc "Report.pdf"
ttkbootstrap::Breadcrumb::pop  .bc
set items [ttkbootstrap::Breadcrumb::get .bc]
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-items` | `{}` | Initial path segment list |
| `-command` | `{}` | Called with `$idx` and `$label` on click |
| `-separator` | `›` | Separator character between segments |
| `-bootstyle` | `primary` | Link colour for clickable segments |

**Commands**

| Command | Description |
|---------|-------------|
| `Breadcrumb::load bc items` | Replace the full path list |
| `Breadcrumb::get bc` | Return the current items list |
| `Breadcrumb::push bc label` | Append a segment |
| `Breadcrumb::pop bc` | Remove the last segment |

> `Breadcrumb::set` is a compatibility alias for `Breadcrumb::load`.

---

### ttkbootstrap::Timeline

A vertical list of timestamped events with coloured dot indicators and optional
body text. Built on `ScrolledFrame` so it scrolls when content overflows.

```tcl
set tl [ttkbootstrap::Timeline .tl]
pack $tl -fill both -expand 1

ttkbootstrap::Timeline::add .tl \
    -title     "Deployed v2.0" \
    -timestamp "2024-05-10 14:32" \
    -body      "All services updated successfully." \
    -bootstyle success \
    -icon      "✓"

ttkbootstrap::Timeline::add .tl \
    -title     "Build failed" \
    -timestamp "2024-05-10 12:15" \
    -bootstyle danger \
    -icon      "✗"

ttkbootstrap::Timeline::clear .tl
```

**Event options** (passed to `Timeline::add`)

| Option | Default | Description |
|--------|---------|-------------|
| `-title` | `{}` | Event title (bold) |
| `-timestamp` | `{}` | Date/time string shown right-aligned |
| `-body` | `{}` | Description text below the title |
| `-bootstyle` | `primary` | Dot/icon colour |
| `-icon` | `•` | Single character shown in the dot |

**Commands**

| Command | Description |
|---------|-------------|
| `Timeline::add tl ?options?` | Append an event |
| `Timeline::clear tl` | Remove all events |

---

### ttkbootstrap::SparkLine

An inline canvas mini-chart for showing trends at a glance. No axes, no labels
— just the data shape. Supports live updates via `push`.

```tcl
# Line sparkline
ttkbootstrap::SparkLine .sl \
    -data      {12 34 28 45 39 52 61 48} \
    -bootstyle primary \
    -width     80 -height 24 \
    -type      line
pack .sl -side left

# Bar sparkline
ttkbootstrap::SparkLine .sb \
    -data      {5 3 8 2 9 4 7} \
    -bootstyle success \
    -type      bar
pack .sb -side left

# Append live data (scrolling window of 20 points)
ttkbootstrap::SparkLine::push .sl 72 -maxpoints 20

# Replace all data
ttkbootstrap::SparkLine::load .sl {1 2 3 4 5 6 7 8}

# Read current data
set data [ttkbootstrap::SparkLine::get .sl]
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-data` | `{}` | Initial data value list |
| `-bootstyle` | `primary` | Line/bar colour |
| `-width` | `80` | Canvas width in pixels |
| `-height` | `24` | Canvas height in pixels |
| `-type` | `line` | `line` or `bar` |
| `-filled` | `1` | Fill area under line |
| `-smooth` | `1` | Smooth the line curve |
| `-minval` | `{}` | Y-axis minimum (auto if empty) |
| `-maxval` | `{}` | Y-axis maximum (auto if empty) |
| `-dot` | `1` | Show a dot at the last data point |

**Commands**

| Command | Description |
|---------|-------------|
| `SparkLine::load sl data` | Replace data list and redraw |
| `SparkLine::push sl value ?-maxpoints n?` | Append value, trim to n points |
| `SparkLine::get sl` | Return the current data list |

> `SparkLine::set` is a compatibility alias for `SparkLine::load`.

---

## Tier 3 widgets (1.4.4)

### ttkbootstrap::DateRangePicker

Two linked calendar grids for selecting a start and end date. Shares the
`_dp_*` calendar infrastructure from `DateEntry`. The user clicks a date in
the left calendar to set the start date, then clicks a date in the right
calendar to set the end date. Selected dates are highlighted and the range
between them is shaded.

```tcl
set drp [ttkbootstrap::DateRangePicker .drp \
    -bootstyle primary \
    -startvar  ::start_date \
    -endvar    ::end_date \
    -command   { puts "Range: $::start_date to $::end_date" }]
pack $drp -fill x

# Programmatic control
ttkbootstrap::DateRangePicker::set   .drp "2024-01-01" "2024-01-31"
ttkbootstrap::DateRangePicker::clear .drp
set range [ttkbootstrap::DateRangePicker::get   .drp]  ;# {start end}
set start [ttkbootstrap::DateRangePicker::start .drp]
set end   [ttkbootstrap::DateRangePicker::end   .drp]
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-bootstyle` | `primary` | Calendar accent colour |
| `-startvar` | `{}` | Global variable linked to the start date string |
| `-endvar` | `{}` | Global variable linked to the end date string |
| `-command` | `{}` | Called when both dates are selected |
| `-dateformat` | `%Y-%m-%d` | `strftime` format for date strings |
| `-firstweekday` | `0` | `0` = Sunday first, `1` = Monday first |
| `-allowpast` | `1` | Allow past dates to be selected |
| `-mindate` | `{}` | `{year month day}` minimum selectable date |
| `-maxdate` | `{}` | `{year month day}` maximum selectable date |

**Commands**

| Command | Description |
|---------|-------------|
| `DateRangePicker::get drp` | Returns `{start end}` formatted date list |
| `DateRangePicker::start drp` | Returns formatted start date string |
| `DateRangePicker::end drp` | Returns formatted end date string |
| `DateRangePicker::clear drp` | Clear both selections |
| `DateRangePicker::set drp start end` | Set start and end programmatically |

---

### ttkbootstrap::EditableTableview

Extends `Tableview` with double-click in-place cell editing. Double-click any
cell to open a floating entry widget over it. Press Return to confirm, Tab to
confirm and move to the next cell (wrapping rows), or Escape to cancel.

```tcl
set tv [ttkbootstrap::EditableTableview .tv \
    -coldata {
        {text "Name"  stretch 1}
        {text "Email" stretch 1}
        {text "Role"  stretch 0 width 120}
    } \
    -rowdata {
        {Alice alice@corp.com Manager}
        {Bob   bob@corp.com  Developer}
    } \
    -bootstyle    primary \
    -editcolumns  {0 1 2} \
    -editcommand  { puts "Edited: row=$rowid col=$colindex val=$newval" } \
    -validate     { expr {$newval ne {}} }]
pack $tv -fill both -expand 1

# Access data
set data [ttkbootstrap::EditableTableview::getdata .tv]
set row  [ttkbootstrap::EditableTableview::getrow  .tv $rowid]
set cell [ttkbootstrap::EditableTableview::getcell .tv $rowid $colindex]
ttkbootstrap::EditableTableview::setcell  .tv $rowid $colindex "New Value"
ttkbootstrap::EditableTableview::cancelEdit .tv
```

**Options** — accepts all `Tableview` options plus:

| Option | Default | Description |
|--------|---------|-------------|
| `-editcolumns` | `{}` | 0-based column indices that are editable (`{}` = all) |
| `-editcommand` | `{}` | Script called after a cell edit. Variables `$rowid`, `$colindex`, `$newval` are available |
| `-validate` | `{}` | Script called before commit. Must return `1` to accept or `0` to reject |

**Rowdata format** — accepts both flat and nested lists:

```tcl
# Nested (preferred)
-rowdata {{Alice alice@corp.com Manager} {Bob bob@corp.com Developer}}

# Flat (automatically chunked by column count)
-rowdata {Alice alice@corp.com Manager Bob bob@corp.com Developer}
```

**Commands**

| Command | Description |
|---------|-------------|
| `EditableTableview::getdata tv` | Returns list of row value lists |
| `EditableTableview::getrow tv rowid` | Returns value list for one row |
| `EditableTableview::getcell tv rowid colindex` | Returns single cell value |
| `EditableTableview::setcell tv rowid colindex val` | Update a cell |
| `EditableTableview::cancelEdit tv` | Dismiss editor without committing |

---

## Tier 3 widgets (1.4.4)

### ttkbootstrap::DateRangePicker

Two linked calendars for selecting a start and end date. Shows a header with the current selection, navigation arrows, day-of-week labels, a day grid, and quick-range preset buttons.

```tcl
set ::start {}; set ::end {}
set drp [ttkbootstrap::DateRangePicker .drp \
    -bootstyle   primary \
    -startvar    ::start \
    -endvar      ::end \
    -command     { puts "Range: $::start to $::end" } \
    -dateformat  "%Y-%m-%d"]
pack $drp -fill x

# Get current range
set range [ttkbootstrap::DateRangePicker::get .drp]   ;# {start end}
set s     [ttkbootstrap::DateRangePicker::start .drp]
set e     [ttkbootstrap::DateRangePicker::end   .drp]

# Set programmatically
ttkbootstrap::DateRangePicker::set .drp "2024-01-01" "2024-01-31"

# Clear both selections
ttkbootstrap::DateRangePicker::clear .drp
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-bootstyle` | `primary` | Calendar accent colour |
| `-startvar` | `{}` | Variable for start date string |
| `-endvar` | `{}` | Variable for end date string |
| `-command` | `{}` | Called when both dates are selected |
| `-dateformat` | `%Y-%m-%d` | strftime format for date strings |
| `-firstweekday` | `0` | `0` = Sunday first, `1` = Monday first |
| `-allowpast` | `1` | Allow selection of past dates |
| `-mindate` | `{}` | `{year month day}` minimum selectable date |
| `-maxdate` | `{}` | `{year month day}` maximum selectable date |

**Commands**

| Command | Description |
|---------|-------------|
| `DateRangePicker::get drp` | Returns `{start end}` formatted date list |
| `DateRangePicker::start drp` | Formatted start date string (empty if unset) |
| `DateRangePicker::end drp` | Formatted end date string (empty if unset) |
| `DateRangePicker::set drp start end` | Set both dates programmatically |
| `DateRangePicker::clear drp` | Clear both selections |

**Quick presets** — buttons below the calendars set common ranges:
Last 7 days · Last 30 days · Last 90 days · Today · Yesterday

---

### ttkbootstrap::EditableTableview

Extends `Tableview` with double-click in-place cell editing. A floating entry widget appears over the clicked cell; Tab moves to the next cell, Enter confirms, Escape cancels.

```tcl
set etv [ttkbootstrap::EditableTableview .etv \
    -coldata {
        {text "Name"  stretch 1}
        {text "Email" stretch 1}
        {text "Role"  stretch 0 width 120}
    } \
    -rowdata {
        {Alice alice@example.com Admin}
        {Bob   bob@example.com   User}
    } \
    -bootstyle    primary \
    -editcolumns  {0 1 2} \
    -editcommand  { puts "Edited: row=$rowid col=$colindex val=$newval" } \
    -validate     { expr {$newval ne {}} }]
pack $etv -fill both -expand 1

# Read data
set data  [ttkbootstrap::EditableTableview::getdata  .etv]
set row   [ttkbootstrap::EditableTableview::getrow   .etv $rowid]
set val   [ttkbootstrap::EditableTableview::getcell  .etv $rowid 0]

# Update a cell
ttkbootstrap::EditableTableview::setcell  .etv $rowid 0 "New Name"

# Cancel any active edit
ttkbootstrap::EditableTableview::cancelEdit .etv
```

**Options** — all `Tableview` options, plus:

| Option | Default | Description |
|--------|---------|-------------|
| `-editcolumns` | `{}` | 0-based column indices that are editable (empty = all) |
| `-editcommand` | `{}` | Script called after commit. `$rowid`, `$colindex`, `$newval` available |
| `-validate` | `{}` | Script called before commit. Must return `1` (accept) or `0` (reject) |

**Commands**

| Command | Description |
|---------|-------------|
| `EditableTableview::getdata tv` | Returns list of row value lists |
| `EditableTableview::getrow tv rowid` | Returns value list for one row |
| `EditableTableview::getcell tv rowid col` | Single cell value |
| `EditableTableview::setcell tv rowid col val` | Update a cell value |
| `EditableTableview::cancelEdit tv` | Dismiss editor without committing |

**Keyboard shortcuts**

| Key | Action |
|-----|--------|
| Double-click | Open cell editor |
| Enter | Confirm edit |
| Tab | Confirm and move to next cell |
| Escape | Cancel edit |

---

### ttkbootstrap::TimePicker

An entry widget with a clock-face popup for hour/minute/second selection. Companion to `DateEntry`, using the same popup pattern. Supports 24-hour, 12-hour AM/PM, and optional seconds. Seeded with the current time on creation.

```tcl
# 24-hour (default)
ttkbootstrap::TimePicker .tp \
    -bootstyle   primary \
    -textvariable ::my_time \
    -timeformat  {%H:%M} \
    -command     { puts "Time: $::my_time" }
pack .tp

# 12-hour AM/PM
ttkbootstrap::TimePicker .tp2 \
    -textvariable ::my_time2 \
    -timeformat   {%I:%M %p} \
    -ampm         1
pack .tp2

# With seconds
ttkbootstrap::TimePicker .tp3 \
    -textvariable ::my_time3 \
    -timeformat   {%H:%M:%S} \
    -seconds      1
pack .tp3

# Programmatic get/set
set val [.tp.get]
.tp.set "14:30"
```

**Options**

| Option | Default | Description |
|--------|---------|-------------|
| `-bootstyle` | `primary` | Accent colour |
| `-textvariable` | (internal) | Variable linked to the time string |
| `-timeformat` | `%H:%M` | strftime format. Tokens: `%H` 24h, `%I` 12h, `%M` minutes, `%S` seconds, `%p` AM/PM |
| `-width` | `8` | Entry width in characters |
| `-command` | `{}` | Called when time is committed |
| `-state` | `normal` | `normal`, `disabled`, or `readonly` |
| `-seconds` | `0` | Show a seconds spinbox in the popup |
| `-ampm` | (auto) | Force AM/PM mode. Auto-detected from format if empty |

**Methods** — called as `$w.method ?args?`

| Method | Description |
|--------|-------------|
| `.get` | Return current time string |
| `.set timestr` | Set time from a string (parsed automatically) |
| `.configure ?opts?` | Change options after creation |

**Popup controls**

| Control | Description |
|---------|-------------|
| Hour spinbox | 1–12 (AM/PM mode) or 0–23 (24h mode) |
| Minute spinbox | 0–59 |
| Seconds spinbox | 0–59 (when `-seconds 1`) |
| AM/PM radio | Toggle between AM and PM |
| Now · Noon · 6 AM · 6 PM | Quick-set presets |
| OK | Commit and close |
| Cancel | Discard changes and close |

**Pairing with DateEntry**

```tcl
set ::dt_date {}
set ::dt_time {}

ttkbootstrap::DateEntry   .de -textvariable ::dt_date -bootstyle primary
ttkbootstrap::TimePicker  .tp -textvariable ::dt_time -bootstyle primary
pack .de .tp -side left -padx 4
```
