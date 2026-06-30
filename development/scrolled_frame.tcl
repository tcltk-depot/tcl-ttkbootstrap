# scrolled_frame.tcl — ttkbootstrap port of development/scrolledframe/scrolled.py
# A scrollable frame widget with auto-hide scrollbar on mouse-leave
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

# ── ScrolledFrame ─────────────────────────────────────────────────────────────
# Usage:
#   set sf [ScrolledFrame::new $parent]
#   # pack content into $sf
#   pack [ScrolledFrame::container $sf] -fill both -expand 1
#
namespace eval ScrolledFrame {}

proc ScrolledFrame::new {master args} {
    set container [ttk::frame $master.sfc[incr ::_sf_n] {*}$args]

    set c  [canvas $container.c -highlightthickness 0 -bd 0 \
                -yscrollcommand [list $container.sb set]]
    set sb [ttk::scrollbar $container.sb -orient vertical \
                -command [list $c yview]]

    set inner [ttk::frame $c.inner]
    $c create window 0 0 -window $inner -anchor nw -tags inner

    pack $sb -side right -fill y
    pack $c  -side left  -fill both -expand 1

    # Update scrollregion whenever inner frame resizes
    bind $inner <Configure> [list apply {{c} {
        $c configure -scrollregion [$c bbox all]
        # Make canvas window same width as canvas
        $c itemconfigure inner -width [winfo width $c]
    }} $c]

    bind $c <Configure> [list apply {{c} {
        $c itemconfigure inner -width [winfo width $c]
    }} $c]

    # Mouse wheel
    set ws [tk windowingsystem]
    bind $container <Enter> [list ScrolledFrame::_bind_wheel $c $ws]
    bind $container <Leave> [list ScrolledFrame::_unbind_wheel $c $ws]

    # Auto-hide scrollbar
    place forget $sb
    bind $container <Enter> +[list place $sb -relx 1.0 -rely 0 -relheight 1.0 -anchor ne]
    bind $container <Leave> +[list place forget $sb]

    set ::_sf_inner($container) $inner
    return $inner
}

proc ScrolledFrame::container {inner} {
    return [winfo parent [winfo parent $inner]]
}

proc ScrolledFrame::_bind_wheel {c ws} {
    if {$ws eq "x11"} {
        bind $c <Button-4> [list $c yview scroll -3 units]
        bind $c <Button-5> [list $c yview scroll  3 units]
    } else {
        bind $c <MouseWheel> [list apply {{c d} {
            $c yview scroll [expr {-int($d/120)}] units
        }} $c %D]
    }
}

proc ScrolledFrame::_unbind_wheel {c ws} {
    if {$ws eq "x11"} {
        bind $c <Button-4> {}
        bind $c <Button-5> {}
    } else {
        bind $c <MouseWheel> {}
    }
}

set ::_sf_n 0

# ── Demo ──────────────────────────────────────────────────────────────────────
ttkbootstrap::Window -themename litera -title "Scrolled Frame" -size {400 300}

set sf [ScrolledFrame::new .]
pack [ScrolledFrame::container $sf] -fill both -expand 1

for {set i 1} {$i <= 25} {incr i} {
    ttk::button $sf.btn$i \
        -text "Button $i" \
        -style [ttkbootstrap::bootstyle primary TButton]
    pack $sf.btn$i -fill x -pady 1
}

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
