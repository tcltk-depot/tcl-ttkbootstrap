# file_search_engine.tcl — ttkbootstrap port of file_search_engine.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename journal -title "File Search Engine"

set ::fse_path [pwd]
set ::fse_term "tcl"
set ::fse_type "endswith"
set ::fse_searching 0

set f [ttk::frame .fse -padding 15]
pack $f -fill both -expand 1

# Options labelframe
set opt [ttk::labelframe $f.opt \
    -text "Complete the form to begin your search" \
    -padding 15]
pack $opt -fill x -expand 1 -anchor n

# Path row
set prow [ttk::frame $opt.prow]
pack $prow -fill x -expand 1
ttk::label $prow.lbl -text "Path" -width 8
pack $prow.lbl -side left -padx {15 0}
ttk::entry $prow.ent -textvariable ::fse_path
pack $prow.ent -side left -fill x -expand 1 -padx 5
ttk::button $prow.browse -text "Browse" -width 8 \
    -command {
        set d [tk_chooseDirectory -title "Browse directory"]
        if {$d ne ""} { set ::fse_path $d }
    }
pack $prow.browse -side left -padx 5

# Term row
set trow [ttk::frame $opt.trow]
pack $trow -fill x -expand 1 -pady 15
ttk::label $trow.lbl -text "Term" -width 8
pack $trow.lbl -side left -padx {15 0}
ttk::entry $trow.ent -textvariable ::fse_term
pack $trow.ent -side left -fill x -expand 1 -padx 5
ttk::button $trow.search -text "Search" -width 8 \
    -style [ttkbootstrap::bootstyle primary outline TButton] \
    -command fse_search
pack $trow.search -side left -padx 5

# Type row
set tyrow [ttk::frame $opt.tyrow]
pack $tyrow -fill x -expand 1
ttk::label $tyrow.lbl -text "Type" -width 8
pack $tyrow.lbl -side left -padx {15 0}
ttk::radiobutton $tyrow.contains  -text "Contains"   -variable ::fse_type -value contains
ttk::radiobutton $tyrow.startswith -text "StartsWith" -variable ::fse_type -value startswith
ttk::radiobutton $tyrow.endswith   -text "EndsWith"   -variable ::fse_type -value endswith
pack $tyrow.contains $tyrow.startswith $tyrow.endswith -side left -padx {0 15}

# Results treeview
set tv [ttk::treeview $f.tv \
    -columns {name modified type size path} \
    -show headings \
    ]
pack $tv -fill both -expand 1 -pady 10

$tv heading name     -text "Name"     -anchor w
$tv heading modified -text "Modified" -anchor w
$tv heading type     -text "Type"     -anchor e
$tv heading size     -text "Size"     -anchor e
$tv heading path     -text "Path"     -anchor w
$tv column name     -width [ttkbootstrap::_sp 125] -stretch 0 -anchor w
$tv column modified -width [ttkbootstrap::_sp 140] -stretch 0 -anchor w
$tv column type     -width  50 -stretch 0 -anchor e
$tv column size     -width  50 -stretch 0 -anchor e
$tv column path     -width [ttkbootstrap::_sp 300] -anchor w

# Progressbar
ttk::progressbar $f.pb \
    -mode indeterminate \
    -style [ttkbootstrap::bootstyle success striped TProgressbar]
pack $f.pb -fill x -expand 1

proc fse_convert_size {bytes} {
    set kb [expr {$bytes / 1000}]
    if {$kb > 1000} {
        return [format "%.1f MB" [expr {$kb / 1000.0}]]
    } else {
        return [format "%d KB" $kb]
    }
}

proc fse_search {} {
    set term $::fse_term
    set path $::fse_path
    set type $::fse_type
    if {$term eq ""} return

    # Clear results
    .fse.tv delete [.fse.tv children {}]
    .fse.pb start 10

    # Search in background using after
    set ::fse_files {}
    fse_collect $path $term $type
}

proc fse_collect {path term type} {
    catch {
        foreach f [glob -nocomplain -directory $path *] {
            if {[file isfile $f]} {
                set name [file tail $f]
                set match 0
                if {$type eq "contains"   && [string match "*$term*" $name]} { set match 1 }
                if {$type eq "startswith" && [string match "$term*"  $name]} { set match 1 }
                if {$type eq "endswith"   && [string match "*$term"  $name]} { set match 1 }
                if {$match} {
                    set mtime [file mtime $f]
                    set modified [clock format $mtime -format "%m/%d/%Y %I:%M:%S%p"]
                    set ext [string tolower [file extension $f]]
                    set size [fse_convert_size [file size $f]]
                    .fse.tv insert {} end -values [list \
                        [file rootname $name] $modified $ext $size $f]
                }
            }
        }
        foreach d [glob -nocomplain -directory $path -type d *] {
            fse_collect $d $term $type
        }
    }
    .fse.pb stop
}

wm protocol . WM_DELETE_WINDOW { foreach id [after info] { after cancel $id }; _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
