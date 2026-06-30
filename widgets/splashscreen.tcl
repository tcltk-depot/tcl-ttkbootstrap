# =============================================================================
# splashscreen.tcl — Borderless startup splash screen
#
# USAGE
#   set ss [ttkbootstrap::SplashScreen \
#       -title     "My Application" \
#       -version   "v2.1.0" \
#       -message   "Loading modules..." \
#       -bootstyle dark \
#       -progress  1 \
#       -width     400 \
#       -height    240]
#
#   # Update progress
#   ttkbootstrap::SplashScreen::progress $ss 40 "Loading plugins..."
#   ttkbootstrap::SplashScreen::progress $ss 80 "Starting UI..."
#   ttkbootstrap::SplashScreen::progress $ss 100 "Ready"
#
#   # Close when done
#   ttkbootstrap::SplashScreen::close $ss
#
# OPTIONS
#   -title     string   Application name (large, centered)
#   -version   string   Version string shown below title
#   -message   string   Small status text (updated during loading)
#   -bootstyle color    Background colour (default: dark)
#   -progress  0|1      Show progress bar (default: 1)
#   -width     int      Window width  (default: 420)
#   -height    int      Window height (default: 240)
#   -image     photo    Optional logo photo image
#   -alpha     float    Window transparency 0.0-1.0 (default: 0.95)
#   -duration  int      Auto-close after ms (0 = manual close, default: 0)
#
# COMMANDS
#   SplashScreen::progress ss value ?message?  — update progress and message
#   SplashScreen::message  ss text             — update message only
#   SplashScreen::close    ss                  — destroy window
# =============================================================================

namespace eval ttkbootstrap {

proc SplashScreen {args} {
    # Ensure a theme is active — SplashScreen can be called before ttkbootstrap::Window
    if {[ttkbootstrap::currentTheme] eq ""} {
        ttkbootstrap::setTheme flatly
    }
    array set opts {
        -title     "Application"
        -version   {}
        -message   "Loading..."
        -bootstyle dark
        -progress  1
        -width     420
        -height    240
        -image     {}
        -alpha     0.95
        -duration  0
        -parent    {}
    }
    array set opts $args

    set w [toplevel .__tbs_splash_[clock milliseconds] \
        -relief flat -borderwidth 0]
    wm overrideredirect $w 1
    catch { wm attributes $w -topmost 1 }
    catch { wm attributes $w -alpha $opts(-alpha) }
    wm withdraw $w

    set ww [ttkbootstrap::_sp $opts(-width)]
    set wh [ttkbootstrap::_sp $opts(-height)]
    # Centre on the parent window if one is given, otherwise on the screen
    set par $opts(-parent)
    if {$par ne {} && [winfo exists $par]} {
        set px [winfo rootx  $par]
        set py [winfo rooty  $par]
        set pw [winfo width  $par]
        set ph [winfo height $par]
    } else {
        set px 0
        set py 0
        set pw [winfo screenwidth  .]
        set ph [winfo screenheight .]
    }
    set x [expr {$px + ($pw - $ww) / 2}]
    set y [expr {$py + ($ph - $wh) / 2}]
    wm geometry $w "${ww}x${wh}+${x}+${y}"

    set hex [ttkbootstrap::getColor $opts(-bootstyle)]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set sec [ttkbootstrap::Colors::update_hsv $hex -vd 0.2]

    $w configure -background $hex

    set ns ::ttkbootstrap::splash::$w
    namespace eval $ns {}
    set ${ns}::opts [array get opts]

    # Content frame
    set f [frame $w.f -background $hex -borderwidth 0]
    pack $f -fill both -expand 1 -padx [ttkbootstrap::_sp 30] \
        -pady [ttkbootstrap::_sp 20]

    # Optional logo image
    if {$opts(-image) ne {}} {
        label $f.img -image $opts(-image) -background $hex
        pack $f.img -pady [ttkbootstrap::_sp2 0 10]
    }

    # Title
    label $f.title \
        -text       $opts(-title) \
        -background $hex \
        -foreground $fg \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 20] bold] \
        -anchor     center
    pack $f.title -fill x

    # Version
    if {$opts(-version) ne {}} {
        label $f.version \
            -text       $opts(-version) \
            -background $hex \
            -foreground $sec \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                             [ttkbootstrap::_sf 12]] \
            -anchor     center
        pack $f.version -fill x -pady [ttkbootstrap::_sp2 4 0]
    }

    # Spacer
    frame $f.spacer -background $hex -height [ttkbootstrap::_sp 16]
    pack $f.spacer

    # Progress bar
    if {$opts(-progress)} {
        set pb [ttk::progressbar $f.pb \
            -orient  horizontal \
            -value   0 \
            -maximum 100 \
            -style   "success.Horizontal.TProgressbar"]
        pack $pb -fill x -pady [ttkbootstrap::_sp2 0 6]
        set ${ns}::pb $pb
    } else {
        set ${ns}::pb {}
    }

    # Message label
    set mlbl [label $f.msg \
        -text       $opts(-message) \
        -background $hex \
        -foreground $sec \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 11]] \
        -anchor     center]
    pack $mlbl -fill x
    set ${ns}::msg_lbl $mlbl

    # Click to dismiss (optional)
    bind $w <Button-1> [list ttkbootstrap::SplashScreen::close $w]

    wm deiconify $w
    raise $w
    update idletasks

    # Auto-close
    if {$opts(-duration) > 0} {
        after $opts(-duration) [list ttkbootstrap::SplashScreen::close $w]
    }

    return $w
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::SplashScreen {}

proc ttkbootstrap::SplashScreen::progress {w value {msg {}}} {
    set ns ::ttkbootstrap::splash::$w
    if {![namespace exists $ns]} return
    set pb [set ${ns}::pb]
    if {$pb ne {} && [winfo exists $pb]} { $pb configure -value $value }
    if {$msg ne {}} { message $w $msg }
    update idletasks
}

proc ttkbootstrap::SplashScreen::message {w text} {
    set ns ::ttkbootstrap::splash::$w
    if {![namespace exists $ns]} return
    set lbl [set ${ns}::msg_lbl]
    if {[winfo exists $lbl]} { $lbl configure -text $text }
    update idletasks
}

proc ttkbootstrap::SplashScreen::close {w} {
    catch { destroy $w }
    catch { namespace delete ::ttkbootstrap::splash::$w }
}
