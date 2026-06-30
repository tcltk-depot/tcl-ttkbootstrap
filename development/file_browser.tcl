# file_browser.tcl — ttkbootstrap port of development/filedialogs/filedialog_methods.py
# A file browser with sidebar shortcuts, treeview contents, and navigation
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename darkly -title "File Browser" -size {900 600}

set ASSETS [file join [file dirname [info script]] filedialogs/assets]

# ── Load sidebar icons ────────────────────────────────────────────────────────
foreach {name file} {
    home      icons8_home_40px.png
    user      icons8_user_folder_40px.png
    desktop   icons8_desktop_40px.png
    documents icons8_documents_folder_40px.png
    downloads icons8_downloads_folder_40px.png
    music     icons8_music_folder_40px.png
    pictures  icons8_pictures_folder_40px.png
    videos    icons8_movies_folder_40px.png
    folder    icons8_folder_40px.png
    file      icons8_file_40px.png
} {
    if {[file exists [file join $ASSETS $file]]} {
        image create photo img_$name -file [file join $ASSETS $file]
    } else {
        image create photo img_$name
    }
}

set ::fb_path [file normalize ~]

# ── Layout ────────────────────────────────────────────────────────────────────
set main [ttk::frame .fb]
pack $main -fill both -expand 1

# Toolbar
set toolbar [ttk::frame $main.toolbar -padding {5 3}]
pack $toolbar -fill x -side top

ttk::button $toolbar.up -text "⬆ Up" -width 6 \
    -style [ttkbootstrap::bootstyle secondary TButton] \
    -command fb_go_up
pack $toolbar.up -side left -padx {0 5}

set ::fb_path_var $::fb_path
ttk::entry $toolbar.path -textvariable ::fb_path_var
pack $toolbar.path -side left -fill x -expand 1 -padx 5

ttk::button $toolbar.go -text "Go" -width 4 \
    -style [ttkbootstrap::bootstyle primary TButton] \
    -command { fb_load $::fb_path_var }
pack $toolbar.go -side left

bind $toolbar.path <Return> { fb_load $::fb_path_var }

ttk::separator $main.sep -orient horizontal
pack $main.sep -fill x

# Body: sidebar + treeview
set body [ttk::frame $main.body]
pack $body -fill both -expand 1

# Sidebar
set sidebar [ttk::frame $body.sidebar -padding 5 -width 160]
pack $sidebar -side left -fill y
$body.sidebar configure -style secondary.TFrame

ttk::label $sidebar.hdr \
    -text "Quick Access" \
    -style secondary.Inverse.TLabel \
    -font {TkDefaultFont 9 bold}
pack $sidebar.hdr -fill x -pady {0 8}

# Treeview
set tv [ttk::treeview $body.tv \
    -columns {path modified type size} \
    -show {tree headings} \
    -selectmode browse]

set sb_y [ttk::scrollbar $body.sby -orient vertical   -command "$tv yview"]
set sb_x [ttk::scrollbar $body.sbx -orient horizontal -command "$tv xview"]
$tv configure -yscrollcommand "$sb_y set" -xscrollcommand "$sb_x set"

$tv heading #0       -text "Name"          -anchor w
$tv heading modified -text "Date Modified" -anchor w
$tv heading type     -text "Type"          -anchor w
$tv heading size     -text "Size"          -anchor e

$tv column #0       -width 300
$tv column modified -width 150 -stretch 0
$tv column type     -width 120 -stretch 0
$tv column size     -width 80  -stretch 0 -anchor e

$tv tag configure dir  -image img_folder
$tv tag configure file -image img_file

pack $sb_y  -side right  -fill y
pack $sb_x  -side bottom -fill x
pack $tv    -side left   -fill both -expand 1

# ── Sidebar buttons ───────────────────────────────────────────────────────────
set home [file normalize ~]
set shortcuts [list \
    "Home"      $home              img_home \
    "Desktop"   $home/Desktop      img_desktop \
    "Documents" $home/Documents    img_documents \
    "Downloads" $home/Downloads    img_downloads \
    "Music"     $home/Music        img_music \
    "Pictures"  $home/Pictures     img_pictures \
    "Videos"    $home/Videos       img_videos \
]

foreach {label path icon} $shortcuts {
    if {[file exists $path]} {
        ttk::button $sidebar.btn_[string tolower $label] \
            -text $label \
            -image $icon \
            -compound left \
            -style [ttkbootstrap::bootstyle secondary Link.TButton] \
            -command [list fb_load $path]
        pack $sidebar.btn_[string tolower $label] -fill x -pady 1 -anchor w
    }
}

# ── Navigation procs ──────────────────────────────────────────────────────────
proc fb_load {path} {
    if {![file isdirectory $path]} return
    set ::fb_path [file normalize $path]
    set ::fb_path_var $::fb_path
    .fb.body.tv delete [.fb.body.tv children {}]

    set items {}
    catch {
        foreach f [lsort [glob -nocomplain -directory $::fb_path *]] {
            set name  [file tail $f]
            set mtime [file mtime $f]
            set mod   [clock format $mtime -format "%m/%d/%Y %I:%M %p"]
            if {[file isdirectory $f]} {
                set type "Folder"
                set size ""
                set tag  dir
            } else {
                set ext  [string toupper [string trimleft [file extension $f] .]]
                set type [expr {$ext ne "" ? "$ext File" : "File"}]
                set bytes [file size $f]
                set size  [format "%d KB" [expr {max(1, $bytes / 1024)}]]
                set tag   file
            }
            lappend items [list $name $mod $type $size $tag $f]
        }
    }

    # Sort: folders first
    set dirs  [lsearch -all -inline -index 4 $items dir]
    set files [lsearch -all -inline -index 4 $items file]
    foreach item [concat $dirs $files] {
        lassign $item name mod type size tag path
        # Use auto-assigned iid; store full path in values
        .fb.body.tv insert {} end -text " $name" \
            -values [list $path $mod $type $size] \
            -tags $tag
    }
}

proc fb_go_up {} {
    set parent [file dirname $::fb_path]
    if {$parent ne $::fb_path} {
        fb_load $parent
    }
}

# Double-click folder to navigate into it
bind $tv <Double-Button-1> {
    set item [.fb.body.tv focus]
    if {$item ne ""} {
        set path [lindex [.fb.body.tv item $item -values] 0]
        if {[file isdirectory $path]} { fb_load $path }
    }
}

# Load home directory on start
fb_load $::fb_path

wm protocol . WM_DELETE_WINDOW { exit }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
