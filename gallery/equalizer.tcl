# equalizer.tcl — ttkbootstrap port of equalizer.py
# Canvas-based vertical sliders with filled track matching Python appearance
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename litera -title "Equalizer"
wm resizable . 0 0

set f [ttk::frame .eq -padding 20]
pack $f -fill both -expand 1

set bands {VOL 31.25 62.5 125 250 500 1K 2K 4K 8K 16K GAIN}

# Draw/update a band's canvas
proc eq_redraw {band} {
    set c      $::eq_c($band)
    set val    [set ::eq_val_$band]
    set color  $::eq_color($band)
    set y0     $::eq_y0
    set y1     $::eq_y1
    set cx     $::eq_cx
    set knob_r $::eq_knob_r
    set track_w 3
    set bg     [ttkbootstrap::getColor bg]
    set border [ttkbootstrap::getColor border]

    # Y position for knob (val=99 → top=y0, val=1 → bottom=y1)
    set ky [expr {$y0 + int((1.0 - ($val - 1) / 98.0) * ($y1 - $y0))}]

    $c delete all

    # Background track (full height, grey)
    $c create line $cx $y0 $cx $y1 \
        -fill $border -width $track_w -capstyle round

    # Filled track (from bottom up to knob)
    if {$ky < $y1} {
        $c create line $cx $ky $cx $y1 \
            -fill $color -width $track_w -capstyle round
    }

    # Knob circle
    $c create oval \
        [expr {$cx - $knob_r}] [expr {$ky - $knob_r}] \
        [expr {$cx + $knob_r}] [expr {$ky + $knob_r}] \
        -fill $color -outline $color -tags knob
}

proc eq_set_val {band y} {
    set y0 $::eq_y0
    set y1 $::eq_y1
    set ky [expr {max($y0, min($y1, $y))}]
    set val [expr {int((1.0 - double($ky - $y0) / ($y1 - $y0)) * 98) + 1}]
    set ::eq_val_$band $val
    eq_redraw $band
}

proc eq_drag_start {band c y} {
    set ::eq_drag_band $band
    # Bind motion/release at canvas level so drag works even if mouse moves off knob
    bind $c <B1-Motion>       [list eq_drag_move $band $c %y]
    bind $c <ButtonRelease-1> [list eq_drag_end  $band $c]
    eq_set_val $band $y
}

proc eq_drag_move {band c y} {
    eq_set_val $band $y
}

proc eq_drag_end {band c} {
    bind $c <B1-Motion>       {}
    bind $c <ButtonRelease-1> {}
    unset -nocomplain ::eq_drag_band
}

# Slider geometry
set ::eq_knob_r  8
set ::eq_cx      15
set ::eq_cw      30
set ::eq_track_h 150
set ::eq_y0      [expr {$::eq_knob_r + 2}]
set ::eq_y1      [expr {$::eq_y0 + $::eq_track_h}]
set ::eq_ch      [expr {$::eq_y1 + $::eq_knob_r + 4}]

foreach band $bands {
    set val [expr {int(rand() * 98) + 1}]
    set ::eq_val_$band $val

    if {$band in {VOL GAIN}} {
        set ::eq_color($band) [ttkbootstrap::getColor success]
    } else {
        set ::eq_color($band) [ttkbootstrap::getColor info]
    }

    # sanitize for widget path
    set wn [string map {. _ / _} $band]
    set col [ttk::frame $f.col_$wn]
    pack $col -side left -fill y -padx 10

    ttk::label $col.hdr -text $band -anchor center -width 5
    pack $col.hdr -side top -fill x -pady 10

    set c [canvas $col.c \
        -width  $::eq_cw \
        -height $::eq_ch \
        -bg     [ttkbootstrap::getColor bg] \
        -highlightthickness 0 -bd 0]
    pack $c -side top

    set ::eq_c($band) $c

    # Initial draw
    eq_redraw $band

    # Bindings — click on knob to start drag; motion follows at canvas level
    $c bind knob <ButtonPress-1> [list eq_drag_start $band $c %y]

    ttk::label $col.val -textvariable ::eq_val_$band -anchor center -width 5
    pack $col.val -side top -pady {4 0}
}

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
