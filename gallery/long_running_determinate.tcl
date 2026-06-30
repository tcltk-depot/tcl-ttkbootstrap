# long_running_determinate.tcl — ttkbootstrap port of long_running_determinate.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename lumen -title "Long Running Task (Determinate)"

set ::lr_message ""
set ::lr_progress 0
set ::lr_tasks_done 0
set ::lr_total_tasks 10

set f [ttk::frame .lr -padding 5 -style info.TFrame]
pack $f -fill both -expand 1

set inner [ttk::frame $f.inner -padding 10]
pack $inner -fill both -expand 1

set desc "Click the START button to begin a long-running\ntask that will last approximately 1 to 15 seconds."
ttk::label $inner.lbl -text $desc -justify left
pack $inner.lbl -fill x -pady 10 -expand 1

ttk::button $inner.btn \
    -text "START" \
    -command lr_start
pack $inner.btn -fill x -pady 10
set ::lr_btn $inner.btn

ttk::progressbar $inner.pb \
    -maximum $::lr_total_tasks \
    -variable ::lr_progress \
    -style [ttkbootstrap::bootstyle success striped TProgressbar]
pack $inner.pb -fill x -expand 1

ttk::label $inner.msg -textvariable ::lr_message -anchor center
pack $inner.msg -fill x -pady 10

proc lr_start {} {
    $::lr_btn configure -state disabled
    set ::lr_tasks_done 0
    set ::lr_progress 0
    set ::lr_message ""
    # Simulate 10 tasks with random durations
    lr_run_task 1
}

proc lr_run_task {n} {
    if {$n > $::lr_total_tasks} {
        set ::lr_progress $::lr_total_tasks
        set ::lr_message "All tasks complete!"
        tk_messageBox -title "Alert" -message "Process complete!"
        $::lr_btn configure -state normal
        set ::lr_message ""
        return
    }
    set delay [expr {int(rand() * 1500) + 200}]
    after $delay [list lr_finish_task $n]
}

proc lr_finish_task {n} {
    set ::lr_progress $n
    set ::lr_message "Finished task on Thread: $n"
    lr_run_task [expr {$n + 1}]
}

wm protocol . WM_DELETE_WINDOW { foreach id [after info] { after cancel $id }; _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
