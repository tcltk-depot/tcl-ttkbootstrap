# =============================================================================
# progressdialog.tcl — Modal progress dialog
#
# A themed modal dialog with a title, message, labelled progress bar, and an
# optional Cancel button.  The caller drives progress via the returned handle.
#
# USAGE — basic
#   set pd [ttkbootstrap::ProgressDialog . \
#       -title   "Copying files" \
#       -message "Please wait…" \
#       -maximum 100]
#
#   for {set i 0} {$i <= 100} {incr i 5} {
#       ttkbootstrap::ProgressDialog::update $pd $i "Copied $i of 100 files"
#       update
#       after 50
#   }
#   ttkbootstrap::ProgressDialog::close $pd
#
# USAGE — indeterminate (spinner)
#   set pd [ttkbootstrap::ProgressDialog . \
#       -title   "Connecting…" \
#       -mode    indeterminate]
#   ttkbootstrap::ProgressDialog::start $pd
#   # ... do work ...
#   ttkbootstrap::ProgressDialog::close $pd
#
# USAGE — with cancel button
#   set cancelled 0
#   set pd [ttkbootstrap::ProgressDialog . \
#       -title     "Processing" \
#       -cancelvar cancelled]
#   # Poll $cancelled in your work loop to check if user cancelled.
#
# OPTIONS
#   -title      string   Dialog window title
#   -message    string   Initial message shown above the bar
#   -maximum    int      Maximum progress value (default 100)
#   -mode       determinate|indeterminate  (default determinate)
#   -bootstyle  color    Progress bar colour (default primary)
#   -cancelvar  varname  If set, a Cancel button appears; var set to 1 on click
#   -width      int      Dialog width in pixels (default 360)
#
# COMMANDS
#   ProgressDialog::update pd value ?message?  — set value and optional message
#   ProgressDialog::start  pd                  — start indeterminate animation
#   ProgressDialog::stop   pd                  — stop indeterminate animation
#   ProgressDialog::close  pd                  — destroy the dialog
#   ProgressDialog::message pd text            — update message label only
# =============================================================================

namespace eval ttkbootstrap {

proc ProgressDialog {parent args} {
    array set opts {
        -title     "Progress"
        -message   {}
        -maximum   100
        -mode      determinate
        -bootstyle primary
        -cancelvar {}
        -width     {}
    }
    array set opts $args
    if {$opts(-width) eq {}} { set opts(-width) [ttkbootstrap::_sp 360] }

    set d [toplevel .__tbs_pd_[clock milliseconds] \
        -relief flat -borderwidth [ttkbootstrap::_sp 1]]
    wm title       $d $opts(-title)
    wm resizable   $d 0 0
    wm transient   $d [winfo toplevel $parent]
    wm withdraw    $d

    set bg [ttkbootstrap::getColor bg]
    $d configure -background $bg

    set ns ::ttkbootstrap::pd::$d
    namespace eval $ns {}
    set ${ns}::opts_arr [array get opts]

    set f [ttk::frame $d.f -padding [ttkbootstrap::_sp2 20 16]]
    pack $f -fill both -expand 1

    # Title
    set title_lbl [ttk::label $f.title \
        -text  $opts(-title) \
        -font  [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                     [ttkbootstrap::_sf 12] bold] \
        -anchor w]
    pack $title_lbl -fill x -pady [ttkbootstrap::_sp2 0 4]

    # Message
    set msg_lbl [ttk::label $f.msg \
        -text       $opts(-message) \
        -wraplength [expr {$opts(-width) - [ttkbootstrap::_sp 40]}] \
        -justify    left \
        -anchor     w]
    pack $msg_lbl -fill x -pady [ttkbootstrap::_sp2 0 10]
    set ${ns}::msg_lbl $msg_lbl

    # Progress bar
    set pb [ttk::progressbar $f.pb \
        -orient  horizontal \
        -length  [expr {$opts(-width) - [ttkbootstrap::_sp 40]}] \
        -maximum $opts(-maximum) \
        -mode    $opts(-mode) \
        -style   "$opts(-bootstyle).Horizontal.TProgressbar"]
    pack $pb -fill x -pady [ttkbootstrap::_sp2 0 6]
    set ${ns}::pb $pb

    # Value label (e.g. "42 / 100")
    set val_lbl [ttk::label $f.val \
        -text   {} \
        -anchor e \
        -font   [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                      [ttkbootstrap::_sf 10]]]
    pack $val_lbl -fill x
    set ${ns}::val_lbl $val_lbl

    # Cancel button
    if {$opts(-cancelvar) ne {}} {
        set [set opts(-cancelvar)] 0
        ttk::separator $f.sep -orient horizontal
        pack $f.sep -fill x -pady [ttkbootstrap::_sp 8]
        ttk::button $f.cancel \
            -text    "Cancel" \
            -style   "secondary.Outline.TButton" \
            -command [list apply {{var d} {
                set $var 1
                ttkbootstrap::ProgressDialog::close $d
            }} $opts(-cancelvar) $d]
        pack $f.cancel -anchor e
    }

    # Centre on parent
    update idletasks
    set pw [winfo reqwidth  $d]
    set ph [winfo reqheight $d]
    set px [expr {[winfo rootx $parent] + ([winfo width $parent]  - $pw) / 2}]
    set py [expr {[winfo rooty $parent] + ([winfo height $parent] - $ph) / 2}]
    wm geometry $d "+${px}+${py}"
    wm deiconify $d
    raise $d
    grab set $d

    return $d
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::ProgressDialog {}

proc ttkbootstrap::ProgressDialog::update {d value {msg {}}} {
    set ns ::ttkbootstrap::pd::$d
    if {![namespace exists $ns]} return
    set pb      [set ${ns}::pb]
    set val_lbl [set ${ns}::val_lbl]
    set msg_lbl [set ${ns}::msg_lbl]
    array set o [set ${ns}::opts_arr]
    if {[winfo exists $pb]} {
        $pb configure -value $value
        $val_lbl configure -text "${value} / $o(-maximum)"
    }
    if {$msg ne {} && [winfo exists $msg_lbl]} {
        $msg_lbl configure -text $msg
    }
}

proc ttkbootstrap::ProgressDialog::message {d text} {
    set ns ::ttkbootstrap::pd::$d
    if {![namespace exists $ns]} return
    set msg_lbl [set ${ns}::msg_lbl]
    if {[winfo exists $msg_lbl]} { $msg_lbl configure -text $text }
}

proc ttkbootstrap::ProgressDialog::start {d} {
    set ns ::ttkbootstrap::pd::$d
    if {![namespace exists $ns]} return
    set pb [set ${ns}::pb]
    if {[winfo exists $pb]} { $pb start }
}

proc ttkbootstrap::ProgressDialog::stop {d} {
    set ns ::ttkbootstrap::pd::$d
    if {![namespace exists $ns]} return
    set pb [set ${ns}::pb]
    if {[winfo exists $pb]} { $pb stop }
}

proc ttkbootstrap::ProgressDialog::close {d} {
    catch { grab release $d }
    catch { destroy $d }
    catch { namespace delete ::ttkbootstrap::pd::$d }
}
