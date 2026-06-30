# Tutorial — Building Apps with ttkbootstrap

This tutorial walks you through building real applications using ttkbootstrap's
64 widgets. Each section includes complete, runnable code examples.

## Contents

1. [Your First App](#1-your-first-app)
2. [Themes and Colours](#2-themes-and-colours)
3. [Buttons — Original and SVG](#3-buttons)
4. [Input Widgets](#4-input-widgets)
5. [Data Display](#5-data-display)
6. [Navigation Widgets](#6-navigation-widgets)
7. [Layout and Cards](#7-layout-and-cards)
8. [Date and Time Pickers](#8-date-and-time-pickers)
9. [Tables and Data](#9-tables-and-data)
10. [Overlays and Popups](#10-overlays-and-popups)
11. [Building a Complete App](#11-building-a-complete-app)
12. [New SVG Widgets](#12-new-svg-widgets)

---

## 1. Your First App

Every ttkbootstrap app starts with `Window` to create a themed root window:

```tcl
source ttkbootstrap.tcl

ttkbootstrap::Window \
    -themename litera \
    -title "My First App" \
    -size {600 400}

ttk::label .title -text "Welcome to ttkbootstrap!" \
    -font {TkDefaultFont 18 bold}
pack .title -pady 20

ttk::button .btn -text "Click Me" \
    -style "primary.TButton" \
    -command { tk_messageBox -message "Hello!" }
pack .btn -pady 10

# Start the event loop (only needed in scripts, not tclkit)
# tkwait window .
```

---

## 2. Themes and Colours

### Switching Themes at Runtime

```tcl
source ttkbootstrap.tcl
ttkbootstrap::Window -themename cosmo -title "Theme Demo"

# List all available themes
puts [ttkbootstrap::themeNames]
# → cerculean cosmo cyborg darkly flatly journal litera lumen minty
#   morph pulse sandstone simplex solar superhero united vapor yeti

# Switch theme
ttkbootstrap::setTheme darkly

# Query theme type
puts [ttkbootstrap::getColor type]   ;# → "dark"

# Get specific colours
puts [ttkbootstrap::getColor primary]    ;# → "#375a7f"
puts [ttkbootstrap::getColor bg]         ;# → "#222222"
```

### Bootstyle Colours

Every widget supports these colour keywords via `-style` or `-bootstyle`:

```tcl
# Six standard colours
foreach bs {primary secondary success info warning danger} {
    ttk::button .b_$bs -text $bs -style "$bs.TButton"
    pack .b_$bs -side left -padx 4
}

# Outline variants
foreach bs {primary success danger} {
    ttk::button .o_$bs -text $bs -style "$bs.Outline.TButton"
    pack .o_$bs -side left -padx 4
}
```

### Light vs Dark Themes

```tcl
# Get lists of themes by type
puts "Light: [ttkbootstrap::lightThemes]"
# → cerculean cosmo flatly journal litera lumen minty morph
#   pulse sandstone simplex united yeti

puts "Dark: [ttkbootstrap::darkThemes]"
# → cyborg darkly solar superhero vapor
```

---

## 3. Buttons

### Original ttk Buttons

```tcl
# Solid buttons
foreach bs {primary success warning danger} {
    ttk::button .s$bs -text [string totitle $bs] \
        -style "$bs.TButton" \
        -command [list puts "Clicked $bs"]
    pack .s$bs -side left -padx 4 -pady 8
}

# Outline buttons
foreach bs {primary success danger} {
    ttk::button .o$bs -text [string totitle $bs] \
        -style "$bs.Outline.TButton"
    pack .o$bs -side left -padx 4
}
```

### SVG Buttons — Square, Rounded, Pill

```tcl
# Square button (radius 0)
ttkbootstrap::SVGButton .sq \
    -text "Square" -bootstyle primary \
    -radius 0 -command {puts "Square!"}
pack .sq -pady 4

# Rounded button (default radius)
ttkbootstrap::SVGButton .rnd \
    -text "Rounded" -bootstyle success \
    -command {puts "Rounded!"}
pack .rnd -pady 4

# Pill button (fully rounded)
ttkbootstrap::PillButton .pill \
    -text "Pill Button" -bootstyle danger \
    -command {puts "Pill!"}
pack .pill -pady 4

# Outline pill button
ttkbootstrap::PillButton .opill \
    -text "Outline Pill" -bootstyle info \
    -outline 1 -command {puts "Outline!"}
pack .opill -pady 4
```

### SVG Checkboxes and Radio Buttons

```tcl
# SVG Checkboxes
set ::opt1 0; set ::opt2 1
ttkbootstrap::SVGCheck .ck1 \
    -text "Enable notifications" \
    -variable ::opt1 -bootstyle primary
ttkbootstrap::SVGCheck .ck2 \
    -text "Dark mode" \
    -variable ::opt2 -bootstyle success
pack .ck1 .ck2 -anchor w -pady 4

# SVG Radio buttons
set ::choice "a"
ttkbootstrap::SVGRadio .r1 -text "Option A" \
    -variable ::choice -value a -bootstyle primary
ttkbootstrap::SVGRadio .r2 -text "Option B" \
    -variable ::choice -value b -bootstyle primary
ttkbootstrap::SVGRadio .r3 -text "Option C" \
    -variable ::choice -value c -bootstyle primary
pack .r1 .r2 .r3 -anchor w -pady 2
```

### Toggle Switches

```tcl
# Round toggle (default)
ttkbootstrap::ToggleSwitch .ts1 \
    -text "WiFi" -variable ::wifi \
    -bootstyle success
pack .ts1 -pady 4

# Square toggle
ttkbootstrap::ToggleSwitch .ts2 \
    -text "Bluetooth" -variable ::bt \
    -bootstyle primary -shape square
pack .ts2 -pady 4
```

---

## 4. Input Widgets

### Entry, Combobox, Spinbox

```tcl
# Standard entry
ttk::label .ln -text "Name:"
ttk::entry .en -style "primary.TEntry"
pack .ln .en -anchor w -padx 16 -pady 2

# SVG pill-shaped entry
ttkbootstrap::SVGEntry .se \
    -bootstyle success -width 25 \
    -textvariable ::email
pack .se -padx 16 -pady 4

# Combobox
ttk::label .lc -text "Country:"
ttk::combobox .cb -values {Australia Canada UK USA} \
    -style "primary.TCombobox"
pack .lc .cb -anchor w -padx 16 -pady 2

# Spinbox
ttk::label .ls -text "Quantity:"
ttk::spinbox .sp -from 1 -to 100 \
    -style "primary.TSpinbox"
pack .ls .sp -anchor w -padx 16 -pady 2
```

### AutocompleteEntry

```tcl
ttkbootstrap::AutocompleteEntry .ac \
    -values {Apple Apricot Banana Blueberry Cherry Date
             Elderberry Fig Grape Kiwi Lemon Mango} \
    -bootstyle primary \
    -maxitems 6
pack .ac -padx 16 -pady 8
# Type "a" to see Apple, Apricot filtered
```

### TagEntry

```tcl
ttkbootstrap::TagEntry .te \
    -tags {Python Tcl JavaScript} \
    -bootstyle primary \
    -maxitems 10 \
    -command {
        puts "Tags: [ttkbootstrap::TagEntry::_dispatch .te get]"
    }
pack .te -fill x -padx 16 -pady 8
# Type a word and press Enter to add a tag
# Click × on a tag to remove it
```

### Scale and SVG Scale

```tcl
# Original scale
ttk::scale .sc -from 0 -to 100 \
    -variable ::volume \
    -style "primary.Horizontal.TScale"
pack .sc -fill x -padx 16 -pady 8

# SVG scale with rounded track and circle thumb
ttkbootstrap::SVGScale .svgsc \
    -from 0 -to 100 \
    -variable ::brightness \
    -bootstyle success \
    -command {puts "Brightness: $::brightness"}
pack .svgsc -fill x -padx 16 -pady 8
```

---

## 5. Data Display

### Meter and SVG Meter

```tcl
# Original meter
ttkbootstrap::Meter .m1 \
    -bootstyle primary \
    -amountused 72 -amounttotal 100 \
    -subtext "CPU" -metersize 180
pack .m1 -side left -padx 16

# SVG meter (crisp at any DPI)
ttkbootstrap::SVGMeter .m2 \
    -bootstyle success \
    -amountused 45 -amounttotal 100 \
    -subtext "RAM" -metersize 180
pack .m2 -side left -padx 16
```

### Progress Bars

```tcl
# Original determinate
ttk::progressbar .pb1 \
    -style "success.Horizontal.TProgressbar" \
    -value 65 -maximum 100
pack .pb1 -fill x -padx 16 -pady 4

# Original indeterminate (bouncing)
ttk::progressbar .pb2 \
    -style "info.Horizontal.TProgressbar" \
    -mode indeterminate
.pb2 start 15
pack .pb2 -fill x -padx 16 -pady 4

# SVG progress bar (rounded)
ttkbootstrap::SVGProgress .spb \
    -bootstyle warning -value 80 -maximum 100
pack .spb -padx 16 -pady 4
```

### Floodgauge

```tcl
# Original floodgauge
ttkbootstrap::Floodgauge .fg \
    -bootstyle primary \
    -variable ::download \
    -text "Downloading..." \
    -mask "%0.0f%%"
pack .fg -padx 16 -pady 8
set ::download 42

# SVG floodgauge
ttkbootstrap::SVGFloodgauge .sfg \
    -bootstyle success -value 78 -maximum 100 \
    -text "Uploading..." -mask "%0.0f%%"
pack .sfg -padx 16 -pady 8
```

### Badges, Ratings, SparkLines

```tcl
# SVG badge
ttkbootstrap::SVGBadge .b1 -text "NEW" -bootstyle danger
ttkbootstrap::SVGBadge .b2 -text "99+" -bootstyle primary
ttkbootstrap::SVGBadge .b3 -text "PRO" -bootstyle success
pack .b1 .b2 .b3 -side left -padx 4 -pady 8

# SVG star rating
ttkbootstrap::SVGRatingBar .rb \
    -variable ::rating -maximum 5 \
    -bootstyle warning
pack .rb -pady 8

# SVG sparkline (mini chart)
set sl [ttkbootstrap::SVGSparkLine .sl \
    -data {12 28 15 32 22 38 25 42} \
    -bootstyle primary -type line]
pack $sl -pady 8

# Push live data
after 1000 {ttkbootstrap::SVGSparkLine_push .sl 35}
after 2000 {ttkbootstrap::SVGSparkLine_push .sl 48}
```

---

## 6. Navigation Widgets

### Breadcrumb and SVG Breadcrumb

```tcl
# Original breadcrumb
ttkbootstrap::Breadcrumb .bc \
    -items {Home Products Electronics Laptops} \
    -bootstyle primary \
    -command {puts "Navigate to item $::idx"}
pack .bc -fill x -padx 16 -pady 8

# SVG breadcrumb (SVG chevron separators)
ttkbootstrap::SVGBreadcrumb .sbc \
    -items {Dashboard Reports Analytics} \
    -bootstyle success
pack .sbc -fill x -padx 16 -pady 8

# Dynamic updates
ttkbootstrap::SVGBreadcrumb::load .sbc {Dashboard Reports Q4}
```

### StepProgress (Wizard Steps)

```tcl
# SVG step progress
set sp [ttkbootstrap::SVGStepProgress .sp \
    -steps {Account Profile Payment Confirm Done} \
    -bootstyle primary -complete success]
pack $sp -fill x -padx 24 -pady 8

# Navigate with buttons
ttk::button .next -text "Next" -style "primary.TButton" \
    -command {ttkbootstrap::SVGStepProgress::next .sp}
ttk::button .back -text "Back" -style "secondary.TButton" \
    -command {ttkbootstrap::SVGStepProgress::prev .sp}
pack .back .next -side left -padx 4 -pady 8
```

### Sidebar

```tcl
# Original sidebar navigation
set sb [ttkbootstrap::Sidebar .sb -bootstyle primary -width 200]
ttkbootstrap::Sidebar::add $sb home     "Home"     -icon home \
    -command {puts "Home"}
ttkbootstrap::Sidebar::add $sb files    "Files"    -icon files \
    -command {puts "Files"}
ttkbootstrap::Sidebar::add $sb settings "Settings" -icon settings \
    -command {puts "Settings"}
ttkbootstrap::Sidebar::select $sb home
pack $sb -side left -fill y
```

### Collapsing Frame (Accordion)

```tcl
set cf [ttkbootstrap::CollapsingFrame .cf]
set s1 [ttkbootstrap::CollapsingFrame::add $cf "General Settings"]
    ttk::label $s1.l -text "App name, version, language..."
    pack $s1.l -anchor w -padx 8 -pady 4
set s2 [ttkbootstrap::CollapsingFrame::add $cf "Advanced"]
    ttk::label $s2.l -text "Cache, logging, debug options..."
    pack $s2.l -anchor w -padx 8 -pady 4
pack $cf -fill x -padx 16 -pady 8
```

---

## 7. Layout and Cards

### Original Card

```tcl
set c [ttkbootstrap::Card .c -title "Project Status" \
    -bootstyle primary -padding 12]
set body [ttkbootstrap::Card::body $c]
ttk::label $body.l -text "All systems operational."
pack $body.l -pady 4
set foot [ttkbootstrap::Card::footer $c]
ttk::button $foot.b -text "Details" -style "primary.Outline.TButton"
pack $foot.b -anchor e
pack $c -padx 16 -pady 8
```

### SVG Card (Rounded Corners)

```tcl
set c [ttkbootstrap::SVGCard .sc \
    -title "Revenue" -bootstyle success \
    -width 250 -height 150]
set body [ttkbootstrap::SVGCard::body $c]
ttk::label $body.l -text "Q4: +18% growth"
pack $body.l -pady 8
pack $c -padx 16 -pady 8
```

### SVG Shadow Card (Elevated)

```tcl
set c [ttkbootstrap::SVGShadowCard .shc \
    -title "Dashboard" -bootstyle primary \
    -shadow 10 -width 260 -height 180]
set body [ttkbootstrap::SVGShadowCard::body $c]
ttk::label $body.l -text "Active users: 1,247"
pack $body.l -pady 8
pack $c -padx 16 -pady 8
```

### Timeline

```tcl
# SVG Timeline with mixed shapes
set tl [ttkbootstrap::SVGTimeline .tl]
ttkbootstrap::SVGTimeline::add $tl \
    -title "Deployed v2.1" -timestamp "Today 14:32" \
    -body "All services updated." \
    -bootstyle success -icon "\u2713" -shape circle
ttkbootstrap::SVGTimeline::add $tl \
    -title "Code review" -timestamp "Yesterday 10:15" \
    -body "PR #142 approved." \
    -bootstyle primary -icon "\u2714" -shape square
ttkbootstrap::SVGTimeline::add $tl \
    -title "Bug reported" -timestamp "May 15 09:00" \
    -body "Login crash on Safari." \
    -bootstyle danger -icon "!" -shape circle
pack $tl -fill x -padx 16 -pady 8
```

---

## 8. Date and Time Pickers

### DateEntry (Original and SVG)

```tcl
# Original DateEntry
set ::date1 ""
ttkbootstrap::DateEntry .de \
    -bootstyle primary \
    -dateformat "%Y-%m-%d" \
    -textvariable ::date1
pack .de -padx 16 -pady 4

# SVG DateEntry (SVG calendar icon + circle day highlights)
set ::date2 ""
ttkbootstrap::SVGDateEntry .sde \
    -bootstyle success \
    -dateformat "%d/%m/%Y" \
    -textvariable ::date2
pack .sde -padx 16 -pady 4
```

### TimePicker (Original and SVG)

```tcl
# Original TimePicker
set ::time1 ""
ttkbootstrap::TimePicker .tp \
    -bootstyle primary \
    -textvariable ::time1 \
    -timeformat "%H:%M"
pack .tp -padx 16 -pady 4

# SVG TimePicker
set ::time2 ""
ttkbootstrap::SVGTimePicker .stp \
    -bootstyle info \
    -textvariable ::time2 \
    -timeformat "%H:%M"
pack .stp -padx 16 -pady 4
```

### DateRangePicker

```tcl
ttkbootstrap::DateRangePicker .drp \
    -bootstyle primary \
    -dateformat "%Y-%m-%d"
pack .drp -padx 16 -pady 8
```

---

## 9. Tables and Data

### Tableview (Sortable, Filterable, Paginated)

```tcl
set tv [ttkbootstrap::Tableview .tv \
    -coldata {
        {text "Name"       stretch 1}
        {text "Role"       stretch 0 width 120}
        {text "Department" stretch 0 width 140}
        {text "Status"     stretch 0 width 100}
    } \
    -rowdata {
        {Alice    Admin      Engineering Active}
        {Bob      Editor     Marketing   Active}
        {Carol    Viewer     Engineering Inactive}
        {Dave     Manager    Sales       Active}
        {Eve      Admin      Support     Active}
    } \
    -bootstyle primary \
    -searchable 1 \
    -stripecolor [ttkbootstrap::getColor light] \
    -height 6]
pack $tv -fill both -expand 1 -padx 16 -pady 8
```

### Editable Tableview

```tcl
set etv [ttkbootstrap::EditableTableview .etv \
    -coldata {
        {text "Product"  stretch 1}
        {text "Price"    stretch 0 width 100}
        {text "Stock"    stretch 0 width 80}
    } \
    -rowdata {
        {"Widget A"  "$29.99"  "150"}
        {"Widget B"  "$49.99"  "75"}
        {"Widget C"  "$19.99"  "200"}
    } \
    -bootstyle primary \
    -editcolumns {1 2}]
pack $etv -fill both -expand 1 -padx 16 -pady 8
# Double-click a cell in Price or Stock to edit
```

---

## 10. Overlays and Popups

### Tooltips

```tcl
# Original tooltip
ttk::button .b1 -text "Hover me" -style "primary.TButton"
ttkbootstrap::Tooltip .b1 "This is a tooltip"
pack .b1 -pady 4

# SVG tooltip (rounded background)
ttk::button .b2 -text "SVG Tooltip" -style "success.TButton"
ttkbootstrap::SVGTooltip .b2 "Rounded SVG tooltip!" \
    -bootstyle dark -delay 300
pack .b2 -pady 4
```

### Toast Notifications

```tcl
ttkbootstrap::Toast::show \
    -title "Download Complete" \
    -message "report_q4.pdf saved successfully." \
    -bootstyle success \
    -duration 3000
```

### Notification Banner

```tcl
ttkbootstrap::NotificationBanner::show \
    -title "Warning" \
    -message "Disk space is running low." \
    -bootstyle warning \
    -duration 5000
```

### Splash Screen

```tcl
ttkbootstrap::SplashScreen::show \
    -title "MyApp" \
    -message "Loading modules..."
after 2000 { ttkbootstrap::SplashScreen::close }
```

### Status Bar

```tcl
set sb [ttkbootstrap::StatusBar .sb -bootstyle primary]
pack $sb -fill x -side bottom
ttkbootstrap::StatusBar::msg $sb "Ready" -clear 3000
```

---

## 11. Building a Complete App

Here's a complete mini-application combining multiple widgets:

```tcl
source ttkbootstrap.tcl

ttkbootstrap::Window -themename litera \
    -title "Task Manager" -size {900 600}

# ── Sidebar ──
set sb [ttkbootstrap::Sidebar .sb -bootstyle primary -width 180]
ttkbootstrap::Sidebar::add $sb tasks  "Tasks"    -icon tasks
ttkbootstrap::Sidebar::add $sb stats  "Stats"    -icon stats
ttkbootstrap::Sidebar::add $sb config "Settings" -icon settings
ttkbootstrap::Sidebar::select $sb tasks
pack $sb -side left -fill y

# ── Main content ──
set main [ttk::frame .main]
pack $main -fill both -expand 1

# Title
ttk::label $main.title -text "Task Manager" \
    -font {TkDefaultFont 16 bold}
pack $main.title -anchor w -padx 16 -pady {16 8}

# Stats cards row
set cards [ttk::frame $main.cards]
pack $cards -fill x -padx 16

foreach {title value bs} {
    "Active" "12 tasks" primary
    "Completed" "48 tasks" success
    "Overdue" "3 tasks" danger
} {
    set c [ttkbootstrap::SVGShadowCard $cards.c[incr ::ci] \
        -title $title -bootstyle $bs \
        -shadow 10 -width 200 -height 100]
    set body [ttkbootstrap::SVGShadowCard::body $c]
    ttk::label $body.v -text $value
    pack $body.v -pady 4
    pack $c -side left -padx 6 -fill both -expand 1
}

# Task table
set tv [ttkbootstrap::Tableview $main.tv \
    -coldata {
        {text "Task"     stretch 1}
        {text "Priority" stretch 0 width 100}
        {text "Due Date" stretch 0 width 120}
        {text "Status"   stretch 0 width 100}
    } \
    -rowdata {
        {"Update docs"      "High"   "2025-06-01" "In Progress"}
        {"Fix login bug"    "High"   "2025-05-28" "In Progress"}
        {"Add dark mode"    "Medium" "2025-06-15" "Pending"}
        {"Write tests"      "Low"    "2025-06-30" "Pending"}
        {"Deploy v2.1"      "High"   "2025-05-30" "Done"}
    } \
    -bootstyle primary \
    -searchable 1 \
    -height 6]
pack $tv -fill both -expand 1 -padx 16 -pady 8

# Status bar
set status [ttkbootstrap::StatusBar .status -bootstyle primary]
pack $status -fill x -side bottom
ttkbootstrap::StatusBar::msg $status "Ready — 12 active tasks"
```

---



---

## 12. New SVG Widgets

### Animated Toggle Switches

```tcl
set ::wifi 1
set ::bluetooth 0
set ::airplane 0

ttkbootstrap::SVGToggleSwitch .ts1 \
    -text "WiFi" -variable ::wifi \
    -bootstyle success \
    -command {puts "WiFi: $::wifi"}
ttkbootstrap::SVGToggleSwitch .ts2 \
    -text "Bluetooth" -variable ::bluetooth \
    -bootstyle primary
ttkbootstrap::SVGToggleSwitch .ts3 \
    -text "Airplane Mode" -variable ::airplane \
    -bootstyle danger -shape square
pack .ts1 .ts2 .ts3 -anchor w -pady 4
```

### Progress Rings and Spinners

```tcl
# Determinate rings
foreach {bs val} {primary 25 success 50 warning 75 danger 100} {
    set pr [ttkbootstrap::SVGProgressRing .pr_$bs \
        -bootstyle $bs -value $val -size 50]
    pack $pr -side left -padx 8
}

# Loading spinner
set spin [ttkbootstrap::SVGProgressRing .spin \
    -bootstyle info -size 50]
ttkbootstrap::SVGProgressRing_spin $spin
pack $spin -side left -padx 8

# Update a ring's value
after 2000 {ttkbootstrap::SVGProgressRing_set .pr_primary 80}
```

### SVG Form with Validation

```tcl
source ttkbootstrap.tcl
ttkbootstrap::Window -themename litera -title "Registration"

set ::reg_name ""
set ::reg_email ""
set ::reg_age ""

ttkbootstrap::SVGFormField .name \
    -label "Full Name" -bootstyle primary \
    -textvariable ::reg_name -width 30 \
    -validate {string length $value >= 2} \
    -validmsg "\u2713 Looks good" \
    -invalidmsg "\u2717 Name too short"
pack .name -fill x -padx 16 -pady 4

ttkbootstrap::SVGFormField .email \
    -label "Email" -bootstyle primary \
    -textvariable ::reg_email -width 30 \
    -validate {regexp {.+@.+\..+} $value} \
    -validmsg "\u2713 Valid email" \
    -invalidmsg "\u2717 Enter a valid email"
pack .email -fill x -padx 16 -pady 4

ttk::label .agelbl -text "Age:"
ttkbootstrap::SVGSpinbox .age \
    -from 18 -to 120 -bootstyle primary -width 6
pack .agelbl .age -anchor w -padx 16 -pady 4

ttk::label .countrylbl -text "Country:"
ttkbootstrap::SVGCombobox .country \
    -values {Australia Canada UK USA Germany Japan} \
    -bootstyle primary -width 20
pack .countrylbl .country -anchor w -padx 16 -pady 4

ttkbootstrap::PillButton .submit \
    -text "Register" -bootstyle success \
    -command {
        set valid1 [ttkbootstrap::SVGFormField::isValid .name]
        set valid2 [ttkbootstrap::SVGFormField::isValid .email]
        if {$valid1 == 1 && $valid2 == 1} {
            puts "Registered: $::reg_name ($::reg_email)"
        }
    }
pack .submit -pady 16
```

### Colour Picker

```tcl
set ::theme_colour "#2196F3"
ttkbootstrap::SVGColourPicker .cp \
    -variable ::theme_colour \
    -columns 8
pack .cp -padx 16 -pady 8
# ::theme_colour updates when user clicks a swatch
```

### Notification Banners

```tcl
# Trigger from a button
ttk::button .notify -text "Show Notification" \
    -command {
        ttkbootstrap::SVGNotificationBanner::show \
            -title "Update Available" \
            -message "Version 2.0 is ready to install." \
            -bootstyle info -duration 4000
    }
pack .notify -pady 8
```

### SVG Icons in Buttons

```tcl
# Icon + text button
set home_icon [ttkbootstrap::SVGIcon home -size 18 -colour white]
ttk::button .btn -text " Home" -image $home_icon \
    -compound left -style "primary.TButton"
pack .btn -pady 4

# Icon-only toolbar
set toolbar [ttk::frame .toolbar]
foreach name {save edit trash refresh search} {
    set ico [ttkbootstrap::SVGIcon $name -size 20 \
        -colour [ttkbootstrap::getColor fg]]
    ttk::button $toolbar.$name -image $ico \
        -style "secondary.TButton" -padding 6
    pack $toolbar.$name -side left -padx 2
}
pack $toolbar -pady 8
```

### Auto-Detect OS Theme

```tcl
source ttkbootstrap.tcl

# Automatically match OS dark/light preference
ttkbootstrap::autoTheme -light minty -dark solar
# On a dark-themed OS → solar theme
# On a light-themed OS → minty theme
```

## Auto-Scaling

All widgets automatically scale for HiDPI and large displays. No code changes needed.

### How It Works

```tcl
# DPI-aware pixel scaling
set px [ttkbootstrap::_sp 10]   ;# 10px at 96dpi, 20px at 192dpi

# DPI-aware font scaling
set fs [ttkbootstrap::_sf 12]   ;# 12pt at 96dpi, 24pt at 192dpi

# Padding shorthand
set pad [ttkbootstrap::_sp2 8 4]     ;# {8 4} scaled
set pad [ttkbootstrap::_sp4 4 8 4 8] ;# {4 8 4 8} scaled

# Font-metric-based padding (adapts to theme font)
set pad [ttkbootstrap::_fontPad 10]   ;# {hPad vPad} computed from font
```

### Testing with Xephyr

```bash
# 4K HiDPI (2x scaling via DPI)
sudo Xephyr :20 -screen 3840x2160 -dpi 192
DISPLAY=:20 ./tclkit gallery/showcase.tcl

# Large screen at standard DPI (2x scaling via screen size)
sudo Xephyr :20 -screen 3840x2160
DISPLAY=:20 ./tclkit gallery/showcase.tcl

# Standard 1080p (1x, no scaling)
sudo Xephyr :20 -screen 1920x1080 -dpi 96
DISPLAY=:20 ./tclkit gallery/showcase.tcl
```
