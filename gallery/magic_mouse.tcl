# magic_mouse.tcl — ttkbootstrap port of magic_mouse.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

set ASSETS [file join [file dirname [info script]] assets magic_mouse]
source [file join [file dirname [info script]] gallery_icons.tcl]

ttkbootstrap::Window -themename yeti -title "Magic Mouse"

# Load images (regenerated from SVG — no PNG assets required)
foreach {name file} {
    reset        icons8_reset_24px.png
    reset-small  icons8_reset_16px.png
    submit       icons8_submit_progress_24px.png
    question     icons8_question_mark_16px.png
    direction    icons8_move_16px.png
    bluetooth    icons8_bluetooth_2_16px.png
    buy          icons8_buy_26px_2.png
    mouse        magic_mouse.png
} {
    gallery_make_icon img_$name $file
}

proc mm_callback {} {
    tk_messageBox -title "Button callback" -message "You pressed a button."
}

set f [ttk::frame .mm]
pack $f -fill both -expand 1

for {set i 0} {$i < 3} {incr i} { grid columnconfigure $f $i -weight 1 }
grid rowconfigure $f 0 -weight 1

# ── Column 1 ─────────────────────────────────────────────────────────────
set col1 [ttk::frame $f.col1 -padding 10]
grid $col1 -row 0 -column 0 -sticky nsew

# Device info
set dev [ttk::labelframe $col1.dev -text "Device Info" -padding 10]
pack $dev -side top -fill both -expand 1

set dhdr [ttk::frame $dev.hdr -padding 5]
pack $dhdr -fill x

ttk::button $dhdr.reset -image img_reset -style Link.TButton -command mm_callback
pack $dhdr.reset -side left

ttk::label $dhdr.lbl -text "Model 2009, 2xAA Batteries"
pack $dhdr.lbl -side left -fill x -padx 15

ttk::button $dhdr.submit -image img_submit -style Link.TButton -command mm_callback
pack $dhdr.submit -side left

ttk::label $dev.img -image img_mouse
pack $dev.img -fill x

set ::mm_battery 66
ttk::progressbar $dev.pb -variable ::mm_battery
pack $dev.pb -fill x -pady 5 -padx 5

ttk::label $dev.pct -text "Battery is discharging." -font [list Helvetica [ttkbootstrap::_sf 8]] -anchor center
pack $dev.pct -fill x

# License info
set lic [ttk::labelframe $col1.lic -text "License Info" -padding 20]
pack $lic -side top -fill both -expand 1 -pady {10 0}

ttk::label $lic.title -text "Trial Version, 28 days left" -anchor center
pack $lic.title -fill x -pady {0 20}

ttk::label $lic.serial_lbl -text "Mouse serial number:" -anchor center -font [list Helvetica [ttkbootstrap::_sf 8]]
pack $lic.serial_lbl -fill x

ttk::label $lic.serial -text "dtMM2-XYZGHIJKLMN3" \
    -style primary.TLabel -anchor center
pack $lic.serial -fill x -pady {0 20}

ttk::button $lic.buy -image img_buy -text "Buy now" -compound bottom \
    -command mm_callback
pack $lic.buy -padx 10 -fill x

# ── Column 2 ─────────────────────────────────────────────────────────────
set col2 [ttk::frame $f.col2 -padding 10]
grid $col2 -row 0 -column 1 -sticky nsew

# Scrolling
set scroll [ttk::labelframe $col2.scroll -text "Scrolling" -padding {15 10}]
pack $scroll -side top -fill both -expand 1

proc add_check_opt {parent varname text {indent 0} {imgname ""}} {
    set ::$varname 1
    set row [ttk::frame $parent.row_$varname]
    pack $row -fill x -pady 5
    set padx [expr {$indent > 0 ? {20 0} : {0 0}}]
    ttk::checkbutton $row.cb -text $text -variable ::$varname
    pack $row.cb -side left -padx $padx -fill x
    if {$imgname ne ""} {
        ttk::button $row.btn -image $imgname -style Link.TButton -command mm_callback
        pack $row.btn -side right
    }
}

add_check_opt $scroll mm_op1 "Scrolling"
add_check_opt $scroll mm_op2 "No horizontal scrolling" 1 img_question
add_check_opt $scroll mm_op3 "Inverse scroll direction vertically" 1 img_direction
add_check_opt $scroll mm_op4 "Scroll only vertical or horizontal" 1
$scroll.row_mm_op4.cb configure -state disabled

add_check_opt $scroll mm_op5 "Smooth scrolling" 1 img_bluetooth

proc add_speed_row {parent label varscale} {
    set row [ttk::frame $parent.spd_$varscale]
    pack $row -fill x -padx {20 0} -pady 5
    ttk::label $row.lbl -text $label
    pack $row.lbl -side left
    ttk::scale $row.sc -from 1 -to 100 -value 35
    pack $row.sc -side left -fill x -expand 1 -padx 5
    ttk::button $row.btn -image img_reset-small -style Link.TButton -command mm_callback
    pack $row.btn -side left
}

add_speed_row $scroll "Speed:" spd1
add_speed_row $scroll "Sense:" sns1

# 1 Finger Gestures
set fg [ttk::labelframe $col2.fg -text "1 Finger Gestures" -padding {15 10}]
pack $fg -side top -fill both -expand 1 -pady {10 0}

add_check_opt $fg mm_op6 "Fast swipe left/right"
add_check_opt $fg mm_op7 "Swap swipe direction" 1
add_speed_row $fg "Sense:" sns2

# Middle Click
set mc [ttk::labelframe $col2.mc -text "Middle Click" -padding {15 10}]
pack $mc -side top -fill both -expand 1 -pady {10 0}

set mc_cbo [ttk::combobox $mc.cbo \
    -values {"Any 2 finger" "Other 1" "Other 2"} \
    -state readonly]
$mc_cbo current 0
pack $mc_cbo -fill x

# ── Column 3 ─────────────────────────────────────────────────────────────
set col3 [ttk::frame $f.col3 -padding 10]
grid $col3 -row 0 -column 2 -sticky nsew

# 2 Finger Gestures
set tfg [ttk::labelframe $col3.tfg -text "2 Finger Gestures" -padding 10]
pack $tfg -side top -fill both

add_check_opt $tfg mm_op8 "Fast swipe left/right"
add_check_opt $tfg mm_op9 "Swap swipe direction" 1

add_speed_row $tfg "Sense:" sns3

ttk::label $tfg.lbl2up -text "On fast 2 finger up/down swipe:"
pack $tfg.lbl2up -fill x -pady {10 5}

add_check_opt $tfg mm_op10 "Swap swipe direction" 1
add_check_opt $tfg mm_op11 "Swap swipe direction" 1

set tfc [ttk::combobox $tfg.cbo \
    -values {"Cycle Task View | Normal | Desktop View"} \
    -state readonly]
$tfc current 0
pack $tfc -fill x -padx {20 0} -pady 5

add_speed_row $tfg "Sense:" sns4

# Mouse options
set mopt [ttk::labelframe $col3.mopt -text "Mouse Options" -padding {15 10}]
pack $mopt -side top -fill both -expand 1 -pady {10 0}

add_check_opt $mopt mm_op12 "Ignore input if mouse is lifted"
add_check_opt $mopt mm_op13 "Ignore input if mouse is lifted"
add_check_opt $mopt mm_op14 "Ignore input if mouse is lifted"
add_speed_row $mopt "Base speed:" bspd

# Turn off select checkbuttons
foreach v {mm_op2 mm_op9 mm_op12 mm_op13} { set ::$v 0 }

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
