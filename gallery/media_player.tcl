# media_player.tcl — ttkbootstrap port of media_player.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

set ASSETS [file join [file dirname [info script]] assets]
source [file join [file dirname [info script]] gallery_icons.tcl]

ttkbootstrap::Window -themename yeti -title "Media Player" -size {600 600} -size {600 500}

set ::mp_elapsed 0.0
set ::mp_remain  190.0
set ::mp_elapsed_str "00:00"
set ::mp_remain_str  "03:10"
set ::mp_header "Open a file to begin playback"

set f [ttk::frame .mp]
pack $f -fill both -expand 1

# Header
ttk::label $f.hdr \
    -textvariable ::mp_header \
    -style light.Inverse.TLabel \
    -padding 10
pack $f.hdr -fill x

# Media image — flat SVG backdrop (nanosvg has no gradients) standing in for
# the original album-art PNG: a panel with a disc and a music note.
set _mpw [ttkbootstrap::_sp 600]
set _mph [ttkbootstrap::_sp 350]
set _mpbg  [ttkbootstrap::getColor secondary]
set _mpfg  [ttkbootstrap::getColor light]
set _mpac  [ttkbootstrap::getColor primary]
set _cx [expr {$_mpw/2}]; set _cy [expr {$_mph/2}]
set _mpsvg "<svg xmlns='http://www.w3.org/2000/svg' width='$_mpw' height='$_mph'>\
<rect width='$_mpw' height='$_mph' fill='$_mpbg'/>\
<circle cx='$_cx' cy='$_cy' r='[expr {$_mph/3}]' fill='$_mpac'/>\
<circle cx='$_cx' cy='$_cy' r='[expr {$_mph/16}]' fill='$_mpbg'/>\
<g fill='$_mpfg'>\
<rect x='[expr {$_cx-2}]' y='[expr {$_cy-60}]' width='6' height='70'/>\
<rect x='[expr {$_cx+30}]' y='[expr {$_cy-70}]' width='6' height='70'/>\
<rect x='[expr {$_cx-2}]' y='[expr {$_cy-70}]' width='38' height='10'/>\
<ellipse cx='[expr {$_cx-6}]' cy='[expr {$_cy+12}]' rx='12' ry='9'/>\
<ellipse cx='[expr {$_cx+26}]' cy='[expr {$_cy+2}]' rx='12' ry='9'/>\
</g></svg>"
set mp_bg [image create photo -data $_mpsvg -format svg]
set mc [canvas $f.media -height [ttkbootstrap::_sp 350] -highlightthickness 0 -bd 0 \
    -bg [ttkbootstrap::getColor bg]]
$mc create image 0 0 -image $mp_bg -anchor nw
pack $mc -fill x -pady 0

# Progress bar row
set prow [ttk::frame $f.prow]
pack $prow -fill x -expand 1 -pady 10

ttk::label $prow.elapsed -textvariable ::mp_elapsed_str
pack $prow.elapsed -side left -padx 10

ttk::scale $prow.scale \
    -orient horizontal \
    -from 0 -to 1 \
    -command mp_on_progress
pack $prow.scale -side left -fill x -expand 1

ttk::label $prow.remain -textvariable ::mp_remain_str
pack $prow.remain -side left -padx 10

proc mp_on_progress {val} {
    set total [expr {$::mp_elapsed + $::mp_remain}]
    set elapse [expr {int($val * $total)}]
    set remain [expr {$total - $elapse}]
    set ::mp_elapsed_str [format "%02d:%02d" [expr {$elapse/60}] [expr {$elapse%60}]]
    set ::mp_remain_str  [format "%02d:%02d" [expr {int($remain)/60}] [expr {int($remain)%60}]]
    set ::mp_elapsed $elapse
    set ::mp_remain  $remain
}

# Button row — blue buttons with white SVG icons
set brow [ttk::frame $f.brow]
pack $brow -fill x -expand 1

# White icons for blue buttons
set mp_clr white
set mp_sz  32

foreach {iname svg_body} [list \
    skip_back "<svg xmlns='http://www.w3.org/2000/svg' width='$mp_sz' height='$mp_sz' viewBox='0 0 24 24'><polygon points='19,5 9,12 19,19' fill='$mp_clr'/><rect x='5' y='5' width='3' height='14' fill='$mp_clr'/></svg>" \
    play      "<svg xmlns='http://www.w3.org/2000/svg' width='$mp_sz' height='$mp_sz' viewBox='0 0 24 24'><polygon points='6,4 20,12 6,20' fill='$mp_clr'/></svg>" \
    skip_fwd  "<svg xmlns='http://www.w3.org/2000/svg' width='$mp_sz' height='$mp_sz' viewBox='0 0 24 24'><polygon points='5,5 15,12 5,19' fill='$mp_clr'/><rect x='16' y='5' width='3' height='14' fill='$mp_clr'/></svg>" \
    pause     "<svg xmlns='http://www.w3.org/2000/svg' width='$mp_sz' height='$mp_sz' viewBox='0 0 24 24'><rect x='6'  y='5' width='4' height='14' fill='$mp_clr'/><rect x='14' y='5' width='4' height='14' fill='$mp_clr'/></svg>" \
    stop      "<svg xmlns='http://www.w3.org/2000/svg' width='$mp_sz' height='$mp_sz' viewBox='0 0 24 24'><rect x='5' y='5' width='14' height='14' fill='$mp_clr'/></svg>" \
    next_trk  "<svg xmlns='http://www.w3.org/2000/svg' width='$mp_sz' height='$mp_sz' viewBox='0 0 24 24'><polygon points='5,5 15,12 5,19' fill='$mp_clr'/><polygon points='13,5 23,12 13,19' fill='$mp_clr'/></svg>" \
] {
    catch { image delete ::mp_img::$iname }
    image create photo ::mp_img::$iname -data $svg_body -format svg
}

# Popup: brief message near the button showing what was pressed
proc mp_popup {widget msg} {
    set x [expr {[winfo rootx $widget] + [winfo width $widget]/2}]
    set y [expr {[winfo rooty $widget] - 10}]

    catch { destroy .mp_popup }
    set p [toplevel .mp_popup -relief solid -borderwidth 1]
    wm overrideredirect $p 1
    wm withdraw $p

    set bg [ttkbootstrap::getColor primary]
    set fg [ttkbootstrap::_contrastFg $bg]
    set fnm [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]

    frame $p.f -bg $bg -padx 12 -pady 6
    pack  $p.f -fill both -expand 1
    label $p.f.l -text $msg -bg $bg -fg $fg \
        -font [list $fnm [ttkbootstrap::_sf 10] bold]
    pack $p.f.l

    update idletasks
    set pw [winfo reqwidth  $p]
    set ph [winfo reqheight $p]
    wm geometry $p +[expr {$x - $pw/2}]+[expr {$y - $ph}]
    wm deiconify $p
    raise $p

    after 1200 { catch { destroy .mp_popup } }
}

foreach {iname tip} {
    skip_back "Skip Back"
    play      "Play"
    skip_fwd  "Skip Forward"
    pause     "Pause"
    stop      "Stop"
    next_trk  "Next Track"
} {
    set cmd [list mp_popup $brow.b$iname "You pressed: $tip"]
    ttk::button $brow.b$iname \
        -image   ::mp_img::$iname \
        -style   "primary.TButton" \
        -padding 8 \
        -command $cmd
    pack $brow.b$iname -side left -fill x -expand 1
}

# Set default scale position
$prow.scale set 0.35
mp_on_progress 0.35

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
