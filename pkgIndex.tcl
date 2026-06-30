# pkgIndex.tcl — Package index for ttkbootstrap-tcl
#
# Usage:
#   lappend auto_path /path/to/ttkbootstrap-tcl
#   package require ttkbootstrap
#
# Requires Tcl/Tk 9.0+ (uses Tk's built-in SVG image format).
if {![package vsatisfies [package provide Tcl] 9.0-]} return
package ifneeded ttkbootstrap 1.5.0 \
    [list source [file join $dir ttkbootstrap.tcl]]
