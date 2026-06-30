# new_widgets.tcl — Showcase of ttkbootstrap 1.5.0 new widgets
#
# Demonstrates: CollapsingFrame, ToggleSwitch, StatusBar,
#               AutocompleteEntry, ProgressDialog, TagEntry,
#               NotificationBanner
#
# Run: tclkit-9.0.3 new_widgets.tcl

package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window \
    -themename litera \
    -title     "New Widgets — ttkbootstrap 1.5.0" \
    -size      {860 640}

wm protocol . WM_DELETE_WINDOW { exit }

# ── StatusBar (created first so it sits at the very bottom) ──────────────────
set sb [ttkbootstrap::StatusBar .]
ttkbootstrap::StatusBar::msg $sb "ttkbootstrap 1.5.0 — new widget showcase"

# ── Root scrollable frame ─────────────────────────────────────────────────────
set sf [ttkbootstrap::ScrolledFrame .sf]
pack $sf -fill both -expand 1
set root [.sf.interior]

# ── Notification Banner demo (top of content) ─────────────────────────────────
set nb_frame [ttk::frame $root.nb_frame]
pack $nb_frame -fill x -padx 20 -pady [ttkbootstrap::_sp2 10 0]

ttk::label $nb_frame.hdr \
    -text "NotificationBanner" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 12] bold]
pack $nb_frame.hdr -anchor w -pady [ttkbootstrap::_sp2 0 6]

set nb_demo [ttk::frame $nb_frame.demo]
pack $nb_demo -fill x

# The banner lives inside a bordered preview frame
set nb_preview [ttk::labelframe $nb_demo.preview -text "Preview" \
    -padding [ttkbootstrap::_sp 8]]
pack $nb_preview -fill x -side left -expand 1

set active_nb {}
proc show_nb {style msg} {
    global active_nb nb_preview
    if {$active_nb ne {} && [winfo exists $active_nb]} {
        ttkbootstrap::NotificationBanner::hide $active_nb
        destroy $active_nb
    }
    set active_nb [ttkbootstrap::NotificationBanner $nb_preview \
        -message   $msg \
        -bootstyle $style \
        -command   { ttkbootstrap::StatusBar::msg $::sb "Banner dismissed" -clear 2000 }]
}

set nb_btns [ttk::frame $nb_demo.btns]
pack $nb_btns -side left -padx [ttkbootstrap::_sp 12] -anchor n

foreach {style label} {
    info    "Info"
    success "Success"
    warning "Warning"
    danger  "Danger"
} {
    ttk::button $nb_btns.b$style \
        -text    $label \
        -style   "$style.TButton" \
        -padding [ttkbootstrap::_sp2 8 3] \
        -command [list show_nb $style "$label: this is a $style notification banner."]
    pack $nb_btns.b$style -fill x -pady [ttkbootstrap::_sp 2]
}

show_nb info "Info: click a button to change the banner style."

ttk::separator $root.sep1 -orient horizontal
pack $root.sep1 -fill x -padx 20 -pady [ttkbootstrap::_sp 10]

# ── Two-column layout for the remaining widgets ───────────────────────────────
set cols [ttk::frame $root.cols -padding [ttkbootstrap::_sp2 0 0]]
pack $cols -fill both -expand 1 -padx 20

set left  [ttk::frame $cols.left]
set right [ttk::frame $cols.right]
pack $left  -side left -fill both -expand 1 -padx [ttkbootstrap::_sp2 0 10]
pack $right -side left -fill both -expand 1

# ═══════════════════════════════════════════════════════════════
# LEFT COLUMN
# ═══════════════════════════════════════════════════════════════

# ── CollapsingFrame ───────────────────────────────────────────────────────────
ttk::label $left.cf_hdr \
    -text "CollapsingFrame" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 12] bold]
pack $left.cf_hdr -anchor w -pady [ttkbootstrap::_sp2 0 6]

set cf [ttkbootstrap::CollapsingFrame $left.cf]
pack $cf -fill x -pady [ttkbootstrap::_sp2 0 10]

# Section 1: ToggleSwitches
set pane1 [ttk::frame $cf.pane1 -padding [ttkbootstrap::_sp 10]]
foreach {var label bs} {
    ts_notif  "Enable notifications" success
    ts_auto   "Auto-save"            primary
    ts_dark   "Dark mode"            secondary
    ts_sounds "Sound effects"        info
} {
    global $var
    set $var 0
    ttkbootstrap::ToggleSwitch $pane1.ts_$var \
        -text      $label \
        -variable  $var \
        -bootstyle $bs \
        -command   [list ttkbootstrap::StatusBar::msg $sb "Toggle: $label" -clear 2000]
    pack $pane1.ts_$var -fill x -pady [ttkbootstrap::_sp 3]
}
ttkbootstrap::CollapsingFrame::add $cf $pane1 "Toggle Switches" primary

# Section 2: Options (checkbuttons)
set pane2 [ttk::frame $cf.pane2 -padding [ttkbootstrap::_sp 10]]
foreach {var label} {
    opt_a "Show toolbar"
    opt_b "Show statusbar"
    opt_c "Word wrap"
    opt_d "Line numbers"
} {
    global $var; set $var 1
    ttk::checkbutton $pane2.cb_$var \
        -text     $label \
        -variable $var
    pack $pane2.cb_$var -fill x -pady [ttkbootstrap::_sp 2]
}
ttkbootstrap::CollapsingFrame::add $cf $pane2 "Editor options" success

# Section 3: Scale sliders (collapsed by default)
set pane3 [ttk::frame $cf.pane3 -padding [ttkbootstrap::_sp 10]]
foreach {var label from to} {
    sl_font  "Font size"    8  36
    sl_tabs  "Tab width"    2  8
    sl_undo  "Undo history" 10 500
} {
    global $var; set $var [expr {($from+$to)/2}]
    ttk::frame $pane3.row_$var
    ttk::label $pane3.row_$var.lbl -text $label -width 14 -anchor w
    ttk::scale $pane3.row_$var.sc \
        -orient   horizontal \
        -from     $from -to $to \
        -variable $var
    ttk::label $pane3.row_$var.val \
        -textvariable $var -width 4 -anchor e
    pack $pane3.row_$var.lbl $pane3.row_$var.sc -side left
    pack $pane3.row_$var.val -side right
    pack $pane3.row_$var -fill x -pady [ttkbootstrap::_sp 4]
}
ttkbootstrap::CollapsingFrame::add $cf $pane3 "Editor metrics" warning
ttkbootstrap::CollapsingFrame::close $cf $pane3

ttk::separator $left.sep -orient horizontal
pack $left.sep -fill x -pady [ttkbootstrap::_sp 10]

# ── AutocompleteEntry ─────────────────────────────────────────────────────────
ttk::label $left.ac_hdr \
    -text "AutocompleteEntry" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 12] bold]
pack $left.ac_hdr -anchor w -pady [ttkbootstrap::_sp2 0 6]

set fruits {Apple Apricot Avocado Banana Blackberry Blueberry Cherry Coconut
            Cranberry Fig Grape Grapefruit Guava Kiwi Lemon Lime Lychee Mango
            Melon Nectarine Orange Papaya Peach Pear Pineapple Plum Raspberry
            Strawberry Tangerine Watermelon}

set ac_frame [ttk::frame $left.ac_frame]
pack $ac_frame -fill x -pady [ttkbootstrap::_sp2 0 4]

ttk::label $ac_frame.lbl -text "Favourite fruit:" -anchor w
pack $ac_frame.lbl -fill x

set ::ac_result {}
ttkbootstrap::AutocompleteEntry $ac_frame.ac \
    -values       $fruits \
    -textvariable ::ac_result \
    -bootstyle    primary \
    -width        28 \
    -command      [list apply {{} {
        ttkbootstrap::StatusBar::msg $::sb \
            "Selected: $::ac_result" -clear 2000
    }}]
pack $ac_frame.ac -fill x -pady [ttkbootstrap::_sp 4]

ttk::label $ac_frame.hint \
    -text "Start typing — e.g. 'bl', 'str', 'pe'" \
    -foreground [ttkbootstrap::getColor secondary]
pack $ac_frame.hint -anchor w

ttk::separator $left.sep2 -orient horizontal
pack $left.sep2 -fill x -pady [ttkbootstrap::_sp 10]

# ── TagEntry ──────────────────────────────────────────────────────────────────
ttk::label $left.te_hdr \
    -text "TagEntry" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 12] bold]
pack $left.te_hdr -anchor w -pady [ttkbootstrap::_sp2 0 6]

ttk::label $left.te_lbl -text "Project tags:" -anchor w
pack $left.te_lbl -fill x

ttkbootstrap::TagEntry $left.te \
    -tags      {Tcl Tk} \
    -bootstyle primary \
    -command   [list apply {{tags} {
        ttkbootstrap::StatusBar::msg $::sb \
            "Tags: [join $tags {, }]" -clear 2000
    }}]
pack $left.te -fill x -pady [ttkbootstrap::_sp 4]

ttk::label $left.te_hint \
    -text "Type a word and press comma or Return to add a tag.\nBackspace on empty entry removes last tag." \
    -foreground [ttkbootstrap::getColor secondary] \
    -justify left
pack $left.te_hint -anchor w

# Add some preset buttons
set te_presets [ttk::frame $left.te_presets]
pack $te_presets -fill x -pady [ttkbootstrap::_sp 4]
ttk::label $te_presets.lbl -text "Add preset:" -foreground [ttkbootstrap::getColor secondary]
pack $te_presets.lbl -side left
foreach preset {Python Go Rust Swift} {
    ttk::button $te_presets.b$preset \
        -text    $preset \
        -style   "secondary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::TagEntry::_dispatch $left.te add $preset]
    pack $te_presets.b$preset -side left -padx [ttkbootstrap::_sp 2]
}

# ═══════════════════════════════════════════════════════════════
# RIGHT COLUMN
# ═══════════════════════════════════════════════════════════════

# ── StatusBar live demo ───────────────────────────────────────────────────────
ttk::label $right.sb_hdr \
    -text "StatusBar" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 12] bold]
pack $right.sb_hdr -anchor w -pady [ttkbootstrap::_sp2 0 6]

ttk::label $right.sb_desc \
    -text "The StatusBar at the bottom of this window is live.\nUse the controls below to update it." \
    -foreground [ttkbootstrap::getColor secondary] \
    -justify left
pack $right.sb_desc -anchor w -pady [ttkbootstrap::_sp2 0 8]

set sb_ctrl [ttk::frame $right.sb_ctrl]
pack $sb_ctrl -fill x -pady [ttkbootstrap::_sp2 0 10]

set _sbidx 0
foreach {label cmd} {
    "Set message"    { ttkbootstrap::StatusBar::msg $::sb "Status updated" }
    "Show progress"  { ttkbootstrap::StatusBar::msg $::sb "Working..." -progress 65 }
    "Auto-clear 2s"  { ttkbootstrap::StatusBar::msg $::sb "Will clear in 2s..." \
                        -progress 80 -clear 2000 }
    "Clear"          { ttkbootstrap::StatusBar::clear $::sb }
} {
    ttk::button $sb_ctrl.b${_sbidx} \
        -text    $label \
        -style   "secondary.TButton" \
        -padding [ttkbootstrap::_sp2 8 4] \
        -command $cmd
    pack $sb_ctrl.b${_sbidx} -fill x -pady [ttkbootstrap::_sp 2]
    incr _sbidx
}

ttk::separator $right.sep -orient horizontal
pack $right.sep -fill x -pady [ttkbootstrap::_sp 10]

# ── ProgressDialog demo ───────────────────────────────────────────────────────
ttk::label $right.pd_hdr \
    -text "ProgressDialog" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 12] bold]
pack $right.pd_hdr -anchor w -pady [ttkbootstrap::_sp2 0 6]

ttk::label $right.pd_desc \
    -text "Modal progress dialogs for long-running operations." \
    -foreground [ttkbootstrap::getColor secondary] \
    -justify left
pack $right.pd_desc -anchor w -pady [ttkbootstrap::_sp2 0 8]

set pd_ctrl [ttk::frame $right.pd_ctrl]
pack $pd_ctrl -fill x -pady [ttkbootstrap::_sp2 0 10]

# Determinate demo
ttk::button $pd_ctrl.det \
    -text    "Determinate (0-100)" \
    -style   "primary.TButton" \
    -padding [ttkbootstrap::_sp2 8 4] \
    -command {
        set pd [ttkbootstrap::ProgressDialog . \
            -title   "Processing files" \
            -message "Scanning directory..." \
            -maximum 20 \
            -bootstyle primary]
        for {set i 0} {$i <= 20} {incr i} {
            ttkbootstrap::ProgressDialog::update $pd $i \
                "Processing file $i of 20..."
            update
            after 80
        }
        ttkbootstrap::ProgressDialog::close $pd
        ttkbootstrap::StatusBar::msg $::sb "Processing complete" -clear 2000
    }
pack $pd_ctrl.det -fill x -pady [ttkbootstrap::_sp 2]

# Indeterminate demo
ttk::button $pd_ctrl.indet \
    -text    "Indeterminate (spinner)" \
    -style   "secondary.TButton" \
    -padding [ttkbootstrap::_sp2 8 4] \
    -command {
        set pd [ttkbootstrap::ProgressDialog . \
            -title   "Connecting..." \
            -message "Please wait while we connect to the server." \
            -mode    indeterminate \
            -bootstyle info]
        ttkbootstrap::ProgressDialog::start $pd
        after 2000 [list ttkbootstrap::ProgressDialog::close $pd]
    }
pack $pd_ctrl.indet -fill x -pady [ttkbootstrap::_sp 2]

# With cancel
set ::pd_cancelled 0
ttk::button $pd_ctrl.cancel \
    -text    "With cancel button" \
    -style   "warning.TButton" \
    -padding [ttkbootstrap::_sp2 8 4] \
    -command {
        set ::pd_cancelled 0
        set pd [ttkbootstrap::ProgressDialog . \
            -title     "Downloading" \
            -message   "Downloading update package..." \
            -maximum   30 \
            -bootstyle success \
            -cancelvar ::pd_cancelled]
        for {set i 0} {$i <= 30 && !$::pd_cancelled} {incr i} {
            ttkbootstrap::ProgressDialog::update $pd $i \
                "Downloaded $i of 30 MB..."
            update
            after 60
        }
        catch { ttkbootstrap::ProgressDialog::close $pd }
        if {$::pd_cancelled} {
            ttkbootstrap::StatusBar::msg $::sb "Download cancelled" \
                -bootstyle warning -clear 2000
        } else {
            ttkbootstrap::StatusBar::msg $::sb "Download complete" \
                -bootstyle success -clear 2000
        }
    }
pack $pd_ctrl.cancel -fill x -pady [ttkbootstrap::_sp 2]

ttk::separator $right.sep2 -orient horizontal
pack $right.sep2 -fill x -pady [ttkbootstrap::_sp 10]

# ── Theme switcher ────────────────────────────────────────────────────────────
ttk::label $right.th_hdr \
    -text "Theme" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 12] bold]
pack $right.th_hdr -anchor w -pady [ttkbootstrap::_sp2 0 6]

set ::demo_theme litera
set th_frame [ttk::frame $right.th_frame]
pack $th_frame -fill x

ttk::combobox $th_frame.cb \
    -textvariable ::demo_theme \
    -values       [ttkbootstrap::themeNames] \
    -state        readonly \
    -width        16
pack $th_frame.cb -side left

ttk::button $th_frame.apply \
    -text    "Apply" \
    -style   "primary.TButton" \
    -padding [ttkbootstrap::_sp2 8 4] \
    -command {
        ttkbootstrap::setTheme $::demo_theme
        ttkbootstrap::StatusBar::msg $::sb "Theme: $::demo_theme" -clear 2000
    }
pack $th_frame.apply -side left -padx [ttkbootstrap::_sp 6]

# Done
ttkbootstrap::StatusBar::right $sb "ttkbootstrap 1.5.0" 0

vwait forever
