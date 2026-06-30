# data_entry.tcl — ttkbootstrap port of data_entry.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename flatly -title "Data Entry"
wm resizable . 0 0

set ::de_name ""
set ::de_address ""
set ::de_phone ""

set f [ttk::frame .de -padding {10 5}]
pack $f -fill both -expand 1

ttk::label $f.hdr -text "Please enter your contact information" -width 50
pack $f.hdr -fill x -pady 10

proc make_entry {parent label varname} {
    set row [ttk::frame $parent.row_$label]
    pack $row -fill x -expand 1 -pady 5
    ttk::label $row.lbl -text [string totitle $label] -width 10
    pack $row.lbl -side left -padx 5
    ttk::entry $row.ent -textvariable $varname
    pack $row.ent -side left -padx 5 -fill x -expand 1
}

make_entry $f name    ::de_name
make_entry $f address ::de_address
make_entry $f phone   ::de_phone

set btns [ttk::frame $f.btns]
pack $btns -fill x -expand 1 -pady {15 10}

ttk::button $btns.cancel \
    -text "Cancel" -width 6 \
    -style [ttkbootstrap::bootstyle danger TButton] \
    -command { _close_gallery }
pack $btns.cancel -side right -padx 5

ttk::button $btns.submit \
    -text "Submit" -width 6 \
    -style [ttkbootstrap::bootstyle success TButton] \
    -command {
        puts "Name:    $::de_name"
        puts "Address: $::de_address"
        puts "Phone:   $::de_phone"
        tk_messageBox -title "Submitted" -message "Data submitted:\nName: $::de_name\nAddress: $::de_address\nPhone: $::de_phone"
    }
pack $btns.submit -side right -padx 5
focus $btns.submit

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
