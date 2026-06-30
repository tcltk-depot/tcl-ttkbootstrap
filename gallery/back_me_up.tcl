# back_me_up.tcl — ttkbootstrap port of back_me_up.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

set ASSETS [file join [file dirname [info script]] assets]
source [file join [file dirname [info script]] gallery_icons.tcl]

ttkbootstrap::Window -themename litera -title "Back Me Up"

# Load images (regenerated from SVG — no PNG assets required). Names ending in
# -light get a white glyph (for dark buttons); -dark/others get the theme fg.
foreach {name file} {
    props-dark    icons8_settings_24px.png
    props-light   icons8_settings_24px_2.png
    add-dark      icons8_add_folder_24px.png
    add-light     icons8_add_book_24px.png
    stop-bk-dark  icons8_cancel_24px.png
    stop-bk-light icons8_cancel_24px_1.png
    play          icons8_play_24px_1.png
    refresh       icons8_refresh_24px_1.png
    stop-dark     icons8_stop_24px.png
    stop-light    icons8_stop_24px_1.png
    folder        icons8_opened_folder_24px.png
    logo          backup.png
} {
    set col ""
    if {[string match *-light $name]} { set col white }
    gallery_make_icon img_$name $file $col
}
gallery_make_icon img_arrow_up    icons8_double_up_24px.png
gallery_make_icon img_arrow_right icons8_double_right_24px.png

set f [ttk::frame .bmu]
pack $f -fill both -expand 1

# ── Collapsing Frame helper (simplified inline) ────────────────────────────
set ::cf_seq 0
proc make_cf {parent} {
    set w $parent.cf[incr ::cf_seq]
    ttk::frame $w
    $w configure
    grid columnconfigure $w 0 -weight 1
    set ::cf_rows($w) 0
    return $w
}

proc cf_add {cf child title {color secondary} {textvar ""}} {
    set row $::cf_rows($cf)
    set hf [ttk::frame $cf.hf$row -style ${color}.TFrame]
    grid $hf -row $row -column 0 -sticky ew
    if {$textvar ne ""} {
        ttk::label $hf.lbl -textvariable $textvar -style ${color}.Inverse.TLabel
    } else {
        ttk::label $hf.lbl -text $title -style ${color}.Inverse.TLabel
    }
    pack $hf.lbl -side left -fill both -padx 10
    set btn [ttk::button $hf.btn \
        -image img_arrow_up \
        -style ${color}.TButton \
        -command [list cf_toggle $cf $child]]
    pack $btn -side right
    set ::cf_child_btn($child) $btn
    set ::cf_child_cf($child) $cf
    grid $child -row [expr {$row+1}] -column 0 -sticky nsew
    set ::cf_rows($cf) [expr {$row + 2}]
}

proc cf_toggle {cf child} {
    set btn $::cf_child_btn($child)
    if {[winfo viewable $child]} {
        grid remove $child
        $btn configure -image img_arrow_right
    } else {
        grid $child
        $btn configure -image img_arrow_up
    }
}

# ── Button bar ─────────────────────────────────────────────────────────────
set bbar [ttk::frame $f.bbar -style primary.TFrame]
pack $bbar -fill x -pady 1 -side top

foreach {img txt msg} {
    img_add-light   "New backup set" "Adding new backup"
    img_play        "Backup"         "Backing up..."
    img_refresh     "Refresh"        "Refreshing..."
    img_stop-light  "Stop"           "Stopping backup."
    img_props-light "Settings"       "Changing settings"
} {
    set m $msg
    ttk::button $bbar.b[incr ::bmu_bi] \
        -image $img -text $txt \
        -compound left \
        -command [list tk_messageBox -title "Info" -message $m]
    pack $bbar.b$::bmu_bi -side left -ipadx 5 -ipady 5 -padx {1 0} -pady 1
}

# ── Left panel ─────────────────────────────────────────────────────────────
set left [ttk::frame $f.left -style bg.TFrame]
pack $left -side left -fill y

# Backup summary
set bus_cf [make_cf $left]
pack $bus_cf -fill x -pady 1

set bus_frm [ttk::frame $bus_cf.frm -padding 5]
grid columnconfigure $bus_frm 1 -weight 1

set ::bmu_dest "d:/test/"
set ::bmu_lastrun "14.06.2021 19:34:43"
set ::bmu_identical "15%"

foreach {row lbl varname} {
    0 "Destination:"     ::bmu_dest
    1 "Last Run:"        ::bmu_lastrun
    2 "Files Identical:" ::bmu_identical
} {
    ttk::label $bus_frm.lbl$row -text $lbl
    grid $bus_frm.lbl$row -row $row -column 0 -sticky w -pady 2
    ttk::label $bus_frm.val$row -textvariable $varname
    grid $bus_frm.val$row -row $row -column 1 -sticky ew -padx 5 -pady 2
}

ttk::separator $bus_frm.sep -style secondary.TSeparator
grid $bus_frm.sep -row 3 -column 0 -columnspan 2 -pady 10 -sticky ew

ttk::button $bus_frm.props \
    -text "Properties" -image img_props-dark -compound left \
    -style Link.TButton \
    -command { tk_messageBox -message "Changing properties" }
grid $bus_frm.props -row 4 -column 0 -columnspan 2 -sticky w

ttk::button $bus_frm.add \
    -text "Add to backup" -image img_add-dark -compound left \
    -style Link.TButton \
    -command { tk_messageBox -message "Adding to backup" }
grid $bus_frm.add -row 5 -column 0 -columnspan 2 -sticky w

cf_add $bus_cf $bus_frm "Backup Summary" secondary

# Backup status
set status_cf [make_cf $left]
pack $status_cf -fill both -pady 1

set status_frm [ttk::frame $status_cf.frm -padding 10]
grid columnconfigure $status_frm 1 -weight 1

set ::bmu_prog_msg "Backing up..."
set ::bmu_prog_val 71
set ::bmu_started  "Started at: 14.06.2021 19:34:56"
set ::bmu_elapsed  "Elapsed: 1 sec"
set ::bmu_left     "Left: 0 sec"

ttk::label $status_frm.pmsg -textvariable ::bmu_prog_msg -font [list Helvetica [ttkbootstrap::_sf 10] bold]
grid $status_frm.pmsg -row 0 -column 0 -columnspan 2 -sticky w

ttk::progressbar $status_frm.pb \
    -variable ::bmu_prog_val \
    -style [ttkbootstrap::bootstyle success TProgressbar]
grid $status_frm.pb -row 1 -column 0 -columnspan 2 -sticky ew -pady {10 5}

foreach {row var} {2 ::bmu_started 3 ::bmu_elapsed 4 ::bmu_left} {
    ttk::label $status_frm.lbl$row -textvariable $var
    grid $status_frm.lbl$row -row $row -column 0 -columnspan 2 -sticky ew -pady 2
}

ttk::separator $status_frm.sep -style secondary.TSeparator
grid $status_frm.sep -row 5 -column 0 -columnspan 2 -pady 10 -sticky ew

ttk::button $status_frm.stop \
    -text "Stop" -image img_stop-bk-dark -compound left \
    -style Link.TButton \
    -command { tk_messageBox -message "Stopping backup" }
grid $status_frm.stop -row 6 -column 0 -columnspan 2 -sticky w

ttk::separator $status_frm.sep2 -style secondary.TSeparator
grid $status_frm.sep2 -row 7 -column 0 -columnspan 2 -pady 10 -sticky ew

set ::bmu_curfile "Uploading: d:/test/settings.txt"
ttk::label $status_frm.curfile -textvariable ::bmu_curfile
grid $status_frm.curfile -row 8 -column 0 -columnspan 2 -pady 2 -sticky ew

cf_add $status_cf $status_frm "Backup Status" secondary

# Logo
ttk::label $left.logo -image img_logo
pack $left.logo -side bottom

# ── Right panel ─────────────────────────────────────────────────────────────
set right [ttk::frame $f.right -padding {2 1}]
pack $right -side right -fill both -expand 1

# File input row
set browse_frm [ttk::frame $right.bf]
pack $browse_frm -side top -fill x -padx 2 -pady 1

set ::bmu_folder "D:/text/myfiles/top-secret/samples/"
ttk::entry $browse_frm.ent -textvariable ::bmu_folder
pack $browse_frm.ent -side left -fill x -expand 1

ttk::button $browse_frm.btn \
    -image img_folder \
    -style [ttkbootstrap::bootstyle secondary link TButton] \
    -command {
        set d [tk_chooseDirectory]
        if {$d ne ""} { set ::bmu_folder $d }
    }
pack $browse_frm.btn -side right

# Treeview
set tv [ttk::treeview $right.tv \
    -columns {name state modified lastrun size} \
    -show headings \
    -height 5]
foreach {col w} {name 150 state 120 modified 140 lastrun 140 size 60} {
    $tv heading $col -text [string totitle $col] -anchor w
    $tv column  $col -width $w -stretch [expr {$col eq "name" ? 1 : 0}]
}
pack $tv -fill x -pady 1

# Seed treeview with sample data
for {set x 20} {$x < 35} {incr x} {
    set result [expr {rand() > 0.5 ? "Backed Up" : "Missed in Destination"}]
    set ts [clock format [clock seconds] -format "%d.%m.%Y %H:%M:%S"]
    $tv insert {} end -values [list \
        "sample_file_$x.txt" $result $ts $ts "[expr {$x/3}] MB"]
}
$tv selection set [lindex [$tv children {}] 0]

# Scrolling log (collapsible)
set log_cf [make_cf $right]
pack $log_cf -fill both -expand 1

set log_frm [ttk::frame $log_cf.frm -padding 1]
set log_txt [text $log_frm.txt -height 8 -wrap word]
set log_sb  [ttk::scrollbar $log_frm.sb -command "$log_frm.txt yview"]
$log_txt configure -yscrollcommand "$log_frm.sb set"
pack $log_sb -side right -fill y
pack $log_txt -side left -fill both -expand 1

set ::bmu_scroll_msg "Log: Backing up... \[Uploading file: D:/sample_file_35.txt\]"
for {set x 20} {$x < 35} {incr x} {
    $log_txt insert end "19:34:$x\t\t Uploading: D:/file_$x.txt\n"
    $log_txt insert end "19:34:$x\t\t Upload complete.\n"
}

cf_add $log_cf $log_frm "Log" secondary ::bmu_scroll_msg

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
