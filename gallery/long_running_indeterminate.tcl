# long_running_indeterminate.tcl — ttkbootstrap port of long_running_indeterminate.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename lumen -title "Long Running Task (Indeterminate)"

set ::lri_message ""
set ::lri_tasks_done 0
set ::lri_total_tasks 10

set f [ttk::frame .lri -padding 5 -style info.TFrame]
pack $f -fill both -expand 1

set inner [ttk::frame $f.inner -padding 10]
pack $inner -fill both -expand 1

set desc "Click the START button to begin a long-running\ntask that will last approximately 1 to 15 seconds."
ttk::label $inner.lbl -text $desc -justify left
pack $inner.lbl -fill x -pady 10 -expand 1

ttk::button $inner.btn -text "START" -command lri_start
pack $inner.btn -fill x -pady 10
set ::lri_btn $inner.btn

ttk::progressbar $inner.pb \
    -mode indeterminate \
    -style [ttkbootstrap::bootstyle success TProgressbar]
pack $inner.pb -fill x -expand 1
set ::lri_pb $inner.pb

ttk::label $inner.msg -textvariable ::lri_message -anchor center
pack $inner.msg -fill x -pady 10

proc lri_start {} {
    $::lri_btn configure -state disabled
    $::lri_pb start
    set ::lri_tasks_done 0
    set ::lri_message ""
    lri_run_task 1
}

proc lri_run_task {n} {
    if {$n > $::lri_total_tasks} {
        $::lri_pb stop
        set ::lri_message "All tasks complete!"
        tk_messageBox -title "Alert" -message "Process complete!"
        $::lri_btn configure -state normal
        set ::lri_message ""
        return
    }
    set delay [expr {int(rand() * 1500) + 200}]
    after $delay [list lri_finish_task $n]
}

proc lri_finish_task {n} {
    set ::lri_message "Finished task on Thread: $n"
    lri_run_task [expr {$n + 1}]
}

wm protocol . WM_DELETE_WINDOW { foreach id [after info] { after cancel $id }; _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
