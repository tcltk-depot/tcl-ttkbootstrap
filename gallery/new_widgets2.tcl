# new_widgets2.tcl — Showcase of ttkbootstrap 1.4.4 new widgets
#
# Demonstrates: Sidebar, Card, Badge, StepProgress, RatingBar,
#               SplashScreen, Breadcrumb, Timeline, SparkLine
#
# Run: tclkit new_widgets2.tcl

package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

# ── Main window first — sets the theme before any widget is created ───────────
ttkbootstrap::Window \
    -themename litera \
    -title     "ttkbootstrap 1.4.4 — New Widgets" \
    -size      {980 680}

wm protocol . WM_DELETE_WINDOW { exit }

# ── Layout: Sidebar + main content ───────────────────────────────────────────
set root [ttk::frame .root]
pack $root -fill both -expand 1

# ── Sidebar ───────────────────────────────────────────────────────────────────
set sb [ttkbootstrap::Sidebar $root.sb \
    -bootstyle   dark \
    -width       190 \
    -minwidth    50 \
    -collapsible 1]
pack $sb -side left -fill y

ttkbootstrap::Sidebar::add $sb overview  "Overview"   -icon dashboard   -command { show_page overview }
ttkbootstrap::Sidebar::add $sb cards     "Cards"      -icon layers      -command { show_page cards }
ttkbootstrap::Sidebar::add $sb badges    "Badges"     -icon certificate  -badge 3 -command { show_page badges }
ttkbootstrap::Sidebar::add $sb steps     "Steps"      -icon steps       -command { show_page steps }
ttkbootstrap::Sidebar::add $sb rating    "Rating"     -icon star         -command { show_page rating }
ttkbootstrap::Sidebar::separator $sb
ttkbootstrap::Sidebar::add $sb timeline  "Timeline"   -icon timeline    -command { show_page timeline }
ttkbootstrap::Sidebar::add $sb spark     "SparkLine"  -icon chart-bar    -command { show_page spark }
ttkbootstrap::Sidebar::add $sb breadcrumb "Breadcrumb" -icon arrows-right -command { show_page breadcrumb }
ttkbootstrap::Sidebar::separator $sb
ttkbootstrap::Sidebar::add $sb splash    "SplashScreen" -icon ripple    -command { launch_splash }
ttkbootstrap::Sidebar::separator $sb
ttkbootstrap::Sidebar::add $sb daterange "DateRange"   -icon calendar   -command { show_page daterange }
ttkbootstrap::Sidebar::add $sb timepick  "TimePicker"  -icon clock      -command { show_page timepick }
ttkbootstrap::Sidebar::add $sb edittable "EditTable"   -icon table      -command { show_page edittable }
ttkbootstrap::Sidebar::add $sb settings  "Settings"    -icon settings   -command { show_page settings }

# ── Main area ─────────────────────────────────────────────────────────────────
set main [ttk::frame $root.main]
pack $main -side left -fill both -expand 1

# ── Breadcrumb navigation bar ─────────────────────────────────────────────────
set navbar [ttk::frame $main.navbar -padding [ttkbootstrap::_sp2 12 6]]
pack $navbar -fill x -side top

set ::bc [ttkbootstrap::Breadcrumb $navbar.bc \
    -items   {"Home"} \
    -bootstyle primary \
    -command {
        # Navigate: click a breadcrumb item to go back to that page
        set items [ttkbootstrap::Breadcrumb::get $::bc]
        set target [lindex $items $idx]
        ttkbootstrap::Breadcrumb::load $::bc [lrange $items 0 $idx]
        show_page [lindex $::page_keys $idx]
    }]
pack $bc -side left

# Page key list for breadcrumb navigation
set ::page_keys {overview}

ttk::separator $main.sep1 -orient horizontal
pack $main.sep1 -fill x

# ── Page container (pages swap here) ─────────────────────────────────────────
set ::page_frame [ttk::frame $main.pages]
pack $::page_frame -fill both -expand 1

# Status bar at bottom
set ::sb_bar [ttkbootstrap::StatusBar $main]
ttkbootstrap::StatusBar::msg $::sb_bar "Welcome to ttkbootstrap 1.4.4"
ttkbootstrap::StatusBar::right $::sb_bar "ttkbootstrap 1.4.4" 0

# ── Page builder procs ────────────────────────────────────────────────────────
set ::_showing_page 0
proc show_page {key} {
    if {$::_showing_page} return
    set ::_showing_page 1
    # Clear current page
    foreach w [winfo children $::page_frame] { destroy $w }

    # Update breadcrumb
    set labels {
        overview  "Overview"   cards  "Cards"    badges "Badges"
        steps     "Steps"      rating "Rating"   timeline "Timeline"
        spark     "SparkLine"  breadcrumb "Breadcrumb"  settings "Settings"
        splash    "SplashScreen"  daterange "DateRangePicker"
        timepick  "TimePicker"    edittable "EditableTableview"
    }
    array set lmap $labels
    set ::page_keys [list overview $key]
    if {$key eq "overview"} {
        ttkbootstrap::Breadcrumb::load $::bc {"Home"}
        set ::page_keys {overview}
    } else {
        ttkbootstrap::Breadcrumb::load $::bc [list "Home" $lmap($key)]
        set ::page_keys [list overview $key]
    }

    # Highlight sidebar item
    ttkbootstrap::Sidebar::select $::root.sb $key

    # Build page content
    build_$key $::page_frame

    ttkbootstrap::StatusBar::msg $::sb_bar "Viewing: $lmap($key)" -clear 3000
    set ::_showing_page 0
}

# ── Overview page ─────────────────────────────────────────────────────────────
proc build_overview {f} {
    set ::card_idx 0
    set ::sr_idx 0
    set sf [ttkbootstrap::ScrolledFrame $f.sf]
    pack $sf -fill both -expand 1
    set p [$f.sf.interior]

    ttk::label $p.title \
        -text "ttkbootstrap 1.4.4 — New Widgets" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 16] bold]
    pack $p.title -anchor w -padx [ttkbootstrap::_sp 20] -pady [ttkbootstrap::_sp 16]

    # Summary cards in a grid
    set grid [ttk::frame $p.grid -padding [ttkbootstrap::_sp 16]]
    pack $grid -fill x

    foreach {title subtitle bs icon} {
        "Sidebar"      "Navigation panel"    primary  ◧
        "Card"         "Content container"   success  ▦
        "Badge"        "Status pill"         danger   ●
        "StepProgress" "Wizard steps"        info     ▸
        "RatingBar"    "Star rating"         warning  ★
        "SplashScreen" "Startup screen"      secondary ⊙
        "Breadcrumb"   "Nav path"            primary  ›
        "Timeline"     "Event history"       success  ≡
        "SparkLine"    "Mini chart"          info     ∿
    } {
        set c [ttkbootstrap::Card $grid.c[incr ::card_idx] \
            -title     $title \
            -subtitle  $subtitle \
            -bootstyle $bs \
            -padding   8]
        set body [ttkbootstrap::Card::body $grid.c$::card_idx]
        ttk::label $body.icon \
            -text $icon \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 24]] \
            -foreground [ttkbootstrap::getColor $bs]
        pack $body.icon
        grid $grid.c$::card_idx -row [expr {($::card_idx-1)/3}] \
            -column [expr {($::card_idx-1)%3}] \
            -padx [ttkbootstrap::_sp 6] -pady [ttkbootstrap::_sp 6] -sticky nsew
    }
    for {set c 0} {$c < 3} {incr c} { grid columnconfigure $grid $c -weight 1 }

    # SparkLine preview row
    set spark_row [ttk::frame $p.sparks -padding [ttkbootstrap::_sp 16]]
    pack $spark_row -fill x
    ttk::label $spark_row.lbl \
        -text "Live data samples:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $spark_row.lbl -anchor w -pady [ttkbootstrap::_sp2 0 8]

    set ::spark_data {}
    for {set i 0} {$i < 20} {incr i} {
        lappend ::spark_data [expr {int(rand()*80+10)}]
    }

    foreach {label bs type} {
        "Revenue"  primary line
        "Users"    success bar
        "Errors"   danger  line
    } {
        set row [ttk::frame $spark_row.r[incr ::sr_idx] -padding [ttkbootstrap::_sp2 0 4]]
        pack $row -fill x
        ttk::label $row.lbl -text "$label:" -width 12 -anchor w
        set sl [ttkbootstrap::SparkLine $row.sl \
            -data      $::spark_data \
            -bootstyle $bs \
            -type      $type \
            -width     120 -height 24]
        ttk::label $row.val \
            -text "[lindex $::spark_data end]" \
            -foreground [ttkbootstrap::getColor $bs] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 10] bold]
        pack $row.lbl $sl $row.val -side left -padx [ttkbootstrap::_sp 4]
    }

}

proc build_overview_fixed {f} {
    set sf [ttkbootstrap::ScrolledFrame $f.sf]
    pack $sf -fill both -expand 1
    set p [$f.sf.interior]
    build_overview_content $p
}

# ── Cards page ────────────────────────────────────────────────────────────────
proc build_cards {f} {
    set sf [ttkbootstrap::ScrolledFrame $f.sf]
    pack $sf -fill both -expand 1
    set p [$f.sf.interior]

    ttk::label $p.h -text "Card widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 16 8]

    # Basic card
    set c1 [ttkbootstrap::Card $p.c1 \
        -title    "Basic Card" \
        -subtitle "With header and body" \
        -bootstyle primary -padding 12]
    set body1 [ttkbootstrap::Card::body $p.c1]
    ttk::label $body1.l -text "This is the card body. Place any widgets here." \
        -wraplength [ttkbootstrap::_sp 300] -justify left
    pack $body1.l -fill x
    pack $p.c1 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # Card with footer
    set c2 [ttkbootstrap::Card $p.c2 \
        -title    "Card with Footer" \
        -bootstyle success -padding 12]
    set body2 [ttkbootstrap::Card::body $p.c2]
    ttk::label $body2.l -text "Cards can have an optional footer with action buttons." \
        -wraplength [ttkbootstrap::_sp 300] -justify left
    pack $body2.l -fill x
    set foot [ttkbootstrap::Card::footer $p.c2]
    ttk::button $foot.ok  -text "Confirm" -style "success.TButton" \
        -command { ttkbootstrap::StatusBar::msg $::sb_bar "Confirmed!" -clear 2000 }
    ttk::button $foot.cancel -text "Cancel" -style "secondary.Outline.TButton" \
        -command { ttkbootstrap::StatusBar::msg $::sb_bar "Cancelled" -clear 2000 }
    pack $foot.ok $foot.cancel -side right -padx [ttkbootstrap::_sp 4]
    pack $p.c2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # Multiple colour variants
    ttk::label $p.h2 -text "Colour variants:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h2 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 8 4]

    set row [ttk::frame $p.row -padding [ttkbootstrap::_sp 16]]
    pack $row -fill x
    foreach {bs label} {
        primary "Primary" success "Success"
        warning "Warning" danger  "Danger"
    } {
        set ci [ttkbootstrap::Card $row.c$bs \
            -title     $label \
            -bootstyle $bs \
            -padding   8]
        set b [ttkbootstrap::Card::body $row.c$bs]
        ttk::label $b.l -text "Content area" -foreground [ttkbootstrap::getColor secondary]
        pack $b.l
        pack $row.c$bs -side left -fill x -expand 1 \
            -padx [ttkbootstrap::_sp 4]
    }
}

# ── Badges page ───────────────────────────────────────────────────────────────
proc build_badges {f} {
    set p $f
    ttk::label $p.h -text "Badge widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    # Standalone badges
    ttk::label $p.h2 -text "Standalone badges:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h2 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]

    set row [ttk::frame $p.row1 -padding [ttkbootstrap::_sp 16]]
    pack $row -fill x
    foreach {bs text} {
        primary "Primary" success "42" danger "New"
        warning "!" info "Beta" secondary "Draft"
    } {
        set b [ttkbootstrap::Badge $row.b$bs -text $text -bootstyle $bs]
        pack $b -side left -padx [ttkbootstrap::_sp 6]
    }

    # Badge counter control
    ttk::label $p.h3 -text "Counter badge on a button:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h3 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 16 8]

    set ctrl [ttk::frame $p.ctrl -padding [ttkbootstrap::_sp 16]]
    pack $ctrl -fill x

    set ::badge_count 3
    set btn [ttk::button $ctrl.btn \
        -text    "Notifications" \
        -style   "primary.TButton" \
        -padding [ttkbootstrap::_sp2 12 6]]
    pack $btn -side left

    # Sidebar badge is already showing "3" — sync it
    ttkbootstrap::Sidebar::badge $::root.sb badges $::badge_count

    # Inline badge label next to button (simpler than floating overlay)
    set badge_lbl [ttkbootstrap::Badge $ctrl.badge_lbl         -text      $::badge_count         -bootstyle danger]
    pack $badge_lbl -side left -padx [ttkbootstrap::_sp 4]

    ttk::button $ctrl.inc -text "+" -style "success.Outline.TButton" \
        -command {
            incr ::badge_count
            .root.main.pages.ctrl.badge_lbl configure -text $::badge_count
            ttkbootstrap::Sidebar::badge $::root.sb badges $::badge_count
        }
    ttk::button $ctrl.dec -text "−" -style "danger.Outline.TButton" \
        -command {
            if {$::badge_count > 0} { incr ::badge_count -1 }
            .root.main.pages.ctrl.badge_lbl configure                 -text [expr {$::badge_count > 0 ? $::badge_count : "0"}]
            ttkbootstrap::Sidebar::badge $::root.sb badges                 [expr {$::badge_count > 0 ? $::badge_count : {}}]
        }
    pack $ctrl.inc $ctrl.dec -side left -padx [ttkbootstrap::_sp 4]
}

# ── Steps page ────────────────────────────────────────────────────────────────
proc build_steps {f} {
    set p $f
    ttk::label $p.h -text "StepProgress widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    # Wizard demo
    set ::wizard_step 0
    set wizard_steps {"Account" "Profile" "Payment" "Confirm" "Done"}

    set sp [ttkbootstrap::StepProgress $p.sp \
        -steps     $wizard_steps \
        -current   0 \
        -bootstyle primary \
        -command   { update_wizard_page $::wizard_step }]
    pack $sp -fill x -padx [ttkbootstrap::_sp 24] -pady [ttkbootstrap::_sp 16]

    # Page container for wizard steps
    set wiz [ttk::frame $p.wiz -padding [ttkbootstrap::_sp 16]]
    pack $wiz -fill both -expand 1

    set ::wizard_page $wiz

    proc update_wizard_page {step} {
        foreach w [winfo children $::wizard_page] { destroy $w }
        set pages {
            0 "Enter your account details below."
            1 "Complete your profile information."
            2 "Enter your payment method."
            3 "Review and confirm your details."
            4 "Setup complete! You are ready to go."
        }
        array set pm $pages
        ttk::label $::wizard_page.msg -text $pm($step) \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 11]]
        pack $::wizard_page.msg -anchor w -pady [ttkbootstrap::_sp 8]

        if {$step < 4} {
            ttk::frame $::wizard_page.fields
            pack $::wizard_page.fields -fill x
            for {set i 0} {$i < 2} {incr i} {
                ttk::frame $::wizard_page.fields.r$i
                ttk::label $::wizard_page.fields.r$i.l \
                    -text "Field [expr {$i+1}]:" -width 10 -anchor w
                ttk::entry $::wizard_page.fields.r$i.e -width 30
                pack $::wizard_page.fields.r$i.l \
                     $::wizard_page.fields.r$i.e -side left
                pack $::wizard_page.fields.r$i -fill x \
                    -pady [ttkbootstrap::_sp 4]
            }
        } else {
            label $::wizard_page.done \
                -text "✓" \
                -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                            [ttkbootstrap::_sf 48]] \
                -foreground [ttkbootstrap::getColor success] \
                -background [ttkbootstrap::getColor bg]
            pack $::wizard_page.done
        }

        # Nav buttons
        set nav [ttk::frame $::wizard_page.nav]
        pack $nav -fill x -side bottom -pady [ttkbootstrap::_sp 12]
        if {$step > 0} {
            ttk::button $nav.back -text "← Back" \
                -style "secondary.Outline.TButton" \
                -command {
                    incr ::wizard_step -1
                    ttkbootstrap::StepProgress::prev $::page_frame.sp
                }
            pack $nav.back -side left
        }
        if {$step < 4} {
            ttk::button $nav.next -text "Next →" \
                -style "primary.TButton" \
                -command {
                    incr ::wizard_step 1
                    ttkbootstrap::StepProgress::next $::page_frame.sp
                }
            pack $nav.next -side right
        }
    }
    update_wizard_page 0
}

# ── Rating page ───────────────────────────────────────────────────────────────
proc build_rating {f} {
    set ::rr 0
    set p $f
    ttk::label $p.h -text "RatingBar widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    set items {
        "Overall experience"    ::r1
        "Ease of use"           ::r2
        "Documentation quality" ::r3
        "Performance"           ::r4
    }
    set ::r1 4; set ::r2 3; set ::r3 5; set ::r4 4

    foreach {label var} $items {
        set row [ttk::frame $p.row[incr ::rr] -padding [ttkbootstrap::_sp2 16 4]]
        pack $row -fill x
        ttk::label $row.l -text $label -width 24 -anchor w
        set rb [ttkbootstrap::RatingBar $row.rb \
            -variable  $var \
            -maximum   5 \
            -bootstyle warning \
            -command   [list apply {{var lbl} {
                ttkbootstrap::StatusBar::msg $::sb_bar \
                    "$lbl: [set $var] stars" -clear 2000
            }} $var $label]]
        ttk::label $row.val -textvariable $var -width 2 -anchor e \
            -foreground [ttkbootstrap::getColor warning]
        pack $row.l $rb $row.val -side left -padx [ttkbootstrap::_sp 4]
    }

    # Read-only display
    ttk::separator $p.sep -orient horizontal
    pack $p.sep -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    ttk::label $p.h2 -text "Read-only display (3.5 stars):" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h2 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]
    set ro [ttkbootstrap::RatingBar $p.ro \
        -value    3.5 \
        -maximum  5 \
        -bootstyle warning \
        -readonly 1]
    pack $ro -anchor w -padx [ttkbootstrap::_sp 16]
}

# ── Timeline page ─────────────────────────────────────────────────────────────
proc build_timeline {f} {
    set p $f
    ttk::label $p.h -text "Timeline widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    set tl [ttkbootstrap::Timeline $p.tl]
    set ::tl_widget $p.tl   ;# store for the Add button command
    pack $tl -fill both -expand 1 -padx [ttkbootstrap::_sp 16]

    set events {
        {success "✓" "v1.4.4 Released"    "2024-06-01 09:00"
         "Added Sidebar, Card, Badge, StepProgress, RatingBar, SplashScreen, Breadcrumb, Timeline, SparkLine."}
        {primary "★" "v1.4.3 Released"    "2024-05-15 14:30"
         "Added CollapsingFrame, ToggleSwitch, StatusBar, AutocompleteEntry, ProgressDialog, TagEntry, NotificationBanner."}
        {info    "↑" "v1.4.2 Released"    "2024-05-01 11:00"
         "Automatic DPI/HiDPI scaling. All pixel values now scale with tk scaling."}
        {warning "⚠" "Calendar Bug Fixed"  "2024-04-28 16:45"
         "Fixed date selection in current month. Drag binding was overwriting click bindings."}
        {danger  "✗" "Build Failed"        "2024-04-20 10:15"
         "Tests failed in date entry module. Regression in month navigation."}
        {secondary "•" "v1.4.1 Released"  "2024-04-01 09:00"
         "Initial port from Python ttkbootstrap. All 18 themes, core widgets, image system."}
    }
    foreach event $events {
        lassign $event bs icon title ts body
        ttkbootstrap::Timeline::add $p.tl \
            -title     $title \
            -timestamp $ts \
            -body      $body \
            -bootstyle $bs \
            -icon      $icon
    }

    # Add new event button
    set ctrl [ttk::frame $p.ctrl -padding [ttkbootstrap::_sp 16]]
    pack $ctrl -fill x

    ttk::label $ctrl.lbl -text "Add event:" -anchor w
    set ::tl_msg_var ""
    ttk::entry $ctrl.e -textvariable ::tl_msg_var -width 30
    ttk::button $ctrl.add -text "Add" -style "primary.TButton" \
        -command {
            if {$::tl_msg_var ne ""} {
                ttkbootstrap::Timeline::add $::tl_widget \
                    -title     $::tl_msg_var \
                    -timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M"] \
                    -bootstyle primary
                set ::tl_msg_var ""
            }
        }
    pack $ctrl.lbl $ctrl.e $ctrl.add -side left -padx [ttkbootstrap::_sp 4]
}

# ── SparkLine page ────────────────────────────────────────────────────────────
proc build_spark {f} {
    set ::card_idx 0
    set p $f
    ttk::label $p.h -text "SparkLine widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    # Dashboard of sparklines
    set grid [ttk::frame $p.grid -padding [ttkbootstrap::_sp 16]]
    pack $grid -fill both -expand 1

    set metrics {
        "CPU Usage"     primary  line  {45 62 58 71 65 80 74 68 85 72}
        "Memory (GB)"   info     bar   {4.2 4.5 4.1 5.0 4.8 5.2 5.1 4.9 5.3 5.0}
        "Network (MB/s)" success line  {12 45 23 67 34 89 56 23 78 45}
        "Disk I/O"      warning  bar   {10 8 15 12 20 9 14 11 18 13}
        "Error rate"    danger   line  {2 1 3 0 1 4 2 1 0 2}
        "Uptime (%)"    secondary line {99 100 98 100 99 100 100 99 100 100}
    }

    set ::spark_widgets {}
    set ::spark_val_labels {}
    set col 0; set row 0
    foreach {label bs type data} $metrics {
        set c [ttkbootstrap::Card $grid.c$row$col \
            -title $label -bootstyle $bs -padding 10]
        set body [ttkbootstrap::Card::body $grid.c$row$col]

        set sl [ttkbootstrap::SparkLine $body.sl \
            -data      $data \
            -bootstyle $bs \
            -type      $type \
            -width     160 -height 40]
        lappend ::spark_widgets $sl
        pack $sl -fill x

        set val [lindex $data end]
        ttk::label $body.val \
            -text       $val \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                              [ttkbootstrap::_sf 14] bold] \
            -foreground [ttkbootstrap::getColor $bs]
        pack $body.val -anchor e -pady [ttkbootstrap::_sp2 4 0]
        lappend ::spark_val_labels $body.val

        grid $grid.c$row$col -row $row -column $col \
            -padx [ttkbootstrap::_sp 6] -pady [ttkbootstrap::_sp 6] -sticky nsew

        incr col
        if {$col >= 3} { set col 0; incr row }
    }
    for {set c 0} {$c < 3} {incr c} { grid columnconfigure $grid $c -weight 1 }

    # Live update toggle
    set ::spark_live 0
    set ctrl [ttk::frame $p.ctrl -padding [ttkbootstrap::_sp 16]]
    pack $ctrl -fill x

    ttkbootstrap::ToggleSwitch $ctrl.live \
        -text      "Live updates (500ms)" \
        -variable  ::spark_live \
        -bootstyle success \
        -command   { toggle_spark_live }
    pack $ctrl.live -side left

    proc toggle_spark_live {} {
        if {$::spark_live} { run_spark_updates } else { catch {after cancel $::spark_after} }
    }
    proc run_spark_updates {} {
        if {!$::spark_live} return
        # Update each sparkline and its value label together
        foreach sl $::spark_widgets lbl $::spark_val_labels {
            if {[winfo exists $sl] && [namespace exists ::ttkbootstrap::sl::$sl]} {
                ttkbootstrap::SparkLine::push $sl                     [expr {int(rand()*80+10)}] -maxpoints 15
                # Refresh the number shown below the chart
                if {[winfo exists $lbl]} {
                    set latest [lindex [ttkbootstrap::SparkLine::get $sl] end]
                    $lbl configure -text $latest
                }
            }
        }
        set ::spark_after [after 500 run_spark_updates]
    }
}

# ── Breadcrumb page ───────────────────────────────────────────────────────────
proc build_breadcrumb {f} {
    set sf [ttkbootstrap::ScrolledFrame $f.sf]
    pack $sf -fill both -expand 1
    set p [$f.sf.interior]
    ttk::label $p.h -text "Breadcrumb widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    ttk::label $p.desc \
        -text "The breadcrumb at the top of this page is a live example.\nHere is a standalone demonstration:" \
        -justify left -foreground [ttkbootstrap::getColor secondary]
    pack $p.desc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 12]

    # Interactive breadcrumb demo
    set demo_bc [ttkbootstrap::Breadcrumb $p.bc \
        -items   {Home Products Electronics Laptops} \
        -bootstyle primary \
        -command {
            set items [ttkbootstrap::Breadcrumb::get $::bc_demo_widget]
            ttkbootstrap::Breadcrumb::load $::bc_demo_widget [lrange $items 0 $idx]
            ttkbootstrap::StatusBar::msg $::sb_bar "Navigated to: $label" -clear 2000
        }]
    set ::bc_demo_widget $demo_bc
    pack $demo_bc -anchor w -padx [ttkbootstrap::_sp 16] \
        -pady [ttkbootstrap::_sp2 0 16]

    # Controls
    set ctrl [ttk::frame $p.ctrl -padding [ttkbootstrap::_sp 16]]
    pack $ctrl -fill x

    ttk::button $ctrl.push -text "Push segment" -style "primary.TButton" \
        -command {
            set items [ttkbootstrap::Breadcrumb::get $::bc_demo_widget]
            ttkbootstrap::Breadcrumb::push $::bc_demo_widget "Item [expr {[llength $items]+1}]"
        }
    ttk::button $ctrl.pop -text "Pop segment" -style "secondary.Outline.TButton" \
        -command { ttkbootstrap::Breadcrumb::pop $::bc_demo_widget }
    ttk::button $ctrl.reset -text "Reset" -style "danger.Outline.TButton" \
        -command {
            ttkbootstrap::Breadcrumb::load $::bc_demo_widget {Home}
        }
    pack $ctrl.push $ctrl.pop $ctrl.reset -side left -padx [ttkbootstrap::_sp 4]

    # Separator styles
    ttk::separator $p.sep -orient horizontal
    pack $p.sep -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    ttk::label $p.h2 -text "Custom separators:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h2 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]

    set ::_sep_idx 0
    foreach {sep label} {/ Slash > Arrow . Dot} {
        incr ::_sep_idx
        set bc2 [ttkbootstrap::Breadcrumb $p.bcsep$::_sep_idx \
            -items     {"Home" "Section" "Page"} \
            -separator $sep \
            -bootstyle info]
        ttk::label $p.lblsep$::_sep_idx -text "$label \[$sep\]:" -width 14 -anchor w
        set row [ttk::frame $p.rowsep$::_sep_idx -padding [ttkbootstrap::_sp2 16 4]]
        pack $row -fill x
        pack $p.lblsep$::_sep_idx -in $row -side left
        pack $bc2 -in $row -side left
    }
}

# ── Settings page ─────────────────────────────────────────────────────────────
proc launch_splash {} {
    # Don't mark this as a page — the sidebar item launches a popup, not a page swap.
    # Show a fully-animated SplashScreen so the user can see the widget in action.
    set ss [ttkbootstrap::SplashScreen \
        -title     "ttkbootstrap 1.4.4" \
        -version   "New Widget Showcase" \
        -message   "Initialising..." \
        -bootstyle dark \
        -progress  1 \
        -width     400 \
        -height    220 \
        -parent    .]

    foreach {pct msg} {
        20  "Loading theme engine..."
        40  "Building widget library..."
        60  "Registering 16 widgets..."
        80  "Configuring styles..."
        100 "Ready!"
    } {
        ttkbootstrap::SplashScreen::progress $ss $pct $msg
        after 350
        update
    }
    after 600
    ttkbootstrap::SplashScreen::close $ss
    ttkbootstrap::StatusBar::msg $::sb_bar "SplashScreen demo complete" -clear 3000
}

proc build_daterange {f} {
    set sf [ttkbootstrap::ScrolledFrame $f.sf]
    pack $sf -fill both -expand 1
    set p [$f.sf.interior]

    ttk::label $p.h -text "DateRangePicker widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    ttk::label $p.desc \
        -text "Select a start and end date from two linked calendars." \
        -foreground [ttkbootstrap::getColor secondary] -justify left
    pack $p.desc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 12]

    set ::drp_start {}; set ::drp_end {}

    set drp [ttkbootstrap::DateRangePicker $p.drp \
        -bootstyle primary \
        -startvar  ::drp_start \
        -endvar    ::drp_end \
        -command   {
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "Range: $::drp_start  to  $::drp_end" -clear 5000
        }]
    set ::drp_widget $drp
    pack $drp -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # Display linked variables
    set vrow [ttk::frame $p.vrow -padding [ttkbootstrap::_sp2 16 8]]
    pack $vrow -fill x
    ttk::label $vrow.sl -text "Start:" -width 8 -anchor w
    ttk::label $vrow.sv -textvariable ::drp_start \
        -foreground [ttkbootstrap::getColor primary] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold] -width 14
    ttk::label $vrow.el -text "End:" -width 6 -anchor w
    ttk::label $vrow.ev -textvariable ::drp_end \
        -foreground [ttkbootstrap::getColor primary] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $vrow.sl $vrow.sv $vrow.el $vrow.ev -side left -padx [ttkbootstrap::_sp 4]

    # Controls
    set ctrl [ttk::frame $p.ctrl -padding [ttkbootstrap::_sp 16]]
    pack $ctrl -fill x

    ttk::button $ctrl.clear -text "Clear" -style "secondary.Outline.TButton" \
        -command { ttkbootstrap::DateRangePicker::clear $::drp_widget }
    ttk::button $ctrl.setjan -text "Set January 2024" -style "primary.TButton" \
        -command {
            ttkbootstrap::DateRangePicker::set $::drp_widget \
                "2024-01-01" "2024-01-31"
        }
    ttk::button $ctrl.setjun -text "Set June 2024" -style "info.TButton" \
        -command {
            ttkbootstrap::DateRangePicker::set $::drp_widget \
                "2024-06-01" "2024-06-30"
        }
    pack $ctrl.clear $ctrl.setjan $ctrl.setjun -side left \
        -padx [ttkbootstrap::_sp 4]

    # Colour variants
    ttk::separator $p.sep -orient horizontal
    pack $p.sep -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    ttk::label $p.h2 -text "Colour variants:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h2 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]

    set ::drp_ci 0
    foreach bs {success warning danger} {
        incr ::drp_ci
        set d [ttkbootstrap::DateRangePicker $p.drp$::drp_ci -bootstyle $bs]
        pack $d -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 4]
    }
}

proc build_timepick {f} {
    set p $f

    ttk::label $p.h -text "TimePicker widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    ttk::label $p.desc \
        -text "Click the clock button to open the time picker popup.\nSpinboxes for hour and minute, optional seconds and AM/PM mode." \
        -justify left -foreground [ttkbootstrap::getColor secondary]
    pack $p.desc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 16]

    # Three variants
    set rows {
        {primary  "%H:%M"    "24-hour (HH:MM)"   0 0}
        {success  "%H:%M:%S" "With seconds"       1 0}
        {warning  "%I:%M %p" "12-hour AM/PM"      0 1}
    }

    foreach row $rows {
        lassign $row bs fmt label secs ampm
        set rframe [ttk::frame $p.r$bs -padding [ttkbootstrap::_sp2 16 6]]
        pack $rframe -fill x

        ttk::label $rframe.lbl -text $label -width 20 -anchor w \
            -foreground [ttkbootstrap::getColor secondary]
        pack $rframe.lbl -side left

        set var_name ::tp_demo_${bs}
        set $var_name {}
        set tp [ttkbootstrap::TimePicker $rframe.tp \
            -bootstyle    $bs \
            -textvariable $var_name \
            -timeformat   $fmt \
            -seconds      $secs \
            -ampm         $ampm \
            -command      [list apply {{bs var} {
                ttkbootstrap::StatusBar::msg $::sb_bar \
                    "$bs TimePicker: [set $var]" -clear 3000
            }} $bs $var_name]]
        pack $tp -side left -padx [ttkbootstrap::_sp 4]

        # Live display
        ttk::label $rframe.val -textvariable $var_name -width 14 \
            -foreground [ttkbootstrap::getColor $bs] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 11] bold]
        pack $rframe.val -side left -padx [ttkbootstrap::_sp 8]
    }

    # Separator + combo demo
    ttk::separator $p.sep -orient horizontal
    pack $p.sep -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]

    ttk::label $p.h2 -text "Combined DateEntry + TimePicker:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h2 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]

    set combo [ttk::frame $p.combo -padding [ttkbootstrap::_sp 16]]
    pack $combo -fill x

    set ::dt_date {}; set ::dt_time {}
    ttk::label $combo.dl -text "Date:" -anchor w
    set de [ttkbootstrap::DateEntry $combo.de \
        -bootstyle primary -textvariable ::dt_date]
    ttk::label $combo.tl -text "Time:" -anchor w
    set te [ttkbootstrap::TimePicker $combo.te \
        -bootstyle primary -textvariable ::dt_time -timeformat {%H:%M}]
    ttk::button $combo.go -text "Apply" -style "primary.TButton" \
        -command {
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "DateTime: $::dt_date $::dt_time" -clear 4000
        }
    pack $combo.dl $combo.de $combo.tl $combo.te $combo.go \
        -side left -padx [ttkbootstrap::_sp 4]
}

proc build_edittable {f} {
    set p $f
    ttk::label $p.h -text "EditableTableview widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    ttk::label $p.desc \
        -text "Double-click any cell to edit in place. Press Return or Tab to confirm, Escape to cancel. Tab moves to the next column, wrapping to the next row." \
        -justify left -wraplength [ttkbootstrap::_sp 500] \
        -foreground [ttkbootstrap::getColor secondary]
    pack $p.desc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 12]

    set ::etv_edit_log {}

    set tv [ttkbootstrap::EditableTableview $p.tv \
        -coldata {
            {text "Name"       stretch 1}
            {text "Email"      stretch 1}
            {text "Department" stretch 0 width 140}
            {text "Role"       stretch 0 width 100}
        } \
        -rowdata {
            {Alice  alice@corp.com  Engineering  Manager}
            {Bob    bob@corp.com    Marketing    Director}
            {Carol  carol@corp.com  Engineering  Developer}
            {David  david@corp.com  HR           Analyst}
            {Eve    eve@corp.com    Finance      Manager}
        } \
        -bootstyle primary \
        -editcommand {
            lappend ::etv_edit_log "Row $rowid col $colindex: $newval"
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "Edited: $newval" -clear 2000
        }]
    pack $tv -fill both -expand 1 \
        -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]

    # Edit log
    set log_frame [ttk::labelframe $p.log -text "Edit log" \
        -padding [ttkbootstrap::_sp 8]]
    pack $log_frame -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 4]

    set log_lbl [ttk::label $log_frame.lbl \
        -text "Double-click a cell above to see edits recorded here." \
        -foreground [ttkbootstrap::getColor secondary] \
        -wraplength [ttkbootstrap::_sp 500] -justify left]
    pack $log_lbl -anchor w
    set ::etv_log_lbl $log_lbl

    # Update the log label whenever ::etv_edit_log changes.
    # Use a simple proc and remove the trace when the tableview is destroyed.
    trace add variable ::etv_edit_log write {apply {{args} {
        set last5 [lrange $::etv_edit_log end-4 end]
        catch {$::etv_log_lbl configure \
            -text [join $last5 "\n"] \
            -foreground [ttkbootstrap::getColor fg]}
    }}}
    bind $tv <Destroy> {
        catch { trace remove variable ::etv_edit_log write \
            {apply {{args} {
                set last5 [lrange $::etv_edit_log end-4 end]
                catch {$::etv_log_lbl configure \
                    -text [join $last5 "\n"] \
                    -foreground [ttkbootstrap::getColor fg]}
            }}} }
    }

    # Controls
    set ctrl [ttk::frame $p.ctrl -padding [ttkbootstrap::_sp 16]]
    pack $ctrl -fill x

    ttk::button $ctrl.clear_log -text "Clear log" \
        -style "secondary.Outline.TButton" \
        -command {
            set ::etv_edit_log {}
            catch {$::etv_log_lbl configure \
                -text "Log cleared." \
                -foreground [ttkbootstrap::getColor secondary]}
        }
    ttk::button $ctrl.get_data -text "Print all data" \
        -style "info.TButton" \
        -command {
            set data [ttkbootstrap::EditableTableview::getdata $::page_frame.tv]
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "[llength $data] rows" -clear 2000
            foreach row $data { puts $row }
        }
    pack $ctrl.clear_log $ctrl.get_data -side left -padx [ttkbootstrap::_sp 4]
}

proc build_daterange {f} {
    set sf [ttkbootstrap::ScrolledFrame $f.sf]
    pack $sf -fill both -expand 1
    set p [$f.sf.interior]

    ttk::label $p.h -text "DateRangePicker widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    ttk::label $p.desc \
        -text "Select a date range using two linked calendars. Click a start date,\nthen an end date. Use the quick presets below for common ranges." \
        -justify left -foreground [ttkbootstrap::getColor secondary]
    pack $p.desc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 12]

    set ::drp_start {}; set ::drp_end {}
    set drp [ttkbootstrap::DateRangePicker $p.drp \
        -bootstyle primary \
        -startvar  ::drp_start \
        -endvar    ::drp_end \
        -command   {
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "Range: $::drp_start to $::drp_end" -clear 4000
        }]
    set ::drp_widget $drp   ;# store path for button commands
    pack $drp -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # Show selected range
    ttk::frame $p.result -padding [ttkbootstrap::_sp 16]
    pack $p.result -fill x

    ttk::label $p.result.lbl -text "Selected range:" -anchor w
    pack $p.result.lbl -anchor w

    set rcard [ttkbootstrap::Card $p.result.card \
        -title "Current Selection" -bootstyle info -padding 12]
    set rb [ttkbootstrap::Card::body $p.result.card]
    ttk::label $rb.start -text "Start:" -width 8 -anchor w
    ttk::label $rb.sv    -textvariable ::drp_start \
        -foreground [ttkbootstrap::getColor info] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 11] bold]
    ttk::label $rb.end   -text "End:"   -width 8 -anchor w
    ttk::label $rb.ev    -textvariable ::drp_end \
        -foreground [ttkbootstrap::getColor info] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 11] bold]
    grid $rb.start $rb.sv  -sticky w -pady [ttkbootstrap::_sp 3]
    grid $rb.end   $rb.ev  -sticky w -pady [ttkbootstrap::_sp 3]
    pack $p.result.card -fill x -pady [ttkbootstrap::_sp 6]

    ttk::button $p.result.clear -text "Clear Selection" \
        -style "danger.Outline.TButton" \
        -command {
            ttkbootstrap::DateRangePicker::clear $::drp_widget
            set ::drp_start {}; set ::drp_end {}
        }
    pack $p.result.clear -anchor w -pady [ttkbootstrap::_sp 4]
}

proc build_timepick {f} {
    set p $f

    ttk::label $p.h -text "TimePicker widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    ttk::label $p.desc \
        -text "Click the clock button to open the time picker popup.\nSpinboxes for hour and minute, optional seconds and AM/PM mode." \
        -justify left -foreground [ttkbootstrap::getColor secondary]
    pack $p.desc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 16]

    # Three variants
    set rows {
        {primary  "%H:%M"    "24-hour (HH:MM)"   0 0}
        {success  "%H:%M:%S" "With seconds"       1 0}
        {warning  "%I:%M %p" "12-hour AM/PM"      0 1}
    }

    foreach row $rows {
        lassign $row bs fmt label secs ampm
        set rframe [ttk::frame $p.r$bs -padding [ttkbootstrap::_sp2 16 6]]
        pack $rframe -fill x

        ttk::label $rframe.lbl -text $label -width 20 -anchor w \
            -foreground [ttkbootstrap::getColor secondary]
        pack $rframe.lbl -side left

        set var_name ::tp_demo_${bs}
        set $var_name {}
        set tp [ttkbootstrap::TimePicker $rframe.tp \
            -bootstyle    $bs \
            -textvariable $var_name \
            -timeformat   $fmt \
            -seconds      $secs \
            -ampm         $ampm \
            -command      [list apply {{bs var} {
                ttkbootstrap::StatusBar::msg $::sb_bar \
                    "$bs TimePicker: [set $var]" -clear 3000
            }} $bs $var_name]]
        pack $tp -side left -padx [ttkbootstrap::_sp 4]

        # Live display
        ttk::label $rframe.val -textvariable $var_name -width 14 \
            -foreground [ttkbootstrap::getColor $bs] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 11] bold]
        pack $rframe.val -side left -padx [ttkbootstrap::_sp 8]
    }

    # Separator + combo demo
    ttk::separator $p.sep -orient horizontal
    pack $p.sep -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]

    ttk::label $p.h2 -text "Combined DateEntry + TimePicker:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10] bold]
    pack $p.h2 -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]

    set combo [ttk::frame $p.combo -padding [ttkbootstrap::_sp 16]]
    pack $combo -fill x

    set ::dt_date {}; set ::dt_time {}
    ttk::label $combo.dl -text "Date:" -anchor w
    set de [ttkbootstrap::DateEntry $combo.de \
        -bootstyle primary -textvariable ::dt_date]
    ttk::label $combo.tl -text "Time:" -anchor w
    set te [ttkbootstrap::TimePicker $combo.te \
        -bootstyle primary -textvariable ::dt_time -timeformat {%H:%M}]
    ttk::button $combo.go -text "Apply" -style "primary.TButton" \
        -command {
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "DateTime: $::dt_date $::dt_time" -clear 4000
        }
    pack $combo.dl $combo.de $combo.tl $combo.te $combo.go \
        -side left -padx [ttkbootstrap::_sp 4]
}

proc build_edittable {f} {
    set p $f

    ttk::label $p.h -text "EditableTableview widget" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    ttk::label $p.desc \
        -text "Double-click any cell to edit it inline. Press Enter or Tab to confirm,\nEscape to cancel. Tab moves to the next cell automatically." \
        -justify left -foreground [ttkbootstrap::getColor secondary]
    pack $p.desc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 12]

    set etv [ttkbootstrap::EditableTableview $p.etv \
        -coldata {
            {text "Name"       stretch 1}
            {text "Email"      stretch 1}
            {text "Department" stretch 0 width 140}
            {text "Role"       stretch 0 width 100}
        } \
        -rowdata {
            {Alice   alice@example.com   Engineering  Admin}
            {Bob     bob@example.com     Marketing    Editor}
            {Carol   carol@example.com   Engineering  User}
            {Dave    dave@example.com    Sales        User}
            {Eve     eve@example.com     HR           Manager}
        } \
        -bootstyle primary \
        -editcolumns {0 1 2 3} \
        -editcommand {
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "Edited cell — saving..." -clear 2000
        }]
    pack $etv -fill both -expand 1 \
        -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # Toolbar buttons
    set toolbar [ttk::frame $p.toolbar -padding [ttkbootstrap::_sp2 16 4]]
    pack $toolbar -fill x

    ttk::button $toolbar.add -text "+ Add Row" -style "success.TButton" \
        -padding [ttkbootstrap::_sp2 8 4] \
        -command {
            set tree [set ::ttkbootstrap::etv::.root.main.pages.etv::tree]
            $tree insert {} end -values {"New Name" "new@example.com" "Department" "Role"}
            ttkbootstrap::StatusBar::msg $::sb_bar "Row added" -clear 2000
        }
    ttk::button $toolbar.del -text "Delete Selected" -style "danger.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 8 4] \
        -command {
            set tree [set ::ttkbootstrap::etv::.root.main.pages.etv::tree]
            foreach sel [$tree selection] { $tree delete $sel }
            ttkbootstrap::StatusBar::msg $::sb_bar "Row deleted" -clear 2000
        }
    ttk::button $toolbar.get -text "Print All Data" -style "info.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 8 4] \
        -command {
            set data [ttkbootstrap::EditableTableview::getdata .root.main.pages.etv]
            puts "=== Table data ([llength $data] rows) ==="
            foreach row $data { puts "  $row" }
            ttkbootstrap::StatusBar::msg $::sb_bar \
                "[llength $data] rows in table" -clear 2000
        }
    pack $toolbar.add $toolbar.del $toolbar.get \
        -side left -padx [ttkbootstrap::_sp 4]
}

proc build_settings {f} {
    set p $f
    ttk::label $p.h -text "Settings" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 13] bold]
    pack $p.h -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 16]

    # Theme selection card
    set c [ttkbootstrap::Card $p.c1 -title "Theme" -bootstyle secondary -padding 12]
    set body [ttkbootstrap::Card::body $p.c1]
    set ::settings_theme [ttkbootstrap::currentTheme]
    ttk::combobox $body.cb \
        -textvariable ::settings_theme \
        -values       [ttkbootstrap::themeNames] \
        -state        readonly -width 20
    bind $body.cb <<ComboboxSelected>> {
        ttkbootstrap::setTheme $::settings_theme
        ttkbootstrap::StatusBar::msg $::sb_bar "Theme: $::settings_theme" -clear 2000
    }
    pack $body.cb -anchor w
    pack $p.c1 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # Sidebar width card
    set c2 [ttkbootstrap::Card $p.c2 -title "Sidebar" -bootstyle secondary -padding 12]
    set body2 [ttkbootstrap::Card::body $p.c2]
    set ::sidebar_visible 1
    ttkbootstrap::ToggleSwitch $body2.ts \
        -text "Show sidebar" \
        -variable ::sidebar_visible \
        -bootstyle primary \
        -command {
            if {$::sidebar_visible} {
                pack $::root.sb -before $::root.main -side left -fill y
            } else {
                pack forget $::root.sb
            }
        }
    pack $body2.ts
    pack $p.c2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]
}

# ── Kick off ──────────────────────────────────────────────────────────────────
set ::card_idx 0
set ::sr_idx   0
set ::rr       0

set ::page_frame .root.main.pages
set ::root       .root

show_page overview

# ── Startup SplashScreen — shown after the main window is fully built ─────────
# "update" flushes all pending draw calls so the main window appears first.
# The splash then appears centred on the visible window.
update
set ss [ttkbootstrap::SplashScreen \
    -title     "ttkbootstrap 1.4.4" \
    -version   "New Widget Showcase" \
    -message   "Loading demo..." \
    -bootstyle dark \
    -progress  1 \
    -width     360 -height 200 \
    -parent    .]
ttkbootstrap::SplashScreen::progress $ss 40  "Building sidebar..."
ttkbootstrap::SplashScreen::progress $ss 80  "Building content..."
ttkbootstrap::SplashScreen::progress $ss 100 "Ready"
after 800
ttkbootstrap::SplashScreen::close $ss

vwait forever
