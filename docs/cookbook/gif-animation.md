# Animated GIF

Play an animated GIF by extracting individual frames and cycling through them with `after`.

## Source: [cookbook/animated_gif.tcl](../../cookbook/animated_gif.tcl)

## How it works

Tk's `image create photo` can extract individual frames from an animated GIF using the `-format "gif -index N"` option:

```tcl
# Load frame N from an animated GIF
set img [image create photo]
$img configure -file path/to/spinner.gif -format "gif -index 0"
```

When there are no more frames, the command raises an error — we catch that to know when we've loaded all frames.

## Full example

```tcl
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename superhero -title "Animated GIF" -size {400 300}

set gif_path [file join [file dirname [info script]] assets/spinners.gif]

# Load all frames
set ::frames {}
set ::delay  80
for {set i 0} {1} {incr i} {
    set img [image create photo]
    if {[catch {$img configure -file $gif_path -format "gif -index $i"}]} {
        image delete $img
        break
    }
    lappend ::frames $img
}

set ::idx 0

# Display label
ttk::label .gif -image [lindex $::frames 0]
pack .gif -fill both -expand 1

# Animation loop
proc next_frame {} {
    set n [llength $::frames]
    set ::idx [expr {($::idx + 1) % $n}]
    .gif configure -image [lindex $::frames $::idx]
    after $::delay next_frame
}

after $::delay next_frame
vwait forever
```

## Notes

- The frame delay is read from the GIF's duration metadata if available. This example uses a fixed 80ms fallback.
- Transparent GIFs work because Tk's photo image supports transparency natively in PNG and GIF format.
- For very large GIFs (100+ frames), pre-loading all frames uses memory but gives smooth playback. For memory-constrained situations you could load frames on demand.
