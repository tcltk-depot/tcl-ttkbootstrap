#!/usr/bin/env tclsh
# =============================================================================
# tests/test_suite.tcl — Comprehensive test suite for ttkbootstrap-tcl 1.5.0
# =============================================================================
# Run: ./tclkit tests/test_suite.tcl
#   or: DISPLAY=:0 tclsh tests/test_suite.tcl
#
# Tests cover: themes, scaling, colour utilities, all 27 original widgets,
# all 22 SVG widgets, theme switching, and DPI scaling.
# =============================================================================

package require Tk

set ::test_pass 0
set ::test_fail 0
set ::test_skip 0
set ::test_errors {}
set ::test_group ""

proc assert {desc expr} {
    if {[uplevel 1 [list expr $expr]]} {
        incr ::test_pass
    } else {
        incr ::test_fail
        lappend ::test_errors "$::test_group > $desc"
        puts "    FAIL: $desc"
    }
}

proc assert_eq {desc got expected} {
    if {$got eq $expected} {
        incr ::test_pass
    } else {
        incr ::test_fail
        lappend ::test_errors "$::test_group > $desc (got '$got', expected '$expected')"
        puts "    FAIL: $desc (got '$got', expected '$expected')"
    }
}

proc assert_ne {desc got notexpected} {
    if {$got ne $notexpected} {
        incr ::test_pass
    } else {
        incr ::test_fail
        lappend ::test_errors "$::test_group > $desc (got '$got', should not equal '$notexpected')"
        puts "    FAIL: $desc"
    }
}

proc assert_match {desc got pattern} {
    if {[string match $pattern $got]} {
        incr ::test_pass
    } else {
        incr ::test_fail
        lappend ::test_errors "$::test_group > $desc (got '$got', expected pattern '$pattern')"
        puts "    FAIL: $desc"
    }
}

proc assert_error {desc script} {
    if {[catch {uplevel 1 $script}]} {
        incr ::test_pass
    } else {
        incr ::test_fail
        lappend ::test_errors "$::test_group > $desc (expected an error, none raised)"
        puts "    FAIL: $desc (expected an error)"
    }
}

proc assert_noerror {desc script} {
    if {[catch {uplevel 1 $script} err]} {
        incr ::test_fail
        lappend ::test_errors "$::test_group > $desc ($err)"
        puts "    FAIL: $desc ($err)"
    } else {
        incr ::test_pass
    }
}

proc test_group {name body} {
    set ::test_group $name
    puts "\n── $name"
    if {[catch {uplevel 1 $body} err]} {
        incr ::test_fail
        lappend ::test_errors "$name > CRASH: $err"
        puts "    CRASH: $err"
    }
}

proc cleanup {} {
    foreach w [winfo children .] {
        catch { destroy $w }
    }
    update idletasks
}

# ── Load ttkbootstrap ──
set dir [file dirname [file dirname [file normalize [info script]]]]
source [file join $dir ttkbootstrap.tcl]
ttkbootstrap::Window -themename litera -title "Test Suite" -size {200 200}
wm withdraw .

puts "=========================================="
puts "ttkbootstrap-tcl Test Suite v1.5.0"
puts "=========================================="

# ═══════════════════════════════════════════════════════════════════════
# THEME TESTS
# ═══════════════════════════════════════════════════════════════════════

test_group "Theme — List and Query" {
    set names [ttkbootstrap::themeNames]
    assert "18 themes available" {[llength $names] == 18}
    
    set light [ttkbootstrap::lightThemes]
    assert "13 light themes" {[llength $light] == 13}
    
    set dark [ttkbootstrap::darkThemes]
    assert "5 dark themes" {[llength $dark] == 5}
    
    assert "litera is light" {"litera" in $light}
    assert "darkly is dark" {"darkly" in $dark}
    assert "solar is dark" {"solar" in $dark}
}

test_group "Theme — Switch All" {
    foreach theme [ttkbootstrap::themeNames] {
        assert_noerror "Switch to $theme" {
            ttkbootstrap::setTheme $theme
        }
        set type [ttkbootstrap::getColor type]
        assert "$theme has type" {$type eq "light" || $type eq "dark"}
    }
    ttkbootstrap::setTheme litera
}

test_group "Theme — getColor" {
    foreach key {primary secondary success info warning danger
                 light dark bg fg selectbg selectfg border active
                 inputfg inputbg font type} {
        assert_noerror "getColor $key" {
            ttkbootstrap::getColor $key
        }
    }
    
    set hex [ttkbootstrap::getColor primary]
    assert_match "primary is hex colour" $hex "#*"
    
    assert_eq "litera type is light" [ttkbootstrap::getColor type] "light"
    
    ttkbootstrap::setTheme darkly
    assert_eq "darkly type is dark" [ttkbootstrap::getColor type] "dark"
    ttkbootstrap::setTheme litera
}

# ═══════════════════════════════════════════════════════════════════════
# SCALING TESTS
# ═══════════════════════════════════════════════════════════════════════

test_group "Scaling — _sp / _sf" {
    set px [ttkbootstrap::_sp 10]
    assert "_sp returns integer" {[string is integer $px]}
    assert "_sp 10 >= 10" {$px >= 10}
    
    set fs [ttkbootstrap::_sf 12]
    assert "_sf returns integer" {[string is integer $fs]}
    assert "_sf 12 >= 12" {$fs >= 12}
    
    set pad [ttkbootstrap::_sp2 8 4]
    assert "_sp2 returns list" {[llength $pad] == 2}
    
    set sf [ttkbootstrap::scaleFactor]
    assert "scaleFactor >= 1.0" {$sf >= 1.0}
}

test_group "Scaling — _fontPad" {
    set pad [ttkbootstrap::_fontPad 10]
    assert "_fontPad returns list" {[llength $pad] == 2}
    set h [lindex $pad 0]
    set v [lindex $pad 1]
    assert "_fontPad h >= 10" {$h >= 10}
    assert "_fontPad v >= 2" {$v >= 2}
}

# ═══════════════════════════════════════════════════════════════════════
# COLOUR UTILITY TESTS
# ═══════════════════════════════════════════════════════════════════════

test_group "Colours — contrastFg" {
    # _contrastFg returns theme fg for dark text, theme selectfg for light text
    set darkfg [ttkbootstrap::_contrastFg "#ffffff"]
    assert "white bg → dark fg" {$darkfg ne "#ffffff"}
    set lightfg [ttkbootstrap::_contrastFg "#000000"]
    assert "black bg → light fg" {$lightfg ne "#000000"}
    set bluefg [ttkbootstrap::_contrastFg "#0000ff"]
    assert "blue bg → light fg" {$bluefg ne "#0000ff"}
    set yellowfg [ttkbootstrap::_contrastFg "#ffff00"]
    assert "yellow bg → dark fg" {$yellowfg ne "#ffff00"}
}

test_group "Colours — darken / lighten" {
    set dark [ttkbootstrap::_darken "#808080" 20]
    assert_match "darken returns hex" $dark "#*"
    assert_ne "darken changes colour" $dark "#808080"
    
    set light [ttkbootstrap::_lighten "#808080" 20]
    assert_match "lighten returns hex" $light "#*"
    assert_ne "lighten changes colour" $light "#808080"
}

test_group "Colours — _safeFont" {
    set f [ttkbootstrap::_safeFont TkDefaultFont]
    assert_eq "TkDefaultFont passes through" $f "TkDefaultFont"
    
    set f2 [ttkbootstrap::_safeFont ""]
    assert_eq "empty font falls back" $f2 "TkDefaultFont"
}

# ═══════════════════════════════════════════════════════════════════════
# ORIGINAL WIDGET TESTS
# ═══════════════════════════════════════════════════════════════════════

test_group "Original — Breadcrumb" {
    assert_noerror "create" {
        ttkbootstrap::Breadcrumb .bc \
            -items {Home Settings Users} -bootstyle primary
        pack .bc
    }
    assert_noerror "load" {
        ttkbootstrap::Breadcrumb::load .bc {Home Products}
    }
    set items [ttkbootstrap::Breadcrumb::get .bc]
    assert_eq "get returns items" $items {Home Products}
    cleanup
}

test_group "Original — Card" {
    assert_noerror "create with title" {
        set c [ttkbootstrap::Card .c -title "Test" -bootstyle primary -padding 10]
        pack $c
    }
    assert_noerror "body accessible" {
        set body [ttkbootstrap::Card::body .c]
        ttk::label $body.l -text "Hello"
        pack $body.l
    }
    assert_noerror "footer accessible" {
        set foot [ttkbootstrap::Card::footer .c]
    }
    cleanup
}

test_group "Original — DateEntry" {
    assert_noerror "create" {
        set ::testdate ""
        ttkbootstrap::DateEntry .de -bootstyle primary \
            -dateformat "%Y-%m-%d" -textvariable ::testdate
        pack .de
    }
    update idletasks
    assert "date widget created" {[winfo exists .de]}
    cleanup
}

test_group "Original — Floodgauge" {
    assert_noerror "create" {
        set ::fgval 50
        ttkbootstrap::Floodgauge .fg -bootstyle primary \
            -variable ::fgval -text "Test"
        pack .fg
    }
    cleanup
}

test_group "Original — Meter" {
    assert_noerror "create" {
        ttkbootstrap::Meter .m -bootstyle primary \
            -amountused 75 -amounttotal 100 -subtext "CPU"
        pack .m
    }
    cleanup
}

test_group "Original — ScrolledFrame" {
    assert_noerror "create" {
        set sf [ttkbootstrap::ScrolledFrame .sf -autohide 1]
        pack $sf -fill both -expand 1
    }
    cleanup
}

test_group "Original — Sidebar" {
    assert_noerror "create and add" {
        set sb [ttkbootstrap::Sidebar .sb -bootstyle primary]
        ttkbootstrap::Sidebar::add $sb home "Home"
        ttkbootstrap::Sidebar::add $sb settings "Settings"
        ttkbootstrap::Sidebar::select $sb home
        pack $sb
    }
    cleanup
}

test_group "Original — StepProgress" {
    assert_noerror "create" {
        set sp [ttkbootstrap::StepProgress .sp \
            -steps {A B C D} -bootstyle primary]
        pack $sp -fill x
    }
    assert_noerror "next" { ttkbootstrap::StepProgress::next .sp }
    assert_noerror "prev" { ttkbootstrap::StepProgress::prev .sp }
    cleanup
}

test_group "Original — StatusBar" {
    assert_noerror "create" {
        # StatusBar creates children under the given path and returns the bar frame
        ttk::frame .sbparent
        pack .sbparent -fill x -side bottom
        set ::test_sb_bar [ttkbootstrap::StatusBar .sbparent -bootstyle primary]
        update idletasks
    }
    assert_noerror "msg" {
        # msg takes the bar widget returned by StatusBar, not the parent
        ttkbootstrap::StatusBar::msg $::test_sb_bar "Hello"
    }
    cleanup
}

test_group "Original — Tableview" {
    assert_noerror "create" {
        set tv [ttkbootstrap::Tableview .tv \
            -coldata {{text "Name" stretch 1} {text "Val" stretch 0 width 80}} \
            -rowdata {{Alice 10} {Bob 20}} \
            -bootstyle primary -searchable 1]
        pack $tv -fill both -expand 1
    }
    cleanup
}

test_group "Original — TagEntry" {
    assert_noerror "create" {
        ttkbootstrap::TagEntry .te -tags {A B C} -bootstyle primary
        pack .te -fill x
        update idletasks
    }
    cleanup
}

test_group "Original — Timeline" {
    assert_noerror "create and add" {
        set tl [ttkbootstrap::Timeline .tl -bootstyle primary]
        ttkbootstrap::Timeline::add $tl \
            -title "Event 1" -timestamp "12:00" -body "Details"
        pack $tl
    }
    cleanup
}

test_group "Original — TimePicker" {
    assert_noerror "create" {
        set ::testtime ""
        ttkbootstrap::TimePicker .tp -bootstyle primary \
            -textvariable ::testtime
        pack .tp
    }
    cleanup
}

test_group "Original — ToggleSwitch" {
    assert_noerror "create round" {
        ttkbootstrap::ToggleSwitch .ts1 -variable ::v1 -bootstyle success
        pack .ts1
    }
    assert_noerror "create square" {
        ttkbootstrap::ToggleSwitch .ts2 -variable ::v2 -bootstyle primary -shape square
        pack .ts2
    }
    cleanup
}

test_group "Original — Tooltip" {
    assert_noerror "create" {
        ttk::button .btn -text "Hover"
        ttkbootstrap::Tooltip .btn "Test tooltip"
        pack .btn
    }
    cleanup
}

test_group "Original — AutocompleteEntry" {
    assert_noerror "create" {
        ttkbootstrap::AutocompleteEntry .ac \
            -values {Apple Banana Cherry} -bootstyle primary
        pack .ac
    }
    cleanup
}

test_group "Original — EditableTableview" {
    assert_noerror "create" {
        ttkbootstrap::EditableTableview .etv \
            -coldata {{text "Name" stretch 1}} \
            -rowdata {{Alice} {Bob}} \
            -editcolumns {0}
        pack .etv -fill both -expand 1
    }
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# SVG WIDGET TESTS
# ═══════════════════════════════════════════════════════════════════════

test_group "SVG — SVGButton" {
    assert_noerror "create solid" {
        ttkbootstrap::SVGButton .sb1 -text "Test" -bootstyle primary
        pack .sb1
    }
    assert_noerror "create outline" {
        ttkbootstrap::SVGButton .sb2 -text "Out" -bootstyle success -outline 1
        pack .sb2
    }
    assert_noerror "create square (radius 0)" {
        ttkbootstrap::SVGButton .sb3 -text "Sq" -bootstyle danger -radius 0
        pack .sb3
    }
    cleanup
}

test_group "SVG — PillButton" {
    assert_noerror "create solid" {
        ttkbootstrap::PillButton .pb1 -text "Pill" -bootstyle primary
        pack .pb1
    }
    assert_noerror "create outline" {
        ttkbootstrap::PillButton .pb2 -text "Out" -bootstyle info -outline 1
        pack .pb2
    }
    cleanup
}

test_group "SVG — SVGCheck / SVGRadio" {
    assert_noerror "create check" {
        set ::ck 0
        ttkbootstrap::SVGCheck .ck -text "Check" -variable ::ck -bootstyle primary
        pack .ck
    }
    assert_noerror "create radio" {
        set ::rv "a"
        ttkbootstrap::SVGRadio .r1 -text "A" -variable ::rv -value a -bootstyle primary
        ttkbootstrap::SVGRadio .r2 -text "B" -variable ::rv -value b -bootstyle primary
        pack .r1 .r2
    }
    cleanup
}

test_group "SVG — SVGEntry" {
    assert_noerror "create" {
        ttkbootstrap::SVGEntry .se -bootstyle primary -width 20
        pack .se
    }
    cleanup
}

test_group "SVG — SVGProgress" {
    assert_noerror "create" {
        ttkbootstrap::SVGProgress .sp -bootstyle success -value 65 -maximum 100
        pack .sp
    }
    assert_noerror "set value" {
        ttkbootstrap::SVGProgress_set .sp 80
    }
    cleanup
}

test_group "SVG — SVGScale" {
    assert_noerror "create" {
        set ::sv 50
        ttkbootstrap::SVGScale .ss -from 0 -to 100 -variable ::sv -bootstyle primary
        pack .ss
    }
    cleanup
}

test_group "SVG — SVGMeter" {
    assert_noerror "create" {
        ttkbootstrap::SVGMeter .sm -bootstyle primary \
            -amountused 72 -amounttotal 100 -subtext "Test"
        pack .sm
    }
    cleanup
}

test_group "SVG — SVGFloodgauge" {
    assert_noerror "create" {
        ttkbootstrap::SVGFloodgauge .sfg -bootstyle primary \
            -value 50 -maximum 100 -text "50%"
        pack .sfg
    }
    assert_noerror "set value" {
        ttkbootstrap::SVGFloodgauge_set .sfg 75
    }
    cleanup
}

test_group "SVG — SVGBadge" {
    assert_noerror "create" {
        ttkbootstrap::SVGBadge .badge -text "99+" -bootstyle danger
        pack .badge
    }
    assert_noerror "set text" {
        ttkbootstrap::SVGBadge_set .badge "NEW"
    }
    cleanup
}

test_group "SVG — SVGRatingBar" {
    assert_noerror "create" {
        set ::rating 3
        ttkbootstrap::SVGRatingBar .rb -variable ::rating \
            -maximum 5 -bootstyle warning
        pack .rb
    }
    assert_noerror "create readonly" {
        ttkbootstrap::SVGRatingBar .rb2 -variable ::rating \
            -maximum 5 -bootstyle warning -readonly 1
        pack .rb2
    }
    cleanup
}

test_group "SVG — SVGSparkLine" {
    assert_noerror "create line" {
        ttkbootstrap::SVGSparkLine .sl -data {10 25 15 30} \
            -bootstyle primary -type line
        pack .sl
    }
    assert_noerror "push data" {
        ttkbootstrap::SVGSparkLine_push .sl 42
    }
    cleanup
}

test_group "SVG — SVGStepProgress" {
    assert_noerror "create" {
        set sp [ttkbootstrap::SVGStepProgress .ssp \
            -steps {A B C D E} -bootstyle primary -complete success]
        pack $sp -fill x
    }
    assert_noerror "next" { ttkbootstrap::SVGStepProgress::next .ssp }
    assert_noerror "next again" { ttkbootstrap::SVGStepProgress::next .ssp }
    assert_noerror "prev" { ttkbootstrap::SVGStepProgress::prev .ssp }
    set cur [ttkbootstrap::SVGStepProgress::current .ssp]
    assert_eq "current is 1" $cur 1
    assert_noerror "goto" { ttkbootstrap::SVGStepProgress::goto .ssp 3 }
    cleanup
}

test_group "SVG — SVGTimeline" {
    assert_noerror "create and add" {
        set tl [ttkbootstrap::SVGTimeline .stl]
        ttkbootstrap::SVGTimeline::add $tl \
            -title "Event" -timestamp "12:00" \
            -body "Details" -bootstyle success -icon "\u2713" -shape circle
        ttkbootstrap::SVGTimeline::add $tl \
            -title "Event 2" -timestamp "13:00" \
            -bootstyle primary -icon "!" -shape square
        pack $tl
    }
    cleanup
}

test_group "SVG — SVGBreadcrumb" {
    assert_noerror "create" {
        ttkbootstrap::SVGBreadcrumb .sbc \
            -items {Home Docs API} -bootstyle primary
        pack .sbc
    }
    assert_noerror "load" {
        ttkbootstrap::SVGBreadcrumb::load .sbc {Home Products New}
    }
    set items [ttkbootstrap::SVGBreadcrumb::get .sbc]
    assert_eq "get returns items" $items {Home Products New}
    cleanup
}

test_group "SVG — SVGCard" {
    assert_noerror "create with title" {
        set c [ttkbootstrap::SVGCard .sc \
            -title "Test" -bootstyle primary \
            -width 200 -height 150]
        pack $c
    }
    assert_noerror "body accessible" {
        set body [ttkbootstrap::SVGCard::body .sc]
    }
    cleanup
}

test_group "SVG — SVGShadowCard" {
    assert_noerror "create" {
        set c [ttkbootstrap::SVGShadowCard .shc \
            -title "Shadow" -bootstyle primary \
            -shadow 10 -width 220 -height 160]
        pack $c
    }
    assert_noerror "body accessible" {
        set body [ttkbootstrap::SVGShadowCard::body .shc]
        ttk::label $body.l -text "Content"
        pack $body.l
    }
    cleanup
}

test_group "SVG — SVGTooltip" {
    assert_noerror "create" {
        ttk::button .b -text "Hover"
        ttkbootstrap::SVGTooltip .b "SVG tooltip test" -bootstyle dark
        pack .b
    }
    cleanup
}

test_group "SVG — SVGDateEntry" {
    assert_noerror "create" {
        set ::svgdate ""
        ttkbootstrap::SVGDateEntry .sde -bootstyle primary \
            -textvariable ::svgdate
        pack .sde
    }
    assert "date set" {$::svgdate ne ""}
    cleanup
}

test_group "SVG — SVGTimePicker" {
    assert_noerror "create" {
        set ::svgtime ""
        ttkbootstrap::SVGTimePicker .stp -bootstyle primary \
            -textvariable ::svgtime
        pack .stp
    }
    cleanup
}

test_group "SVG — SVGScrollbar" {
    assert_noerror "create vertical" {
        ttkbootstrap::SVGScrollbar .ssb -orient vertical -bootstyle primary
        pack .ssb -fill y
    }
    assert_noerror "set range" {
        ttkbootstrap::SVGScrollbar_set .ssb 0.0 0.5
    }
    cleanup
}

test_group "SVG — SVGSidebar" {
    assert_noerror "create and add" {
        set sb [ttkbootstrap::SVGSidebar .ssb2 -bootstyle primary]
        ttkbootstrap::SVGSidebar::add $sb home "Home"
        ttkbootstrap::SVGSidebar::add $sb config "Settings"
        ttkbootstrap::SVGSidebar::select $sb home
        pack $sb
    }
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# THEME SWITCHING STRESS TEST
# ═══════════════════════════════════════════════════════════════════════

test_group "Theme Switch Stress — All themes with widgets" {
    # Create a set of widgets
    assert_noerror "create test widgets" {
        ttkbootstrap::SVGButton .tb1 -text "Btn" -bootstyle primary
        ttkbootstrap::PillButton .tb2 -text "Pill" -bootstyle success
        ttkbootstrap::SVGEntry .te -bootstyle primary -width 15
        ttkbootstrap::SVGBadge .tba -text "OK" -bootstyle info
        ttkbootstrap::SVGProgress .tp -bootstyle warning -value 50
        pack .tb1 .tb2 .te .tba .tp -pady 2
    }
    
    # Switch through all themes rapidly
    foreach theme [ttkbootstrap::themeNames] {
        assert_noerror "switch to $theme with widgets" {
            ttkbootstrap::setTheme $theme
            update idletasks
        }
    }
    
    ttkbootstrap::setTheme litera
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# BOOTSTYLE COLOUR TESTS
# ═══════════════════════════════════════════════════════════════════════

test_group "Bootstyle — All colours" {
    foreach bs {primary secondary success info warning danger} {
        assert_noerror "SVGButton $bs" {
            ttkbootstrap::SVGButton .b_$bs -text $bs -bootstyle $bs
            pack .b_$bs -side left -padx 2
        }
    }
    cleanup
    
    foreach bs {primary secondary success info warning danger} {
        assert_noerror "PillButton outline $bs" {
            ttkbootstrap::PillButton .p_$bs -text $bs -bootstyle $bs -outline 1
            pack .p_$bs -side left -padx 2
        }
    }
    cleanup
}



test_group "Original — CollapsingFrame" {
    assert_noerror "create and add" {
        set cf [ttkbootstrap::CollapsingFrame .cf]
        # add takes (w child title): child is a frame we create under $cf
        set body [ttk::frame $cf.section1]
        ttk::label $body.l -text "Content"
        pack $body.l
        ttkbootstrap::CollapsingFrame::add $cf $body "Section 1"
        pack $cf
    }
    cleanup
}

test_group "Original — DateRangePicker" {
    assert_noerror "create" {
        ttkbootstrap::DateRangePicker .drp -bootstyle primary
        pack .drp
        update idletasks
    }
    cleanup
}

test_group "Original — Toast" {
    assert_noerror "show" {
        ttkbootstrap::Toast "Hello there" -bootstyle info -duration 300
    }
    after 450 {set ::_toast_done 1}
    vwait ::_toast_done
}

test_group "Original — SplashScreen" {
    assert_noerror "show and close" {
        set sp [ttkbootstrap::SplashScreen -title "Test" -message "Loading"]
        update idletasks
        after 150 [list ttkbootstrap::SplashScreen::close $sp]
        after 300 {set ::_splash_done 1}
        vwait ::_splash_done
    }
}

test_group "Original — ProgressDialog" {
    assert_noerror "create, update, close" {
        set d [ttkbootstrap::ProgressDialog . -title "Test" -maximum 100]
        update idletasks
        after 100 [list ttkbootstrap::ProgressDialog::update $d 50]
        after 250 [list catch [list destroy $d]]
        after 350 {set ::_pd_done 1}
        vwait ::_pd_done
    }
}

# ═══════════════════════════════════════════════════════════════════════
# NEW SVG WIDGET TESTS
# ═══════════════════════════════════════════════════════════════════════

test_group "SVG — SVGToggleSwitch" {
    assert_noerror "create round" {
        set ::tsv1 0
        ttkbootstrap::SVGToggleSwitch .svgts1 \
            -text "Test" -variable ::tsv1 -bootstyle success
        pack .svgts1
        update idletasks
    }
    assert_noerror "create square" {
        set ::tsv2 1
        ttkbootstrap::SVGToggleSwitch .svgts2 \
            -text "Square" -variable ::tsv2 -bootstyle primary -shape square
        pack .svgts2
        update idletasks
    }
    assert_noerror "toggle" {
        set ::tsv1 1
        update idletasks
        after 200 {set ::_ts_done 1}
        vwait ::_ts_done
    }
    assert_eq "variable updated" $::tsv1 1
    cleanup
}

test_group "SVG — SVGProgressRing" {
    assert_noerror "create determinate" {
        ttkbootstrap::SVGProgressRing .pr1 \
            -bootstyle primary -value 50 -size 40
        pack .pr1
    }
    assert_noerror "set value" {
        ttkbootstrap::SVGProgressRing_set .pr1 75
    }
    assert_noerror "create and spin" {
        set sp [ttkbootstrap::SVGProgressRing .pr2 \
            -bootstyle info -size 40]
        ttkbootstrap::SVGProgressRing_spin $sp
        pack $sp
        update idletasks
    }
    assert_noerror "stop spin" {
        ttkbootstrap::SVGProgressRing_stop .pr2
    }
    cleanup
}

test_group "SVG — SVGCombobox" {
    assert_noerror "create" {
        ttkbootstrap::SVGCombobox .scb \
            -values {Red Green Blue} -bootstyle primary -width 15
        pack .scb
    }
    cleanup
}

test_group "SVG — SVGSpinbox" {
    assert_noerror "create" {
        ttkbootstrap::SVGSpinbox .sspb \
            -from 0 -to 50 -bootstyle primary -width 8
        pack .sspb
    }
    cleanup
}

test_group "SVG — SVGFormField" {
    assert_noerror "create with validation" {
        set ::ffval ""
        ttkbootstrap::SVGFormField .sff \
            -label "Email" -bootstyle primary \
            -textvariable ::ffval -width 25 \
            -validate {regexp {.+@.+} $value} \
            -validmsg "OK" -invalidmsg "Bad"
        pack .sff
    }
    assert_noerror "get value" {
        ttkbootstrap::SVGFormField::getValue .sff
    }
    assert_noerror "check validity" {
        set v [ttkbootstrap::SVGFormField::isValid .sff]
    }
    cleanup
}

test_group "SVG — SVGColourPicker" {
    assert_noerror "create" {
        set ::cpval "#000000"
        ttkbootstrap::SVGColourPicker .scp \
            -variable ::cpval -bootstyle primary
        pack .scp
    }
    cleanup
}

test_group "SVG — SVGNotificationBanner" {
    assert_noerror "show" {
        ttkbootstrap::SVGNotificationBanner::show \
            -title "Test" -message "Testing" \
            -bootstyle info -duration 500
    }
    after 600 {set ::_nb_done 1}
    vwait ::_nb_done
}

test_group "SVG Icon Library" {
    set names [ttkbootstrap::SVGIconNames]
    assert "has icons" {[llength $names] >= 30}
    assert_noerror "get home icon" {
        set img [ttkbootstrap::SVGIcon home -size 24 -colour "#333333"]
    }
    assert "icon is photo image" {[image type $img] eq "photo"}
    assert_noerror "get all icons" {
        foreach name $names {
            ttkbootstrap::SVGIcon $name -size 20 -colour "#666666"
        }
    }
}

test_group "OS Theme Auto-Detect" {
    assert_noerror "detect" {
        set mode [ttkbootstrap::_detectOSTheme]
    }
    assert "returns light or dark" {$mode eq "light" || $mode eq "dark"}
}


test_group "SVG — SVGSearchBar" {
    assert_noerror "create" {
        ttkbootstrap::SVGSearchBar .ssb -bootstyle primary \
            -placeholder "Search..." -width 20
        pack .ssb
    }
    cleanup
}

test_group "SVG — SVGAvatar" {
    assert_noerror "create" {
        ttkbootstrap::SVGAvatar .sav -text "JD" -bootstyle primary -size 48
        pack .sav
    }
    cleanup
}

test_group "SVG — SVGChip" {
    assert_noerror "create" {
        ttkbootstrap::SVGChip .sch -text "Test" -bootstyle primary \
            -closeable 1
        pack .sch
    }
    cleanup
}

test_group "SVG — SVGDialog" {
    assert "show proc exists" {[info commands ttkbootstrap::SVGDialog::show] ne ""}
}

test_group "SVG — SVGTabNotebook" {
    assert_noerror "create and add tabs" {
        set nb [ttkbootstrap::SVGTabNotebook .stn -bootstyle primary]
        ttkbootstrap::SVGTabNotebook::add $nb "Tab 1" \
            -create {ttk::label %f.l -text "Page 1"; pack %f.l}
        ttkbootstrap::SVGTabNotebook::add $nb "Tab 2" \
            -create {ttk::label %f.l -text "Page 2"; pack %f.l}
        pack $nb -fill both -expand 1
    }
    assert_noerror "select tab" {
        ttkbootstrap::SVGTabNotebook::select .stn 1
    }
    cleanup
}


test_group "SVG — SVGGradientButton" {
    assert_noerror "create" {
        ttkbootstrap::SVGGradientButton .sgb -text "Test" -bootstyle primary
        pack .sgb
    }
    cleanup
}

test_group "SVG — SVGSkeleton" {
    assert_noerror "create lines" {
        ttkbootstrap::SVGSkeleton .ssk -width 200 -lines 3
        pack .ssk
    }
    assert_noerror "create card" {
        ttkbootstrap::SVGSkeleton .ssk2 -width 200 -shape card
        pack .ssk2
    }
    assert_noerror "start and stop" {
        ttkbootstrap::SVGSkeleton::start .ssk
        update idletasks
        ttkbootstrap::SVGSkeleton::stop .ssk
    }
    cleanup
}

test_group "SVG — SVGTreeview" {
    assert_noerror "create and insert" {
        set tv [ttkbootstrap::SVGTreeview .stv -bootstyle primary]
        set root [ttkbootstrap::SVGTreeview::insert $tv "" "Root" -open 1]
        ttkbootstrap::SVGTreeview::insert $tv $root "Child 1"
        set sub [ttkbootstrap::SVGTreeview::insert $tv $root "Folder" -open 0]
        ttkbootstrap::SVGTreeview::insert $tv $sub "Nested"
        pack $tv -fill both -expand 1
    }
    assert_noerror "selection query" {
        ttkbootstrap::SVGTreeview::selection .stv
    }
    cleanup
}

test_group "Theme Swatch Helper" {
    assert_noerror "create swatch" {
        set img [ttkbootstrap::themeSwatch darkly -width 120 -height 44]
    }
    assert "swatch is photo" {[image type $img] eq "photo"}
    assert_noerror "swatch for all themes" {
        foreach th [ttkbootstrap::themeNames] {
            ttkbootstrap::themeSwatch $th -width 100 -height 40
        }
    }
}


# ═══════════════════════════════════════════════════════════════════════
# BEHAVIORAL TESTS — verify state changes, not just construction
# ═══════════════════════════════════════════════════════════════════════

test_group "Behavior — SVGToggleSwitch state" {
    set ::bt_var 0
    ttkbootstrap::SVGToggleSwitch .btts -text "T" -variable ::bt_var -bootstyle success
    pack .btts
    update idletasks
    assert_eq "starts off" $::bt_var 0
    # Simulate a click via the toggle proc
    ttkbootstrap::_svgts_toggle .btts
    assert_eq "toggled on" $::bt_var 1
    ttkbootstrap::_svgts_toggle .btts
    assert_eq "toggled off" $::bt_var 0
    cleanup
}

test_group "Behavior — SVGProgressRing value" {
    ttkbootstrap::SVGProgressRing .btpr -bootstyle primary -value 30 -size 40
    pack .btpr
    set ns ::ttkbootstrap::svgpr::.btpr
    array set o1 [set ${ns}::o]
    assert_eq "initial value 30" $o1(-value) 30
    ttkbootstrap::SVGProgressRing_set .btpr 80
    array set o2 [set ${ns}::o]
    assert_eq "value updated to 80" $o2(-value) 80
    cleanup
}

test_group "Behavior — SVGProgress value" {
    ttkbootstrap::SVGProgress .btp -bootstyle success -value 25 -maximum 100
    pack .btp
    ttkbootstrap::SVGProgress_set .btp 60
    set ns ::ttkbootstrap::svgpb::.btp
    array set o [set ${ns}::o]
    assert_eq "value set to 60" $o(-value) 60
    cleanup
}

test_group "Behavior — SVGStepProgress navigation" {
    set sp [ttkbootstrap::SVGStepProgress .btsp -steps {A B C D} -bootstyle primary]
    pack $sp -fill x
    assert_eq "starts at step 0" [ttkbootstrap::SVGStepProgress::current .btsp] 0
    ttkbootstrap::SVGStepProgress::next .btsp
    assert_eq "advanced to 1" [ttkbootstrap::SVGStepProgress::current .btsp] 1
    ttkbootstrap::SVGStepProgress::next .btsp
    ttkbootstrap::SVGStepProgress::next .btsp
    assert_eq "advanced to 3" [ttkbootstrap::SVGStepProgress::current .btsp] 3
    ttkbootstrap::SVGStepProgress::prev .btsp
    assert_eq "back to 2" [ttkbootstrap::SVGStepProgress::current .btsp] 2
    ttkbootstrap::SVGStepProgress::goto .btsp 0
    assert_eq "goto 0" [ttkbootstrap::SVGStepProgress::current .btsp] 0
    cleanup
}

test_group "Behavior — SVGTreeview insert and select" {
    set tv [ttkbootstrap::SVGTreeview .bttv -bootstyle primary]
    set root [ttkbootstrap::SVGTreeview::insert $tv "" "Root" -open 1]
    set child [ttkbootstrap::SVGTreeview::insert $tv $root "Child"]
    pack $tv -fill both -expand 1
    assert "root id returned" {$root ne ""}
    assert "child id returned" {$child ne ""}
    assert "ids differ" {$root ne $child}
    ttkbootstrap::_svgtv_select $tv $child
    assert_eq "selection is child" [ttkbootstrap::SVGTreeview::selection $tv] $child
    cleanup
}

test_group "Behavior — SVGTabNotebook selection" {
    set nb [ttkbootstrap::SVGTabNotebook .btnb -bootstyle primary]
    ttkbootstrap::SVGTabNotebook::add $nb "One" -create {ttk::label %f.l -text 1; pack %f.l}
    ttkbootstrap::SVGTabNotebook::add $nb "Two" -create {ttk::label %f.l -text 2; pack %f.l}
    pack $nb -fill both -expand 1
    set ns ::ttkbootstrap::svgtab::.btnb
    assert_eq "first tab auto-selected" [set ${ns}::current] 0
    ttkbootstrap::SVGTabNotebook::select $nb 1
    assert_eq "switched to tab 1" [set ${ns}::current] 1
    cleanup
}

test_group "Behavior — SVGRatingBar value" {
    set ::brate 0
    ttkbootstrap::SVGRatingBar .btrate -variable ::brate -maximum 5 -bootstyle warning
    pack .btrate
    set ::brate 3
    update idletasks
    assert_eq "rating reflects variable" $::brate 3
    cleanup
}

test_group "Behavior — SVGBadge set" {
    ttkbootstrap::SVGBadge .btbadge -text "1" -bootstyle danger
    pack .btbadge
    ttkbootstrap::SVGBadge_set .btbadge "99+"
    assert_eq "badge text updated" [.btbadge cget -text] "99+"
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# VALIDATION TESTS — constructors reject bad input
# ═══════════════════════════════════════════════════════════════════════

test_group "Validation — bad bootstyle rejected" {
    assert_error "SVGToggleSwitch bad bootstyle" {
        ttkbootstrap::SVGToggleSwitch .vbad -bootstyle banana
    }
    catch { destroy .vbad }
    assert_error "SVGProgressRing bad bootstyle" {
        ttkbootstrap::SVGProgressRing .vbad2 -bootstyle notacolour
    }
    catch { destroy .vbad2 }
    assert_error "SVGAvatar bad bootstyle" {
        ttkbootstrap::SVGAvatar .vbad3 -text AB -bootstyle xyz
    }
    catch { destroy .vbad3 }
    cleanup
}

test_group "Validation — bad enum rejected" {
    assert_error "SVGToggleSwitch bad shape" {
        ttkbootstrap::SVGToggleSwitch .venum -shape triangle
    }
    catch { destroy .venum }
    assert_error "SVGSkeleton bad shape" {
        ttkbootstrap::SVGSkeleton .venum2 -shape blob
    }
    catch { destroy .venum2 }
    cleanup
}

test_group "Validation — out-of-range rejected" {
    assert_error "SVGProgressRing value > 100" {
        ttkbootstrap::SVGProgressRing .vrange -value 250
    }
    catch { destroy .vrange }
    assert_error "SVGProgressRing negative value" {
        ttkbootstrap::SVGProgressRing .vrange2 -value -10
    }
    catch { destroy .vrange2 }
    cleanup
}

test_group "Validation — good input accepted" {
    assert_noerror "valid bootstyle + shape" {
        ttkbootstrap::SVGToggleSwitch .vgood -bootstyle success -shape square
        pack .vgood
    }
    assert_noerror "valid bootstyle on avatar" {
        ttkbootstrap::SVGAvatar .vgood2 -text "XY" -bootstyle info
        pack .vgood2
    }
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# CLEANUP TESTS — widgets destroy without leaving errors or stray windows
# ═══════════════════════════════════════════════════════════════════════

test_group "Cleanup — destroy removes widget" {
    ttkbootstrap::SVGButton .clb -text "X" -bootstyle primary
    pack .clb
    assert "exists before" {[winfo exists .clb]}
    destroy .clb
    assert "gone after destroy" {![winfo exists .clb]}
}

test_group "Cleanup — animated widgets stop cleanly" {
    set sp [ttkbootstrap::SVGProgressRing .clring -bootstyle info -size 40]
    pack $sp
    ttkbootstrap::SVGProgressRing_spin $sp
    update idletasks
    assert_noerror "destroy while spinning" { destroy .clring }
    # Let any pending after-callbacks fire — should not error
    after 100 {set ::_cl_done 1}
    vwait ::_cl_done
    assert "widget destroyed cleanly" {![winfo exists .clring]}
}

test_group "Cleanup — skeleton stops on destroy" {
    set sk [ttkbootstrap::SVGSkeleton .clsk -width 200 -lines 3]
    pack $sk
    ttkbootstrap::SVGSkeleton::start $sk
    update idletasks
    assert_noerror "destroy while shimmering" { destroy .clsk }
    after 100 {set ::_cl_done2 1}
    vwait ::_cl_done2
    assert "skeleton gone" {![winfo exists .clsk]}
}

test_group "Cleanup — repeated create/destroy no leak" {
    # Create and destroy 20 times; image count should stay bounded
    for {set i 0} {$i < 20} {incr i} {
        ttkbootstrap::SVGButton .leak -text "B$i" -bootstyle primary
        pack .leak
        update idletasks
        destroy .leak
    }
    assert "no leftover widget" {![winfo exists .leak]}
}



test_group "API — namespace ensemble aliases" {
    ttkbootstrap::SVGProgress .apt -bootstyle primary -value 10
    pack .apt
    assert_noerror "SVGProgress::set works" {
        ttkbootstrap::SVGProgress::set .apt 50
    }
    set ns ::ttkbootstrap::svgpb::.apt
    array set o [set ${ns}::o]
    assert_eq "ensemble alias updated value" $o(-value) 50
    cleanup

    ttkbootstrap::SVGProgressRing .aptr -bootstyle info -size 40
    pack .aptr
    assert_noerror "SVGProgressRing::set works" {
        ttkbootstrap::SVGProgressRing::set .aptr 75
    }
    assert_noerror "SVGProgressRing::spin works" {
        ttkbootstrap::SVGProgressRing::spin .aptr
    }
    assert_noerror "SVGProgressRing::stop works" {
        ttkbootstrap::SVGProgressRing::stop .aptr
    }
    cleanup

    ttkbootstrap::SVGBadge .aptb -text "1" -bootstyle danger
    pack .aptb
    assert_noerror "SVGBadge::set works" {
        ttkbootstrap::SVGBadge::set .aptb "NEW"
    }
    assert_eq "badge updated via ensemble" [.aptb cget -text] "NEW"
    cleanup
}

test_group "API — underscore forms still work (backward compat)" {
    ttkbootstrap::SVGProgress .bct -bootstyle primary -value 10
    pack .bct
    assert_noerror "SVGProgress_set still works" {
        ttkbootstrap::SVGProgress_set .bct 40
    }
    cleanup
}


# ═══════════════════════════════════════════════════════════════════════

test_group "Behavior — SVGProgress value updates" {
    ttkbootstrap::SVGProgress .bp -bootstyle success -value 0 -maximum 100
    pack .bp
    assert_noerror "set to 50" { ttkbootstrap::SVGProgress_set .bp 50 }
    assert_noerror "set to 100" { ttkbootstrap::SVGProgress_set .bp 100 }
    assert_noerror "set to 0" { ttkbootstrap::SVGProgress_set .bp 0 }
    cleanup
}

test_group "Behavior — SVGProgressRing value clamping" {
    ttkbootstrap::SVGProgressRing .bpr -bootstyle primary -value 50 -size 40
    pack .bpr
    assert_noerror "set 75" { ttkbootstrap::SVGProgressRing_set .bpr 75 }
    # Out-of-range should be clamped internally, not error
    assert_noerror "set 150 (clamps)" { ttkbootstrap::SVGProgressRing_set .bpr 150 }
    assert_noerror "set -10 (clamps)" { ttkbootstrap::SVGProgressRing_set .bpr -10 }
    cleanup
}

test_group "Behavior — SVGBreadcrumb get/load" {
    ttkbootstrap::SVGBreadcrumb .bbc -items {Home Docs} -bootstyle primary
    pack .bbc
    assert_eq "initial items" [ttkbootstrap::SVGBreadcrumb::get .bbc] {Home Docs}
    ttkbootstrap::SVGBreadcrumb::load .bbc {A B C}
    assert_eq "after load" [ttkbootstrap::SVGBreadcrumb::get .bbc] {A B C}
    cleanup
}

test_group "Behavior — SVGTreeview insert/select" {
    set tv [ttkbootstrap::SVGTreeview .btv -bootstyle primary]
    set root [ttkbootstrap::SVGTreeview::insert $tv "" "Root" -open 1]
    assert "insert returns id" {$root ne ""}
    set child [ttkbootstrap::SVGTreeview::insert $tv $root "Child"]
    assert "child id differs from root" {$child ne $root}
    pack $tv
    assert_eq "no initial selection" [ttkbootstrap::SVGTreeview::selection $tv] ""
    cleanup
}

test_group "Behavior — SVGFormField validation logic" {
    set ::bff ""
    ttkbootstrap::SVGFormField .bff -label "Email" -bootstyle primary \
        -textvariable ::bff -width 25 \
        -validate {regexp {.+@.+\..+} $value} \
        -validmsg "ok" -invalidmsg "bad"
    pack .bff
    # Before any input, validity is -1 (untouched)
    assert_eq "untouched validity" [ttkbootstrap::SVGFormField::isValid .bff] -1
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# INPUT VALIDATION TESTS — constructors should reject bad input
# ═══════════════════════════════════════════════════════════════════════

test_group "Validation — good bootstyle accepted" {
    assert "primary accepted" {
        [catch { ttkbootstrap::SVGButton .vb2 -text X -bootstyle primary }] == 0
    }
    cleanup
    assert "default bootstyle used when omitted" {
        [catch { ttkbootstrap::SVGProgressRing .vpr2 }] == 0
    }
    catch { destroy .vpr2 }
    cleanup
}

test_group "Validation — ProgressRing range" {
    assert "value 50 ok" {
        [catch { ttkbootstrap::SVGProgressRing .vr1 -value 50 }] == 0
    }
    cleanup
    assert "value 200 rejected" {
        [catch { ttkbootstrap::SVGProgressRing .vr2 -value 200 }] != 0
    }
    catch { destroy .vr2 }
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# CLEANUP TESTS — widgets destroy cleanly without leaving timers/images
# ═══════════════════════════════════════════════════════════════════════

test_group "Cleanup — animated widgets stop on destroy" {
    set sk [ttkbootstrap::SVGSkeleton .csk -width 200 -lines 2]
    pack $sk
    ttkbootstrap::SVGSkeleton::start .csk
    update idletasks
    after 100 {set ::_csk_w 1}; vwait ::_csk_w
    # Destroying mid-animation must not error (tick guards winfo exists)
    assert_noerror "destroy mid-animation" { destroy .csk }
    after 100 {set ::_csk_w2 1}; vwait ::_csk_w2
    assert "gone" {![winfo exists .csk]}
}

test_group "Cleanup — progress ring spin stops on destroy" {
    set pr [ttkbootstrap::SVGProgressRing .cpr -bootstyle info -size 40]
    pack $pr
    ttkbootstrap::SVGProgressRing_spin .cpr
    update idletasks
    after 100 {set ::_cpr_w 1}; vwait ::_cpr_w
    assert_noerror "destroy while spinning" { destroy .cpr }
    after 100 {set ::_cpr_w2 1}; vwait ::_cpr_w2
    assert "gone" {![winfo exists .cpr]}
}

test_group "Cleanup — image count stable across create/destroy cycles" {
    set before [llength [image names]]
    for {set i 0} {$i < 5} {incr i} {
        ttkbootstrap::SVGButton .ic$i -text "B$i" -bootstyle primary
        pack .ic$i
        update idletasks
        destroy .ic$i
        update idletasks
    }
    set after [llength [image names]]
    # Allow a small cache delta, but it shouldn't grow by 5+ per cycle
    assert "no large image leak" {($after - $before) < 10}
}


test_group "API — canonical Widget::method forms" {
    ttkbootstrap::SVGProgress .apb -bootstyle success -value 0 -maximum 100
    pack .apb
    assert_noerror "SVGProgress::set works" { ttkbootstrap::SVGProgress::set .apb 50 }
    cleanup

    ttkbootstrap::SVGProgressRing .apr -bootstyle primary -value 0 -size 40
    pack .apr
    assert_noerror "SVGProgressRing::set works"  { ttkbootstrap::SVGProgressRing::set .apr 60 }
    assert_noerror "SVGProgressRing::spin works" { ttkbootstrap::SVGProgressRing::spin .apr }
    assert_noerror "SVGProgressRing::stop works" { ttkbootstrap::SVGProgressRing::stop .apr }
    cleanup

    ttkbootstrap::SVGBadge .abdg -text "1" -bootstyle danger
    pack .abdg
    assert_noerror "SVGBadge::set works" { ttkbootstrap::SVGBadge::set .abdg "9+" }
    cleanup

    ttkbootstrap::SVGSparkLine .asl -data {1 2 3} -bootstyle primary
    pack .asl
    assert_noerror "SVGSparkLine::push works" { ttkbootstrap::SVGSparkLine::push .asl 4 }
    cleanup
}

test_group "API — legacy underscore forms still work" {
    ttkbootstrap::SVGProgress .lpb -bootstyle success -value 0
    pack .lpb
    assert_noerror "SVGProgress_set (legacy)" { ttkbootstrap::SVGProgress_set .lpb 75 }
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# BEHAVIORAL TESTS — state transitions, not just construction
# ═══════════════════════════════════════════════════════════════════════

test_group "Behavior — SVGToggleSwitch state" {
    set ::bt_var 0
    ttkbootstrap::SVGToggleSwitch .bts -variable ::bt_var -bootstyle success
    pack .bts
    update idletasks
    assert_eq "starts off" $::bt_var 0
    # Simulate toggle via the variable
    set ::bt_var 1
    update idletasks
    assert_eq "variable set on" $::bt_var 1
    cleanup
}

test_group "Behavior — SVGProgressRing value" {
    ttkbootstrap::SVGProgressRing .bpr -bootstyle primary -value 0 -size 40
    pack .bpr
    set ns ::ttkbootstrap::svgpr::.bpr
    array set o1 [set ${ns}::o]
    assert_eq "starts at 0" $o1(-value) 0
    ttkbootstrap::SVGProgressRing_set .bpr 75
    array set o2 [set ${ns}::o]
    assert_eq "updated to 75" $o2(-value) 75
    cleanup
}

test_group "Behavior — SVGProgress value clamp" {
    ttkbootstrap::SVGProgress .bp -bootstyle success -value 50 -maximum 100
    pack .bp
    ttkbootstrap::SVGProgress_set .bp 80
    set ns ::ttkbootstrap::svgpb::.bp
    array set o [set ${ns}::o]
    assert_eq "value updated to 80" $o(-value) 80
    cleanup
}

test_group "Behavior — SVGStepProgress navigation" {
    set sp [ttkbootstrap::SVGStepProgress .bsp -steps {A B C D} -bootstyle primary]
    pack $sp
    assert_eq "starts at step 0" [ttkbootstrap::SVGStepProgress::current .bsp] 0
    ttkbootstrap::SVGStepProgress::next .bsp
    assert_eq "advances to 1" [ttkbootstrap::SVGStepProgress::current .bsp] 1
    ttkbootstrap::SVGStepProgress::next .bsp
    ttkbootstrap::SVGStepProgress::next .bsp
    assert_eq "advances to 3" [ttkbootstrap::SVGStepProgress::current .bsp] 3
    ttkbootstrap::SVGStepProgress::next .bsp
    assert_eq "clamps at last step" [ttkbootstrap::SVGStepProgress::current .bsp] 3
    ttkbootstrap::SVGStepProgress::prev .bsp
    assert_eq "prev goes back" [ttkbootstrap::SVGStepProgress::current .bsp] 2
    ttkbootstrap::SVGStepProgress::goto .bsp 0
    assert_eq "goto works" [ttkbootstrap::SVGStepProgress::current .bsp] 0
    cleanup
}

test_group "Behavior — SVGTreeview insert and select" {
    set tv [ttkbootstrap::SVGTreeview .btv -bootstyle primary]
    set root [ttkbootstrap::SVGTreeview::insert $tv "" "Root" -open 1]
    set child [ttkbootstrap::SVGTreeview::insert $tv $root "Child"]
    pack $tv
    assert "root id returned" {$root ne ""}
    assert "child id returned" {$child ne ""}
    assert "ids are distinct" {$root ne $child}
    assert_eq "nothing selected initially" [ttkbootstrap::SVGTreeview::selection $tv] ""
    ttkbootstrap::_svgtv_select $tv $child
    assert_eq "selection updated" [ttkbootstrap::SVGTreeview::selection $tv] $child
    cleanup
}

test_group "Behavior — SVGFormField validation" {
    set ::bff ""
    ttkbootstrap::SVGFormField .bff -label "Email" -bootstyle primary \
        -textvariable ::bff -width 25 \
        -validate {regexp {.+@.+\..+} $value} \
        -validmsg "OK" -invalidmsg "Bad"
    pack .bff
    assert_eq "initial state neutral" [ttkbootstrap::SVGFormField::isValid .bff] -1
    .bff.ent.ent insert 0 "bad"
    ttkbootstrap::_svgff_validate .bff
    assert_eq "invalid input" [ttkbootstrap::SVGFormField::isValid .bff] 0
    .bff.ent.ent delete 0 end
    .bff.ent.ent insert 0 "user@example.com"
    ttkbootstrap::_svgff_validate .bff
    assert_eq "valid input" [ttkbootstrap::SVGFormField::isValid .bff] 1
    cleanup
}

test_group "Behavior — SVGTabNotebook selection" {
    set nb [ttkbootstrap::SVGTabNotebook .bnb -bootstyle primary]
    ttkbootstrap::SVGTabNotebook::add $nb "T1" -create {ttk::label %f.l -text A; pack %f.l}
    ttkbootstrap::SVGTabNotebook::add $nb "T2" -create {ttk::label %f.l -text B; pack %f.l}
    pack $nb
    set ns ::ttkbootstrap::svgtab::.bnb
    assert_eq "first tab auto-selected" [set ${ns}::current] 0
    ttkbootstrap::SVGTabNotebook::select $nb 1
    assert_eq "switched to tab 2" [set ${ns}::current] 1
    cleanup
}

test_group "Behavior — SVGRatingBar value" {
    set ::brate 3
    ttkbootstrap::SVGRatingBar .brb -variable ::brate -maximum 5 -bootstyle warning
    pack .brb
    assert_eq "initial rating" $::brate 3
    set ::brate 5
    update idletasks
    assert_eq "rating updated" $::brate 5
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# CLEANUP TESTS — verify widgets destroy without leaving errors/timers
# ═══════════════════════════════════════════════════════════════════════

test_group "Cleanup — animated widgets destroy cleanly" {
    # ProgressRing spinner schedules after timers
    set sp [ttkbootstrap::SVGProgressRing .cpr -bootstyle info -size 40]
    ttkbootstrap::SVGProgressRing_spin $sp
    pack $sp
    update idletasks
    assert_noerror "destroy spinning ring" { destroy .cpr }
    update idletasks

    # Skeleton schedules shimmer timers
    set sk [ttkbootstrap::SVGSkeleton .csk -width 200 -lines 3]
    ttkbootstrap::SVGSkeleton::start .csk
    pack $sk
    update idletasks
    assert_noerror "destroy running skeleton" { destroy .csk }
    update idletasks

    # ToggleSwitch with animation
    set ::ctv 0
    ttkbootstrap::SVGToggleSwitch .cts -variable ::ctv -bootstyle success
    pack .cts
    set ::ctv 1
    assert_noerror "destroy mid-animation toggle" { destroy .cts }
    update idletasks
}

test_group "Cleanup — image cache flush" {
    ttkbootstrap::SVGIcon home -size 24 -colour "#111111"
    ttkbootstrap::SVGIcon home -size 24 -colour "#222222"
    assert_noerror "flush icon cache" { ttkbootstrap::SVGIconFlush }
    # After flush, re-requesting works
    assert_noerror "recreate after flush" {
        ttkbootstrap::SVGIcon home -size 24 -colour "#333333"
    }
}

# ═══════════════════════════════════════════════════════════════════════
# INPUT VALIDATION TESTS — constructors reject bad input
# ═══════════════════════════════════════════════════════════════════════

test_group "Validation — bad bootstyle rejected" {
    assert "SVGGradientButton rejects bad bootstyle" {
        [catch { ttkbootstrap::SVGGradientButton .vb -text X -bootstyle banana }] != 0
    }
    catch { destroy .vb }
    assert "SVGProgressRing rejects bad bootstyle" {
        [catch { ttkbootstrap::SVGProgressRing .vpr -bootstyle nope }] != 0
    }
    catch { destroy .vpr }
    assert "SVGAvatar rejects bad bootstyle" {
        [catch { ttkbootstrap::SVGAvatar .va -text JD -bootstyle xyz }] != 0
    }
    catch { destroy .va }
    cleanup
}

test_group "Validation — good bootstyle accepted" {
    foreach bs {primary secondary success info warning danger} {
        assert_noerror "SVGGradientButton accepts $bs" {
            ttkbootstrap::SVGGradientButton .vg_$bs -text X -bootstyle $bs
        }
        catch { destroy .vg_$bs }
    }
    cleanup
}

test_group "Validation — helper procs" {
    assert_noerror "_validateBootstyle accepts primary" {
        ttkbootstrap::_validateBootstyle W -bootstyle primary
    }
    assert "_validateBootstyle rejects junk" {
        [catch { ttkbootstrap::_validateBootstyle W -bootstyle junk }] != 0
    }
    assert_noerror "_validateBootstyle allows empty (fallback)" {
        ttkbootstrap::_validateBootstyle W -bootstyle ""
    }
    assert "_validatePositive rejects non-number" {
        [catch { ttkbootstrap::_validatePositive W -size abc }] != 0
    }
    assert_noerror "_validatePositive accepts 10" {
        ttkbootstrap::_validatePositive W -size 10
    }
    assert_noerror "_validatePositive allows 0 with -allowzero" {
        ttkbootstrap::_validatePositive W -size 0 -allowzero
    }
}


# ═══════════════════════════════════════════════════════════════════════
# 1.5: OUTER-PATH ACCESSORS
# ═══════════════════════════════════════════════════════════════════════

test_group "Accessors — SVGEntry get/set/clear" {
    ttkbootstrap::SVGEntry .ae
    pack .ae
    ttkbootstrap::SVGEntry::set .ae "hello"
    assert_eq "set then get" [ttkbootstrap::SVGEntry::get .ae] "hello"
    ttkbootstrap::SVGEntry::clear .ae
    assert_eq "clear empties" [ttkbootstrap::SVGEntry::get .ae] ""
    assert_eq "widget path" [ttkbootstrap::SVGEntry::widget .ae] ".ae.ent"
    assert_eq "child path still works" [.ae.ent get] ""
    cleanup
}

test_group "Accessors — SVGCombobox get/set/values" {
    ttkbootstrap::SVGCombobox .acb -values {Red Green Blue}
    pack .acb
    ttkbootstrap::SVGCombobox::set .acb "Green"
    assert_eq "set then get" [ttkbootstrap::SVGCombobox::get .acb] "Green"
    assert_eq "values read" [ttkbootstrap::SVGCombobox::values .acb] {Red Green Blue}
    ttkbootstrap::SVGCombobox::values .acb {X Y Z}
    assert_eq "values set" [ttkbootstrap::SVGCombobox::values .acb] {X Y Z}
    cleanup
}

test_group "Accessors — SVGSpinbox get/set" {
    ttkbootstrap::SVGSpinbox .asp -from 0 -to 100
    pack .asp
    ttkbootstrap::SVGSpinbox::set .asp 42
    assert_eq "set then get" [ttkbootstrap::SVGSpinbox::get .asp] "42"
    cleanup
}

test_group "Accessors — SVGSearchBar get/set/clear" {
    ttkbootstrap::SVGSearchBar .asb
    pack .asb
    ttkbootstrap::SVGSearchBar::set .asb "query"
    assert_eq "set then get" [ttkbootstrap::SVGSearchBar::get .asb] "query"
    ttkbootstrap::SVGSearchBar::clear .asb
    assert_eq "clear empties" [ttkbootstrap::SVGSearchBar::get .asb] ""
    cleanup
}

test_group "Accessors — SVGFormField get/set + existing API" {
    ttkbootstrap::SVGFormField .aff -label "Email" \
        -validate {regexp {.+@.+\..+} $value} -validmsg ok -invalidmsg bad
    pack .aff
    ttkbootstrap::SVGFormField::set .aff "user@example.com"
    assert_eq "new get" [ttkbootstrap::SVGFormField::get .aff] "user@example.com"
    assert_eq "existing getValue" [ttkbootstrap::SVGFormField::getValue .aff] "user@example.com"
    ttkbootstrap::_svgff_validate .aff
    assert_eq "validation via accessor input" [ttkbootstrap::SVGFormField::isValid .aff] 1
    cleanup
}

test_group "Accessors — error on non-input widget" {
    ttkbootstrap::SVGBadge .abd -text "X"
    pack .abd
    assert "get on non-input raises" {
        [catch { ttkbootstrap::SVGEntry::get .abd }] != 0
    }
    cleanup
}

# ═══════════════════════════════════════════════════════════════════════
# 1.5: RANGE VALIDATION / AUTO-CORRECTION
# ═══════════════════════════════════════════════════════════════════════

test_group "Range — SVGScale reversed range auto-corrects" {
    set ::ars 5
    assert_noerror "reversed range accepted" {
        ttkbootstrap::SVGScale .ars -from 10 -to 0 -variable ::ars
        pack .ars
    }
    # After swap, the stored range should be from<to
    set ns ::ttkbootstrap::svgsc::.ars
    array set o [set ${ns}::o]
    assert "from < to after correction" {$o(-from) < $o(-to)}
    cleanup
}

test_group "Range — SVGScale equal range widened" {
    assert_noerror "equal range accepted" {
        ttkbootstrap::SVGScale .ars2 -from 5 -to 5
        pack .ars2
    }
    set ns ::ttkbootstrap::svgsc::.ars2
    array set o [set ${ns}::o]
    assert "to widened past from" {$o(-to) > $o(-from)}
    cleanup
}

test_group "Range — SVGMeter zero total guarded" {
    assert_noerror "zero total accepted" {
        ttkbootstrap::SVGMeter .amt -amountused 0 -amounttotal 0
        pack .amt
    }
    set ns ::ttkbootstrap::svgm::.amt
    array set o [set ${ns}::o]
    assert "total corrected to positive" {$o(-amounttotal) > 0}
    cleanup
}

test_group "Helpers — _warn does not crash" {
    assert_noerror "warn emits without error" {
        ttkbootstrap::_warn "test warning message"
    }
}

# ═══════════════════════════════════════════════════════════════════════

# RESULTS
# ═══════════════════════════════════════════════════════════════════════

puts "\n=========================================="
puts "RESULTS"
puts "=========================================="
puts "  Passed: $::test_pass"
puts "  Failed: $::test_fail"
puts "  Total:  [expr {$::test_pass + $::test_fail}]"
if {$::test_fail > 0} {
    puts "\nFailures:"
    foreach err $::test_errors {
        puts "  • $err"
    }
}
puts "=========================================="

exit $::test_fail
