# pc_cleaner.tcl — ttkbootstrap port of pc_cleaner.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

set ASSETS [file join [file dirname [info script]] assets]
source [file join [file dirname [info script]] gallery_icons.tcl]

ttkbootstrap::Window -themename pulse -title "PC Cleaner"

set ::pc_progress 78

set f [ttk::frame .pc]
pack $f -fill both -expand 1

# Load images (regenerated from SVG — no PNG assets required). The logo sits on
# a coloured header so it needs a light glyph; the rest sit on light cards.
gallery_make_icon img_logo     icons8_broom_64px_1.png        white
gallery_make_icon img_cleaner  icons8_broom_64px.png          primary
gallery_make_icon img_registry icons8_registry_editor_64px.png primary
gallery_make_icon img_tools    icons8_wrench_64px.png         primary
gallery_make_icon img_options  icons8_settings_64px.png       primary
gallery_make_icon img_privacy  icons8_spy_80px.png            primary
gallery_make_icon img_junk     icons8_trash_can_80px.png      primary
gallery_make_icon img_protect  icons8_protect_40px.png        primary

# Header
set hdr [ttk::frame $f.hdr -padding 20 -style secondary.TFrame]
grid $hdr -row 0 -column 0 -columnspan 3 -sticky ew

ttk::label $hdr.logo -image img_logo -style secondary.Inverse.TLabel
pack $hdr.logo -side left

ttk::label $hdr.title \
    -text "pc cleaner" \
    -font [list TkFixedFont [ttkbootstrap::_sf 30]] \
    -style secondary.Inverse.TLabel
pack $hdr.title -side left -padx 10

# Action buttons column
set action [ttk::frame $f.action]
grid $action -row 1 -column 0 -sticky nsew

foreach {img txt} {img_cleaner cleaner img_registry registry img_tools tools img_options options} {
    ttk::button $action.btn_$txt \
        -image $img \
        -text $txt \
        -compound top \
        -style [ttkbootstrap::bootstyle info TButton]
    pack $action.btn_$txt -side top -fill both -ipadx 10 -ipady 10
}

# Notebook
set nb [ttk::notebook $f.nb]
grid $nb -row 1 -column 1 -sticky nsew -pady {25 0}

# Windows tab
set win_tab [ttk::frame $nb.win -padding 10]
$nb add $win_tab -text "windows"

set wt_sb [ttk::scrollbar $win_tab.sb]
pack $wt_sb -side right -fill y

set wt_canvas [canvas $win_tab.canvas \
    -relief flat \
    -borderwidth 0 \
    -highlightthickness 0 \
    -yscrollcommand "$wt_sb set"]
pack $wt_canvas -side left -fill both -expand 1
$wt_sb configure -command "$wt_canvas yview"

set scroll_frame [ttk::frame $wt_canvas.sf]
$wt_canvas create window {0 0} -window $scroll_frame -anchor nw
bind $scroll_frame <Configure> {
    .pc.nb.win.canvas configure -scrollregion [.pc.nb.win.canvas bbox all]
}

set radio_opts {
    "Internet Cache" "Internet History" "Cookies"
    "Download History" "Last Download Location"
    "Session" "Set Aside Tabs" "Recently Typed URLs"
    "Saved Form Information" "Saved Password"
}

foreach {sect_name} {"Microsoft Edge" "Internet Explorer"} {
    set sect [ttk::labelframe $scroll_frame.sect_[string map {{ } _} $sect_name] \
        -text $sect_name -padding {20 5}]
    pack $sect -fill both -expand 1 -padx 20 -pady 10
    set i 0
    foreach opt $radio_opts {
        set vname "::pcc_${sect_name}_${i}"
        set $vname 1
        ttk::checkbutton $sect.cb$i -text $opt -variable $vname
        pack $sect.cb$i -side top -pady 2 -fill x
        incr i
    }
}

# Empty applications tab
$nb add [ttk::frame $nb.apps] -text "applications"

# Results frame
set results [ttk::frame $f.results]
grid $results -row 1 -column 2 -sticky nsew

# Progressbar with percentage
set pb_frame [ttk::frame $results.pbf -padding {0 10 10 10}]
pack $pb_frame -side top -fill x -expand 1

ttk::progressbar $pb_frame.pb \
    -variable ::pc_progress \
    -style [ttkbootstrap::bootstyle success striped TProgressbar]
pack $pb_frame.pb -side left -fill x -expand 1 -padx {15 10}

ttk::label $pb_frame.pct -text "%"
pack $pb_frame.pct -side right
ttk::label $pb_frame.val -textvariable ::pc_progress
pack $pb_frame.val -side right

# Cards
set cards [ttk::frame $results.cards -style secondary.TFrame]
pack $cards -fill both -expand 1

# Privacy card
set priv [ttk::frame $cards.priv -padding 1]
pack $priv -side left -fill both -padx {10 5} -pady 10

set priv_c [ttk::frame $priv.c -padding 40]
pack $priv_c -fill both -expand 1

ttk::label $priv_c.img \
    -image img_privacy \
    -text "PRIVACY" \
    -compound top \
    -anchor center
pack $priv_c.img -fill both -padx 20 -pady {40 0}

ttk::label $priv_c.lbl \
    -text "6025 tracking file(s) removed" \
    -style primary.TLabel
pack $priv_c.lbl -pady {0 20}

# Junk card
set junk [ttk::frame $cards.junk -padding 1]
pack $junk -side left -fill both -padx {5 10} -pady 10

set junk_c [ttk::frame $junk.c -padding 40]
pack $junk_c -fill both -expand 1

ttk::label $junk_c.img \
    -image img_junk \
    -text "JUNK" \
    -compound top \
    -anchor center
pack $junk_c.img -fill both -padx 20 -pady {40 0}

ttk::label $junk_c.lbl \
    -text "1,150 MB of unnecessary\nfile(s) removed" \
    -style primary.TLabel \
    -justify center
pack $junk_c.lbl -pady {0 20}

# Notification
set note [ttk::frame $results.note -style secondary.TFrame -padding 40]
pack $note -fill both

ttk::label $note.msg \
    -text "We recommend that you better protect your data" \
    -anchor center \
    -font [list Helvetica [ttkbootstrap::_sf 12] italic] \
    -style secondary.Inverse.TLabel
pack $note.msg -fill both

# Configure grid weights
grid columnconfigure $f 1 -weight 1
grid columnconfigure $f 2 -weight 1
grid rowconfigure    $f 1 -weight 1

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
