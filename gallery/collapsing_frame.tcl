# collapsing_frame.tcl — ttkbootstrap port of collapsing_frame.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

set ASSETS [file join [file dirname [info script]] assets]

# CollapsingFrame — a frame with a collapsible section header
namespace eval CollapsingFrame {
    variable row_count
}

proc CollapsingFrame::create {parent} {
    set w [expr {$parent eq "." ? ".cf[incr ::cf_count]" : "$parent.cf[incr ::cf_count]"}]
    ttk::frame $w
    $w configure
    grid columnconfigure $w 0 -weight 1
    set ::cf_rows($w) 0
    set ::cf_imgs_up($w)    [image create photo -file [file join $::ASSETS icons8_double_up_24px.png]]
    set ::cf_imgs_right($w) [image create photo -file [file join $::ASSETS icons8_double_right_24px.png]]
    return $w
}

proc CollapsingFrame::add {cf child title {color primary}} {
    set row $::cf_rows($cf)

    # header frame
    set hf [ttk::frame $cf.hf$row -style ${color}.TFrame]
    grid $hf -row $row -column 0 -sticky ew

    ttk::label $hf.lbl -text $title \
        -style ${color}.Inverse.TLabel
    pack $hf.lbl -side left -fill both -padx 10 -expand 1

    set btn [ttk::button $hf.btn \
        -image $::cf_imgs_up($cf) \
        -style ${color}.TButton \
        -command [list CollapsingFrame::toggle $cf $child]]
    pack $btn -side right

    # store button reference on child
    set ::cf_child_btn($child) $btn
    grid $child -row [expr {$row+1}] -column 0 -sticky nsew

    set ::cf_rows($cf) [expr {$row + 2}]
}

proc CollapsingFrame::toggle {cf child} {
    set btn $::cf_child_btn($child)
    if {[winfo viewable $child]} {
        grid remove $child
        $btn configure -image $::cf_imgs_right($cf)
    } else {
        grid $child
        $btn configure -image $::cf_imgs_up($cf)
    }
}

set ::cf_count 0

ttkbootstrap::Window -themename litera -title "Collapsing Frame"

set cf [CollapsingFrame::create .]
pack $cf -fill both

# Group 1 — primary
set g1 [ttk::frame $cf.g1 -padding 10]
for {set i 1} {$i <= 5} {incr i} {
    set ::g1_opt$i 0
    ttk::checkbutton $g1.cb$i -text "Option $i" -variable ::g1_opt$i
    pack $g1.cb$i -fill x
}
CollapsingFrame::add $cf $g1 "Option Group 1" primary
# Collapse group 1 by default to match Python reference
CollapsingFrame::toggle $cf $g1

# Group 2 — danger
set g2 [ttk::frame $cf.g2 -padding 10]
for {set i 1} {$i <= 5} {incr i} {
    set ::g2_opt$i 0
    ttk::checkbutton $g2.cb$i -text "Option $i" -variable ::g2_opt$i
    pack $g2.cb$i -fill x
}
CollapsingFrame::add $cf $g2 "Option Group 2" danger

# Group 3 — success
set g3 [ttk::frame $cf.g3 -padding 10]
for {set i 1} {$i <= 5} {incr i} {
    set ::g3_opt$i 0
    ttk::checkbutton $g3.cb$i -text "Option $i" -variable ::g3_opt$i
    pack $g3.cb$i -fill x
}
CollapsingFrame::add $cf $g3 "Option Group 3" success

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
