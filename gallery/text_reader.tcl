# text_reader.tcl — ttkbootstrap port of text_reader.py
package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

ttkbootstrap::Window -themename sandstone -title "Text Reader"

set ::tr_filename ""

set f [ttk::frame .tr -padding 15]
pack $f -fill both -expand 1

# Scrolled text box
set txt [text $f.txt \
    -wrap word \
    -width 80 -height 24 \
    -yscrollcommand "$f.sb set"]
set sb [ttk::scrollbar $f.sb -command "$f.txt yview"]
pack $sb -side right -fill y
pack $txt -side left -fill both -expand 1

$txt insert end "Click the Browse button to open a new text file."

# File entry + browse button
set file_row [ttk::frame $f.frow]
pack $file_row -fill x -pady 10 -after $txt

ttk::entry $file_row.ent -textvariable ::tr_filename
pack $file_row.ent -side left -fill x -expand 1 -padx {0 5}

ttk::button $file_row.browse \
    -text "Browse" \
    -command {
        set path [tk_getOpenFile -title "Open Text File" -filetypes {{"Text Files" {.txt .md .py .tcl}} {"All Files" *}}]
        if {$path ne ""} {
            set ::tr_filename $path
            set fh [open $path r]
            set content [read $fh]
            close $fh
            .tr.txt delete 1.0 end
            .tr.txt insert end $content
        }
    }
pack $file_row.browse -side right -padx {5 0}

# Re-pack in correct order
pack forget $f.txt $f.sb $f.frow
pack $f.frow -fill x -side bottom -pady 10
pack $f.sb -side right -fill y
pack $f.txt -side left -fill both -expand 1

wm protocol . WM_DELETE_WINDOW { _close_gallery }
if {![info exists ::tcl_interactive] || !$::tcl_interactive} { vwait forever }
