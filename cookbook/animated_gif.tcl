# animated_gif.tcl — ttkbootstrap port of cookbook/animated_gif.py
# Plays an animated GIF by cycling through frames with 'after'
# Reference: https://dribbble.com/shots/1237618--Gif-Spinner
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename superhero -title "Animated GIF" -size {400 300}

set ASSETS [file join [file dirname [info script]] assets]

# ── Load all frames from the GIF ─────────────────────────────────────────────
# Tk can load individual frames from an animated GIF using the -format option
set gif_path [file join $ASSETS spinners.gif]

# Load each frame — Tk supports "gif -index N" to extract individual frames
set ::gif_frames {}
set ::gif_delay  80  ;# fallback frame delay in ms

for {set i 0} {1} {incr i} {
    set img [image create photo]
    if {[catch {$img configure -file $gif_path -format "gif -index $i"} err]} {
        image delete $img
        break
    }
    lappend ::gif_frames $img
}

if {[llength $::gif_frames] == 0} {
    # Fallback: load as single image
    set img [image create photo -file $gif_path]
    lappend ::gif_frames $img
}

set ::gif_index 0

# ── Widget ────────────────────────────────────────────────────────────────────
set f [ttk::frame .gif -padding 10]
pack $f -fill both -expand 1

ttk::label $f.img -image [lindex $::gif_frames 0]
pack $f.img -fill both -expand 1

# ── Animation loop ────────────────────────────────────────────────────────────
proc next_frame {} {
    set n [llength $::gif_frames]
    if {$n == 0} return
    set ::gif_index [expr {($::gif_index + 1) % $n}]
    .gif.img configure -image [lindex $::gif_frames $::gif_index]
    after $::gif_delay next_frame
}

after $::gif_delay next_frame

wm protocol . WM_DELETE_WINDOW {
    foreach id [after info] { after cancel $id }
    exit
}
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
