#!/usr/bin/env wish
# =============================================================================
# everything_bagel.tcl
#
# Tcl/Tk port of the ttkbootstrap "everything bagel" widget demo.
# Original Python source:
#   https://github.com/israel-dryer/ttkbootstrap/blob/master/gallery/everything_bagel.py
#
# Usage:
#   wish everything_bagel.tcl
#   tclkit-tk everything_bagel.tcl
#   tclsh everything_bagel.tcl   (needs DISPLAY set on Linux)
#
# Requires ttkbootstrap package in the same directory (or on auto_path).
# =============================================================================

# Must require Tk before ttkbootstrap (important for tclkit/tclsh invocations)
package require Tk
lappend auto_path [file dirname [info script]]
package require ttkbootstrap

# ── Zen of Python text ────────────────────────────────────────────────────────
set ZEN {Beautiful is better than ugly.
Explicit is better than implicit.
Simple is better than complex.
Complex is better than complicated.
Flat is better than nested.
Sparse is better than dense.
Readability counts.
Special cases aren't special enough to break the rules.
Although practicality beats purity.
Errors should never pass silently.
Unless explicitly silenced.
In the face of ambiguity, refuse the temptation to guess.
There should be one-- and preferably only one --obvious way to do it.
Although that way may not be obvious at first unless you're Dutch.
Now is better than never.
Although never is often better than *right* now.
If the implementation is hard to explain, it's a bad idea.
If the implementation is easy to explain, it may be a good idea.
Namespaces are one honking great idea -- let's do more of those!}

# =============================================================================
# setup_demo  —  build and return the main demo frame
# =============================================================================
proc setup_demo {master} {
    global ZEN

    set theme_names [ttkbootstrap::themeNames]

    # ── Root frame ────────────────────────────────────────────────────────────
    set root [ttk::frame $master.bagel -padding [ttkbootstrap::_sp4 10 5 10 10]]

    # ── Theme selector row ────────────────────────────────────────────────────
    set theme_sel [ttk::frame $root.themesel -padding [ttkbootstrap::_sp4 5 5 5 0]]
    pack $theme_sel -fill x -expand 1

    set theme_selected [ttk::label $theme_sel.lbl \
        -text [ttkbootstrap::currentTheme] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] [ttkbootstrap::_sf 16] bold]]
    pack $theme_selected -side left

    ttk::label $theme_sel.prompt -text "Select a theme:"
    pack $theme_sel.prompt -side right

    set ::_bagel_theme [ttkbootstrap::currentTheme]
    ttk::combobox $theme_sel.cbo \
        -values $theme_names \
        -textvariable ::_bagel_theme \
        -state readonly \
        -width 18
    pack $theme_sel.cbo -side right -padx 10
    # Set initial index on Map, and update on ThemeChanged
    bind $theme_sel.cbo <Map> [list apply {{cbo names theme} {
        $cbo current [lsearch $names $theme]
        bind $cbo <Map> {}
    }} $theme_sel.cbo $theme_names [ttkbootstrap::currentTheme]]
    # Update when theme changes from either combobox
    bind . <<ThemeChanged>> [list apply {{cbo lbl names} {
        set t [ttkbootstrap::currentTheme]
        set $::_bagel_theme $t
        $cbo current [lsearch $names $t]
        $lbl configure -text $t
    }} $theme_sel.cbo $theme_selected $theme_names]

    # Change theme on top combobox selection
    bind $theme_sel.cbo <<ComboboxSelected>> [list apply {{sel lbl themevar names} {
        set t [$sel get]
        ttkbootstrap::setTheme $t
        $lbl configure -text $t
        set $themevar $t
        $sel current [lsearch $names $t]
        $sel selection clear
    }} $theme_sel.cbo $theme_selected ::_bagel_theme $theme_names]

    ttk::separator $root.sep1 -orient horizontal
    pack $root.sep1 -fill x -pady 3 -padx 10

    # ── Left and right columns ────────────────────────────────────────────────
    set lframe [ttk::frame $root.lf -padding [ttkbootstrap::_sp 5]]
    pack $lframe -side left -fill both -expand 1

    set rframe [ttk::frame $root.rf -padding [ttkbootstrap::_sp 5]]
    pack $rframe -side right -fill both -expand 1

    # =========================================================================
    # LEFT COLUMN
    # =========================================================================

    # ── Theme color buttons ───────────────────────────────────────────────────
    set color_group [ttk::labelframe $lframe.colors \
        -text "Theme color options" -padding [ttkbootstrap::_sp 10]]
    pack $color_group -fill x -side top

    set crow1 [ttk::frame $color_group.row1]
    set crow2 [ttk::frame $color_group.row2]
    pack $crow1 -fill x
    pack $crow2 -fill x -pady {5 0}

    set _ci 0
    foreach color {primary secondary success info warning danger light dark} {
        incr _ci
        set parent [expr {$_ci <= 4 ? $crow1 : $crow2}]
        set btn [ttk::button $parent.b_$color \
            -text $color \
            -style "[ttkbootstrap::bootstyle $color TButton]"]
        pack $btn -side left -expand 1 -padx 2 -fill x
    }
    unset _ci

    # ── Checkbuttons & Radiobuttons ───────────────────────────────────────────
    set rb_group [ttk::labelframe $lframe.rbs \
        -text "Checkbuttons & radiobuttons" -padding [ttkbootstrap::_sp 10]]
    pack $rb_group -fill x -pady 10 -side top

    # Checkbuttons
    set ::_bagel_chk1 1
    set ::_bagel_chk2 0
    set ::_bagel_chk3 0
    ttk::checkbutton $rb_group.chk1 -text "selected"   -variable ::_bagel_chk1
    ttk::checkbutton $rb_group.chk2 -text "deselected" -variable ::_bagel_chk2
    ttk::checkbutton $rb_group.chk3 -text "disabled"   -variable ::_bagel_chk3 \
        -state disabled

    pack $rb_group.chk1 $rb_group.chk2 $rb_group.chk3 \
        -side left -expand 1 -padx 5

    # Radiobuttons
    set ::_bagel_radio 1
    ttk::radiobutton $rb_group.rb1 -text "selected"   -variable ::_bagel_radio -value 1
    ttk::radiobutton $rb_group.rb2 -text "deselected" -variable ::_bagel_radio -value 2
    ttk::radiobutton $rb_group.rb3 -text "disabled"   -variable ::_bagel_radio -value 3 \
        -state disabled

    pack $rb_group.rb1 $rb_group.rb2 $rb_group.rb3 \
        -side left -expand 1 -padx 5

    # ── Treeview + Notebook row ───────────────────────────────────────────────
    set ttframe [ttk::frame $lframe.tvnb]
    pack $ttframe -pady 5 -fill both -expand 1 -side top

    # Treeview — equal width as notebook (both use -expand 1 -fill both)
    ttk::treeview $ttframe.tv \
        -columns {city rank} \
        -show headings \
        -height 5 \
        -selectmode browse

    $ttframe.tv heading city -text "City"
    $ttframe.tv heading rank -text "Rank"
    $ttframe.tv column  city -width [ttkbootstrap::_sp 200]
    $ttframe.tv column  rank -width [ttkbootstrap::_sp 60] -anchor center

    foreach row {
        {"South Island, New Zealand" 1}
        {"Paris"                     2}
        {"Bora Bora"                 3}
        {"Maui"                      4}
        {"Tahiti"                    5}
    } {
        $ttframe.tv insert {} end -values $row
    }
    $ttframe.tv selection set [lindex [$ttframe.tv children {}] 0]

    # Both treeview and notebook get -expand 1 -fill both so they share space equally
    pack $ttframe.tv -side left -expand 1 -fill both

    # Notebook — same pack options as treeview = equal width, equal height
    ttk::notebook $ttframe.nb
    pack $ttframe.nb -side left -padx {10 0} -expand 1 -fill both

    set nb_h [ttkbootstrap::_sp 128]
    ttk::frame $ttframe.nb.t1 -height $nb_h
    ttk::label $ttframe.nb.t1.lbl -text "This is a notebook tab.\nYou can put any widget you want here."
    pack $ttframe.nb.t1.lbl -anchor nw -padx 5 -pady 5
    $ttframe.nb add $ttframe.nb.t1 -text "Tab 1"
    $ttframe.nb add [ttk::frame $ttframe.nb.t2 -height $nb_h] -text "Tab 2"
    $ttframe.nb add [ttk::frame $ttframe.nb.t3 -height $nb_h] -text "Tab 3"
    $ttframe.nb add [ttk::frame $ttframe.nb.t4 -height $nb_h] -text "Tab 4"
    $ttframe.nb add [ttk::frame $ttframe.nb.t5 -height $nb_h] -text "Tab 5"

    # ── Text widget ───────────────────────────────────────────────────────────
    text $lframe.txt \
        -height 5 \
        -width 50 \
        -wrap none \
        -background [ttkbootstrap::getColor inputbg] \
        -foreground [ttkbootstrap::getColor inputfg] \
        -insertbackground [ttkbootstrap::getColor inputfg] \
        -relief flat \
        -borderwidth 1

    $lframe.txt insert end $ZEN
    pack $lframe.txt -side left -anchor nw -pady 5 -fill both -expand 1

    # Re-theme the text widget on theme change
    bind $lframe.txt <<ThemeChanged>> [list apply {{w} {
        $w configure \
            -background [ttkbootstrap::getColor inputbg] \
            -foreground [ttkbootstrap::getColor inputfg] \
            -insertbackground [ttkbootstrap::getColor inputfg]
    }} $lframe.txt]

    # ── Scale / Progressbar / Meter / Scrollbars ──────────────────────────────
    set lf_inner [ttk::frame $lframe.inner]
    pack $lf_inner -fill both -expand 1 -padx 10

    # Scale
    set ::_bagel_scale 75
    ttk::scale $lf_inner.scale \
        -orient horizontal \
        -variable ::_bagel_scale \
        -from 100 -to 0
    pack $lf_inner.scale -fill x -pady 5 -expand 1

    # Progressbar (default / primary)
    ttk::progressbar $lf_inner.pb1 \
        -orient horizontal \
        -value 50
    pack $lf_inner.pb1 -fill x -pady 5 -expand 1

    # Striped progressbar (success)
    ttk::progressbar $lf_inner.pb2 \
        -orient horizontal \
        -value 75 \
        -style [ttkbootstrap::bootstyle success striped TProgressbar]
    pack $lf_inner.pb2 -fill x -pady 5 -expand 1

    # Meter
    ttkbootstrap::Meter $lf_inner.meter \
        -metersize    [ttkbootstrap::_sp 150] \
        -amountused   45 \
        -subtext      "meter widget" \
        -bootstyle    info \
        -interactive  1
    pack $lf_inner.meter -pady 10

    # Horizontal scrollbar (default)
    ttk::scrollbar $lf_inner.sb1 -orient horizontal
    $lf_inner.sb1 set 0.1 0.9
    pack $lf_inner.sb1 -fill x -pady 5 -expand 1

    # Round scrollbar (danger)
    ttk::scrollbar $lf_inner.sb2 \
        -orient horizontal \
        -style [ttkbootstrap::bootstyle danger round TScrollbar]
    $lf_inner.sb2 set 0.1 0.9
    pack $lf_inner.sb2 -fill x -pady 5 -expand 1

    # =========================================================================
    # RIGHT COLUMN
    # =========================================================================

    # ── Buttons group ─────────────────────────────────────────────────────────
    set btn_group [ttk::labelframe $rframe.btns \
        -text "Buttons" -padding [ttkbootstrap::_sp2 10 5]]
    pack $btn_group -fill x

    # Theme menu (used by menubuttons)
    set menu [menu $rframe.menu -tearoff 0]
    set ::_bagel_menu_sel 0
    set idx 0
    foreach t $theme_names {
        $menu add radiobutton -label $t -variable ::_bagel_menu_sel -value $idx
        incr idx
    }

    # Solid button (primary)
    set default_btn [ttk::button $btn_group.solid \
        -text "solid button" \
        -style [ttkbootstrap::bootstyle primary TButton]]
    pack $default_btn -fill x -pady 5
    focus $default_btn
    # Store widget name for focus-reset after theme change
    set ::bagel_default_btn $default_btn

    # Solid menubutton (secondary)
    ttk::menubutton $btn_group.mb_solid \
        -text "solid menubutton" \
        -style [ttkbootstrap::bootstyle secondary TMenubutton] \
        -menu $menu
    pack $btn_group.mb_solid -fill x -pady 5

    # Solid toolbutton — styled checkbutton using TToolbutton style (toggle look)
    set ::_bagel_tb1 1
    ttk::checkbutton $btn_group.tb_solid \
        -text "solid toolbutton" \
        -variable ::_bagel_tb1 \
        -style [ttkbootstrap::bootstyle success Toolbutton.TButton]
    pack $btn_group.tb_solid -fill x -pady 5

    # Outline button (info)
    ttk::button $btn_group.outline \
        -text "outline button" \
        -style [ttkbootstrap::bootstyle info outline TButton]
    pack $btn_group.outline -fill x -pady 5

    # Outline menubutton (warning)
    ttk::menubutton $btn_group.mb_outline \
        -text "outline menubutton" \
        -style [ttkbootstrap::bootstyle warning outline TMenubutton] \
        -menu $menu
    pack $btn_group.mb_outline -fill x -pady 5

    # Outline toolbutton — uses Outline.TToolbutton style
    set ::_bagel_tb2 0
    ttk::checkbutton $btn_group.tb_outline \
        -text "outline toolbutton" \
        -variable ::_bagel_tb2 \
        -style [ttkbootstrap::bootstyle success Outline.Toolbutton.TButton]
    pack $btn_group.tb_outline -fill x -pady 5

    # Link button
    ttk::button $btn_group.link \
        -text "link button" \
        -style [ttkbootstrap::bootstyle link TButton]
    pack $btn_group.link -fill x -pady 5

    # Round toggle (success — checked)
    set ::_bagel_tog1 1
    ttk::checkbutton $btn_group.tog_round \
        -text "rounded toggle" \
        -variable ::_bagel_tog1 \
        -style [ttkbootstrap::bootstyle success round TCheckbutton]
    pack $btn_group.tog_round -fill x -pady 5

    # Square toggle (primary — checked)
    set ::_bagel_tog2 1
    ttk::checkbutton $btn_group.tog_square \
        -text "squared toggle" \
        -variable ::_bagel_tog2 \
        -style [ttkbootstrap::bootstyle square TCheckbutton]
    pack $btn_group.tog_square -fill x -pady 5

    # ── Other input widgets ───────────────────────────────────────────────────
    set input_group [ttk::labelframe $rframe.inputs \
        -text "Other input widgets" -padding [ttkbootstrap::_sp 10]]
    pack $input_group -fill both -pady {10 5} -expand 1

    # Entry
    ttk::entry $input_group.entry
    $input_group.entry insert end "entry widget"
    pack $input_group.entry -fill x

    # Password entry — use platform-safe show character
    # • (U+2022) works on macOS and Linux; Windows console fonts often miss it
    # so we detect and fall back to * on win32
    set show_char [expr {[tk windowingsystem] eq "win32" ? "*" : "•"}]
    ttk::entry $input_group.password -show $show_char
    $input_group.password insert end "password"
    pack $input_group.password -fill x -pady 5

    # Spinbox
    ttk::spinbox $input_group.spin -from 0 -to 100
    $input_group.spin set 45
    pack $input_group.spin -fill x

    # Combobox (also drives theme change to mirror Python demo)
    ttk::combobox $input_group.cbo \
        -values $theme_names \
        -textvariable ::_bagel_theme \
        -state readonly \
        -exportselection 0
    pack $input_group.cbo -fill x -pady 5

    bind $input_group.cbo <<ComboboxSelected>> [list apply {{sel top_cbo top_lbl names} {
        set t [$sel get]
        ttkbootstrap::setTheme $t
        $top_lbl configure -text $t
        set ::_bagel_theme $t
        $sel current [lsearch $names $t]
        $top_cbo current [lsearch $names $t]
        $sel selection clear
    }} $input_group.cbo $theme_sel.cbo $theme_selected $theme_names]

    # DateEntry
    ttkbootstrap::DateEntry $input_group.de
    pack $input_group.de -fill x

    # ── Footer: Sizegrip ──────────────────────────────────────────────────────
    ttk::sizegrip $root.grip
    pack $root.grip -side bottom -anchor se

    return $root
}

# =============================================================================
# Main
# =============================================================================

# Apply the starting theme
ttkbootstrap::Window -themename litera -title "ttkbootstrap widget demo" \
    -size {1100 800} \
    -minsize {800 600}

# Clean shutdown — cancel all pending after scripts before exiting
# This prevents "application has been destroyed" errors from text widget autoscan
wm protocol . WM_DELETE_WINDOW {
    foreach id [after info] { after cancel $id }
    exit
}

set bagel [setup_demo .]
pack $bagel -fill both -expand 1

# Start the event loop
if {![info exists ::tcl_interactive] || !$::tcl_interactive} {
    vwait forever
}
