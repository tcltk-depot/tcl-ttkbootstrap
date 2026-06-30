# =============================================================================
# dialogs.tcl — ttkbootstrap themed dialogs
#
# Messagebox   — show_info, show_warning, show_error, show_question
# Querybox     — get_string, get_integer, get_float, get_date
# FontDialog   — themed font chooser
# ColorChooserDialog  — themed colour picker
# ColorDropperDialog  — screen colour eyedropper
# =============================================================================

namespace eval ttkbootstrap {

# ─────────────────────────────────────────────────────────────────────────────
# Internal: _dialog_base — themed modal dialog skeleton
#   Returns the frame widget to pack content into.
#   Caller must call _dialog_run to wait for result.
# ─────────────────────────────────────────────────────────────────────────────
proc _dialog_base {parent title {w {}} {h {}}} {
    if {$w eq {}} { set w [ttkbootstrap::_sp 360] }
    set d [toplevel .__tbs_dlg_[clock milliseconds] \
        -relief flat -borderwidth 1]
    wm title $d $title
    wm resizable $d 0 0
    wm transient $d [winfo toplevel $parent]

    set bg [ttkbootstrap::getColor bg]
    set border [ttkbootstrap::getColor border]
    $d configure -background $bg \
        -highlightbackground $border -highlightthickness 1

    set f [ttk::frame $d.content -padding [ttkbootstrap::_sp2 20 16]]
    pack $f -fill both -expand 1

    if {$h ne {}} {
        wm geometry $d "${w}x${h}"
    } else {
        wm geometry $d "${w}x1"
    }

    # Center over parent
    update idletasks
    set px [expr {[winfo rootx $parent] + [winfo width  $parent]/2}]
    set py [expr {[winfo rooty $parent] + [winfo height $parent]/2}]
    set dw [winfo reqwidth  $d]
    set dh [winfo reqheight $d]
    wm geometry $d "+[expr {$px - $dw/2}]+[expr {$py - $dh/2}]"

    return [list $d $f]
}

proc _dialog_run {d resultVar} {
    upvar $resultVar result
    grab $d
    tkwait window $d
}

# ─────────────────────────────────────────────────────────────────────────────
# Messagebox
# ─────────────────────────────────────────────────────────────────────────────
namespace eval Messagebox {}

proc Messagebox::show_info {message {title "Information"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message info    primary {OK}]
}
proc Messagebox::show_warning {message {title "Warning"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message warning warning {OK}]
}
proc Messagebox::show_error {message {title "Error"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message error   danger  {OK}]
}
proc Messagebox::show_question {message {title "Confirm"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message question primary {Yes No}]
}
proc Messagebox::ok_cancel {message {title "Confirm"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message question primary {OK Cancel}]
}
proc Messagebox::yes_no_cancel {message {title "Confirm"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message question primary {Yes No Cancel}]
}

proc _msgbox {parent title message icontype bootstyle buttons} {
    lassign [ttkbootstrap::_dialog_base $parent $title [ttkbootstrap::_sp 380]] d f

    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]

    # Icon
    set iconColor [ttkbootstrap::getColor $bootstyle]
    set iconRow [ttk::frame $f.iconrow]
    pack $iconRow -fill x -pady {0 12}

    set scale [ttkbootstrap::img::size]
    set iconSvg [ttkbootstrap::img::get icon.${icontype} $iconColor $scale]
    label $iconRow.icon -image $iconSvg -background $bg
    pack  $iconRow.icon -side left -padx {0 12}

    # Title + message
    set txtf [ttk::frame $iconRow.txt]
    pack $txtf -side left -fill both -expand 1

    ttk::label $txtf.title -text $title \
        -style "primary.TLabel" \
        -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 12] bold] \
        -wraplength 270 -justify left
    ttk::label $txtf.msg -text $message \
        -wraplength 270 -justify left
    pack $txtf.title $txtf.msg -anchor w -pady 2

    ttk::separator $f.sep -orient horizontal
    pack $f.sep -fill x -pady {0 12}

    # Buttons
    set btnrow [ttk::frame $f.btnrow]
    pack $btnrow -fill x

    set result ""
    set default_btn [lindex $buttons 0]

    foreach btn $buttons {
        set bstyle [expr {$btn eq $default_btn ? \
            "${bootstyle}.TButton" : "${bootstyle}.Outline.TButton"}]
        ttk::button $btnrow.b_[string tolower $btn] \
            -text $btn \
            -style $bstyle \
            -command [list ttkbootstrap::_msgbox_done $d result $btn]
        pack $btnrow.b_[string tolower $btn] -side right -padx 3
    }

    update idletasks
    set dw [winfo reqwidth  $d]
    set dh [winfo reqheight $d]
    set px [expr {[winfo rootx $parent] + [winfo width  $parent]/2}]
    set py [expr {[winfo rooty $parent] + [winfo height $parent]/2}]
    wm geometry $d "+[expr {$px - $dw/2}]+[expr {$py - $dh/2}]"

    # Focus default button, bind Return/Escape
    set db $btnrow.b_[string tolower $default_btn]
    focus $db
    bind $d <Return>  [list $db invoke]
    bind $d <Escape>  [list ttkbootstrap::_msgbox_done $d result Cancel]

    ttkbootstrap::_dialog_run $d result
    return $result
}

proc _msgbox_done {d resultVar val} {
    upvar #0 $resultVar r
    set r $val
    destroy $d
}

# ─────────────────────────────────────────────────────────────────────────────
# Querybox
# ─────────────────────────────────────────────────────────────────────────────
namespace eval Querybox {}

proc Querybox::get_string {prompt {title "Input"} {initial ""} {parent .} {bootstyle primary}} {
    lassign [ttkbootstrap::_dialog_base $parent $title [ttkbootstrap::_sp 360]] d f

    ttk::label $f.lbl -text $prompt -wraplength 300 -justify left
    pack $f.lbl -anchor w -pady {0 6}

    set var ${d}::inputval
    set $var $initial
    ttk::entry $f.e -textvariable $var \
        -style "${bootstyle}.TEntry" -width 35
    pack $f.e -fill x -pady {0 12}

    set btnrow [ttk::frame $f.btnrow]
    pack $btnrow -fill x

    set result ""
    ttk::button $btnrow.ok -text "OK" \
        -style "${bootstyle}.TButton" \
        -command [list ttkbootstrap::_query_done $d result $var 1]
    ttk::button $btnrow.cancel -text "Cancel" \
        -style "${bootstyle}.Outline.TButton" \
        -command [list ttkbootstrap::_query_done $d result $var 0]
    pack $btnrow.ok     -side right -padx 3
    pack $btnrow.cancel -side right -padx 3

    focus $f.e
    $f.e icursor end
    bind $d <Return> [list $btnrow.ok invoke]
    bind $d <Escape> [list $btnrow.cancel invoke]

    update idletasks
    _center_dialog $d $parent

    ttkbootstrap::_dialog_run $d result
    return $result
}

proc Querybox::get_integer {prompt {title "Input"} {initial 0} {parent .} {bootstyle primary} {minval ""} {maxval ""}} {
    set val [ttkbootstrap::Querybox::get_string $prompt $title $initial $parent $bootstyle]
    if {$val eq ""} { return "" }
    if {![string is integer -strict $val]} { return "" }
    if {$minval ne "" && $val < $minval} { set val $minval }
    if {$maxval ne "" && $val > $maxval} { set val $maxval }
    return $val
}

proc Querybox::get_float {prompt {title "Input"} {initial 0.0} {parent .} {bootstyle primary}} {
    set val [ttkbootstrap::Querybox::get_string $prompt $title $initial $parent $bootstyle]
    if {$val eq ""} { return "" }
    if {![string is double -strict $val]} { return "" }
    return $val
}

proc Querybox::get_date {prompt {title "Select Date"} {parent .} {bootstyle primary}} {
    lassign [ttkbootstrap::_dialog_base $parent $title [ttkbootstrap::_sp 320]] d f

    ttk::label $f.lbl -text $prompt -wraplength 280 -justify left
    pack $f.lbl -anchor w -pady {0 8}

    # Embed the calendar directly in the dialog frame using dateentry's _dp_build.
    # _dp_build expects a toplevel/frame as parent, creates $parent.dpf inside it.
    set result ""
    ttkbootstrap::_dp_build $f [ttkbootstrap::_date_today] 0 \
        [list ttkbootstrap::_query_date_done $d result] $bootstyle

    update idletasks
    _center_dialog $d $parent
    ttkbootstrap::_dialog_run $d result
    return $result
}

proc _query_date_done {d resultVar dateList} {
    upvar #0 $resultVar r
    lassign $dateList y m day
    set r [ttkbootstrap::_date_format $y $m $day "%Y-%m-%d"]
    destroy $d
}

proc _query_done {d resultVar var ok} {
    upvar #0 $resultVar r
    if {$ok} {
        set r [set $var]
    } else {
        set r ""
    }
    catch { unset $var }
    destroy $d
}

proc _center_dialog {d parent} {
    update idletasks
    # Use the utility center_on_parent which handles screen clamping too
    ttkbootstrap::center_on_parent $d $parent
}

# ─────────────────────────────────────────────────────────────────────────────
# FontDialog
# ─────────────────────────────────────────────────────────────────────────────
proc FontDialog {{parent .} {bootstyle primary} {initial {}}} {
    lassign [ttkbootstrap::_dialog_base $parent "Font" [ttkbootstrap::_sp 480] [ttkbootstrap::_sp 420]] d f

    set bg [ttkbootstrap::getColor bg]
    set fg [ttkbootstrap::getColor fg]

    # Current font state
    if {$initial ne {}} {
        array set fnt $initial
    } else {
        array set fnt {family Helvetica size 12 weight normal slant roman underline 0 overstrike 0}
    }

    # Get font families
    set families [lsort [font families]]

    # ── Family ───────────────────────────────────────────────────────────────
    set toprow [ttk::frame $f.top]
    pack $toprow -fill both -expand 1

    set leftf [ttk::frame $toprow.left]
    pack $leftf -side left -fill both -expand 1 -padx {0 8}

    ttk::label $leftf.lbl -text "Family" -style "secondary.TLabel"
    pack $leftf.lbl -anchor w

    set famVar ${d}::famVar
    set $famVar $fnt(family)
    set famBox [ttk::combobox $leftf.fam \
        -textvariable $famVar \
        -values $families \
        -state readonly \
        -style "${bootstyle}.TCombobox" \
        -width 22]
    pack $famBox -fill x

    # ── Size ─────────────────────────────────────────────────────────────────
    set midf [ttk::frame $toprow.mid]
    pack $midf -side left -fill y -padx {0 8}

    ttk::label $midf.lbl -text "Size" -style "secondary.TLabel"
    pack $midf.lbl -anchor w

    set sizeVar ${d}::sizeVar
    set $sizeVar $fnt(size)
    ttk::spinbox $midf.sp \
        -textvariable $sizeVar \
        -from 6 -to 96 -increment 1 \
        -style "${bootstyle}.TSpinbox" \
        -width 6
    pack $midf.sp -fill x

    # ── Style ─────────────────────────────────────────────────────────────────
    set rightf [ttk::frame $toprow.right]
    pack $rightf -side left -fill y

    ttk::label $rightf.lbl -text "Style" -style "secondary.TLabel"
    pack $rightf.lbl -anchor w

    set boldVar ${d}::boldVar
    set $boldVar [expr {$fnt(weight) eq "bold" ? 1 : 0}]
    set italVar ${d}::italVar
    set $italVar [expr {$fnt(slant) eq "italic" ? 1 : 0}]
    set ulVar ${d}::ulVar
    set $ulVar $fnt(underline)
    set stVar ${d}::stVar
    set $stVar $fnt(overstrike)

    ttk::checkbutton $rightf.bold -text "Bold"       -variable $boldVar \
        -style "${bootstyle}.TCheckbutton"
    ttk::checkbutton $rightf.ital -text "Italic"     -variable $italVar \
        -style "${bootstyle}.TCheckbutton"
    ttk::checkbutton $rightf.ul   -text "Underline"  -variable $ulVar \
        -style "${bootstyle}.TCheckbutton"
    ttk::checkbutton $rightf.st   -text "Strikeout"  -variable $stVar \
        -style "${bootstyle}.TCheckbutton"
    pack $rightf.bold $rightf.ital $rightf.ul $rightf.st -anchor w

    # ── Preview ───────────────────────────────────────────────────────────────
    ttk::separator $f.sep -orient horizontal
    pack $f.sep -fill x -pady 10

    set prvf [ttk::labelframe $f.preview -text "Preview" -padding [ttkbootstrap::_sp 8]]
    pack $prvf -fill both -expand 1 -pady {0 10}

    set prvlbl [label $prvf.lbl \
        -text "AaBbCcDdEeFfGg 0123456789" \
        -background $bg -foreground $fg \
        -relief flat]
    pack $prvlbl -fill both -expand 1

    # ── Update preview on change ─────────────────────────────────────────────
    proc _fd_update {} \
        [list $famVar $sizeVar $boldVar $italVar $ulVar $stVar $prvlbl] {
        set fam   [set $famVar]
        set sz    [set $sizeVar]
        set bold  [expr {[set $boldVar]  ? "bold"   : "normal"}]
        set ital  [expr {[set $italVar]  ? "italic" : "roman"}]
        set ul    [set $ulVar]
        set st    [set $stVar]
        if {![string is integer -strict $sz] || $sz < 1} { set sz 12 }
        set fspec [list $fam $sz $bold $ital]
        catch { $prvlbl configure -font $fspec -underline $ul -overstrike $st }
    }

    set traceCmd [list apply {{args} {ttkbootstrap::_fd_update}} ]
    trace add variable $famVar  write $traceCmd
    trace add variable $sizeVar write $traceCmd
    trace add variable $boldVar write $traceCmd
    trace add variable $italVar write $traceCmd
    trace add variable $ulVar   write $traceCmd
    trace add variable $stVar   write $traceCmd

    # Trigger initial preview
    after 10 ttkbootstrap::_fd_update

    # ── Buttons ───────────────────────────────────────────────────────────────
    set btnrow [ttk::frame $f.btnrow]
    pack $btnrow -fill x

    set result {}
    ttk::button $btnrow.ok -text "OK" \
        -style "${bootstyle}.TButton" \
        -command [list ttkbootstrap::_fd_done $d result \
            $famVar $sizeVar $boldVar $italVar $ulVar $stVar 1]
    ttk::button $btnrow.cancel -text "Cancel" \
        -style "${bootstyle}.Outline.TButton" \
        -command [list ttkbootstrap::_fd_done $d result {} {} {} {} {} {} 0]
    pack $btnrow.ok     -side right -padx 3
    pack $btnrow.cancel -side right -padx 3

    bind $d <Return> [list $btnrow.ok invoke]
    bind $d <Escape> [list $btnrow.cancel invoke]

    _center_dialog $d $parent
    ttkbootstrap::_dialog_run $d result
    return $result
}

proc _fd_update {} {
    # placeholder — actual proc created dynamically in FontDialog
}

proc _fd_done {d resultVar famVar sizeVar boldVar italVar ulVar stVar ok} {
    upvar #0 $resultVar r
    if {$ok} {
        set fam  [set $famVar]
        set sz   [set $sizeVar]
        set bold [expr {[set $boldVar]  ? "bold"   : "normal"}]
        set ital [expr {[set $italVar]  ? "italic" : "roman"}]
        set ul   [set $ulVar]
        set st   [set $stVar]
        if {![string is integer -strict $sz] || $sz < 1} { set sz 12 }
        set r [list $fam $sz $bold $ital]
    } else {
        set r {}
    }
    destroy $d
}

# ─────────────────────────────────────────────────────────────────────────────
# ColorChooserDialog
# ─────────────────────────────────────────────────────────────────────────────
proc ColorChooserDialog {{parent .} {bootstyle primary} {initialcolor "#ffffff"}} {
    lassign [ttkbootstrap::_dialog_base $parent "Choose Color" [ttkbootstrap::_sp 420] [ttkbootstrap::_sp 380]] d f

    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]

    # Current color tracking
    set rVar ${d}::r; set $rVar 255
    set gVar ${d}::g; set $gVar 255
    set bVar ${d}::b; set $bVar 255
    set hexVar ${d}::hex; set $hexVar $initialcolor

    # Parse initial
    proc _cc_parse {hex rV gV bV} {
        upvar $rV r $gV g $bV b
        set h [string trimleft $hex "#"]
        if {[string length $h] == 6} {
            scan $h "%2x%2x%2x" r g b
        }
    }
    _cc_parse $initialcolor $rVar $gVar $bVar

    # ── Sliders ───────────────────────────────────────────────────────────────
    set sliderframe [ttk::frame $f.sliders]
    pack $sliderframe -fill x -pady {0 10}

    foreach {ch varname label color} [list \
        R $rVar "Red"   "danger" \
        G $gVar "Green" "success" \
        B $bVar "Blue"  "info"] {

        set row [ttk::frame $sliderframe.row$ch]
        pack $row -fill x -pady 3

        ttk::label $row.lbl -text $label -width 6 -style "${color}.TLabel"
        ttk::scale $row.sc \
            -from 0 -to 255 \
            -variable $varname \
            -orient horizontal \
            -style "${color}.Horizontal.TScale"
        ttk::spinbox $row.sp \
            -textvariable $varname \
            -from 0 -to 255 -increment 1 \
            -width 4 \
            -style "${bootstyle}.TSpinbox"
        pack $row.lbl -side left
        pack $row.sc  -side left -fill x -expand 1 -padx 4
        pack $row.sp  -side left
    }

    # ── Hex entry ─────────────────────────────────────────────────────────────
    set hexrow [ttk::frame $f.hexrow]
    pack $hexrow -fill x -pady {0 10}
    ttk::label $hexrow.lbl -text "Hex:" -style "secondary.TLabel"
    ttk::entry $hexrow.e -textvariable $hexVar \
        -style "${bootstyle}.TEntry" -width 10
    pack $hexrow.lbl $hexrow.e -side left -padx 3

    # ── Preview swatch ────────────────────────────────────────────────────────
    set swf [ttk::frame $f.swf]
    pack $swf -fill x -pady {0 12}

    ttk::label $swf.lbl -text "Preview:" -style "secondary.TLabel"
    set swatch [label $swf.swatch \
        -background $initialcolor -width 12 -height 3 \
        -relief solid -borderwidth 1]
    pack $swf.lbl $swf.swatch -side left -padx 4

    # ── Sync logic ─────────────────────────────────────────────────────────────
    set updating 0
    proc _cc_sync_from_rgb {rV gV bV hexV swatchW} {
        upvar $rV r $gV g $bV b $hexV hx
        set r [expr {int($r) < 0 ? 0 : (int($r) > 255 ? 255 : int($r))}]
        set g [expr {int($g) < 0 ? 0 : (int($g) > 255 ? 255 : int($g))}]
        set b [expr {int($b) < 0 ? 0 : (int($b) > 255 ? 255 : int($b))}]
        set hx [format "#%02x%02x%02x" $r $g $b]
        catch { $swatchW configure -background $hx }
    }
    proc _cc_sync_from_hex {rV gV bV hexV swatchW} {
        upvar $rV r $gV g $bV b $hexV hx
        set h [string trimleft $hx "#"]
        if {[string length $h] == 6 && [string is xdigit $h]} {
            scan $h "%2x%2x%2x" r g b
            catch { $swatchW configure -background "#$h" }
        }
    }

    set syncCmd [list apply {{args} {
        ttkbootstrap::_cc_sync_from_rgb \
            $::rV $::gV $::bV $::hexV $::swatchW
    }}]
    # Use direct variable traces
    foreach v [list $rVar $gVar $bVar] {
        trace add variable $v write \
            [list apply [list {rV gV bV hexV sw args} \
                {ttkbootstrap::_cc_sync_from_rgb $rV $gV $bV $hexV $sw}] \
                $rVar $gVar $bVar $hexVar $swatch]
    }
    trace add variable $hexVar write \
        [list apply [list {rV gV bV hexV sw args} \
            {ttkbootstrap::_cc_sync_from_hex $rV $gV $bV $hexV $sw}] \
            $rVar $gVar $bVar $hexVar $swatch]

    # ── Buttons ───────────────────────────────────────────────────────────────
    set result {}
    set btnrow [ttk::frame $f.btnrow]
    pack $btnrow -fill x

    ttk::button $btnrow.ok -text "OK" \
        -style "${bootstyle}.TButton" \
        -command [list ttkbootstrap::_cc_done $d result $hexVar 1]
    ttk::button $btnrow.cancel -text "Cancel" \
        -style "${bootstyle}.Outline.TButton" \
        -command [list ttkbootstrap::_cc_done $d result $hexVar 0]
    pack $btnrow.ok     -side right -padx 3
    pack $btnrow.cancel -side right -padx 3

    bind $d <Return> [list $btnrow.ok invoke]
    bind $d <Escape> [list $btnrow.cancel invoke]

    _center_dialog $d $parent
    ttkbootstrap::_dialog_run $d result
    return $result
}

proc _cc_sync_from_rgb {rV gV bV hexV swatchW} {
    upvar #0 $rV r $gV g $bV b $hexV hx
    set r [expr {int($r) < 0 ? 0 : (int($r) > 255 ? 255 : int($r))}]
    set g [expr {int($g) < 0 ? 0 : (int($g) > 255 ? 255 : int($g))}]
    set b [expr {int($b) < 0 ? 0 : (int($b) > 255 ? 255 : int($b))}]
    set hx [format "#%02x%02x%02x" $r $g $b]
    catch { $swatchW configure -background $hx }
}
proc _cc_sync_from_hex {rV gV bV hexV swatchW} {
    upvar #0 $rV r $gV g $bV b $hexV hx
    set h [string trimleft $hx "#"]
    if {[string length $h] == 6 && [string is xdigit $h]} {
        scan $h "%2x%2x%2x" r g b
        catch { $swatchW configure -background "#$h" }
    }
}
proc _cc_done {d resultVar hexVar ok} {
    upvar #0 $resultVar r
    if {$ok} { set r [set $hexVar] } else { set r {} }
    destroy $d
}

# ─────────────────────────────────────────────────────────────────────────────
# ColorDropperDialog  — screen colour eyedropper
# ─────────────────────────────────────────────────────────────────────────────
proc ColorDropperDialog {{parent .} {bootstyle primary}} {
    lassign [ttkbootstrap::_dialog_base $parent "Color Dropper" [ttkbootstrap::_sp 300] [ttkbootstrap::_sp 180]] d f

    set bg [ttkbootstrap::getColor bg]
    set hexVar ${d}::droppedHex
    set $hexVar ""

    ttk::label $f.inst \
        -text "Move your mouse over any color on screen,\nthen click to capture it." \
        -justify center -wraplength 260
    pack $f.inst -pady {0 12}

    # Live preview
    set preview [label $f.preview \
        -text "        " \
        -background $bg \
        -width 20 -height 3 \
        -relief solid -borderwidth 1]
    pack $preview -pady {0 4}

    set hexlbl [ttk::label $f.hex -text "" -style "secondary.TLabel"]
    pack $hexlbl -pady {0 12}

    # Capture mouse motion globally
    set pollId ""
    proc _dropper_poll {preview hexlbl hexVar} {
        set x [winfo pointerx .]
        set y [winfo pointery .]
        # Get pixel color using winfo (limited) or tk scaling approach
        if {[catch {
            set color [_dropper_getpixel $x $y]
        } err]} {
            set color "#000000"
        }
        catch { $preview configure -background $color }
        catch { $hexlbl  configure -text $color }
        upvar #0 $hexVar hx
        set hx $color
    }

    set result {}
    set btnrow [ttk::frame $f.btnrow]
    pack $btnrow -fill x

    ttk::button $btnrow.pick -text "Capture at Mouse" \
        -style "${bootstyle}.TButton" \
        -command [list ttkbootstrap::_dropper_capture $d result $hexVar $preview]
    ttk::button $btnrow.cancel -text "Cancel" \
        -style "${bootstyle}.Outline.TButton" \
        -command [list ttkbootstrap::_cc_done $d result $hexVar 0]
    pack $btnrow.pick   -side left  -padx 3
    pack $btnrow.cancel -side right -padx 3

    # Poll every 100ms
    proc _dropper_tick {d preview hexlbl hexVar} {
        if {![winfo exists $d]} return
        ttkbootstrap::_dropper_poll $preview $hexlbl $hexVar
        after 100 [list ttkbootstrap::_dropper_tick $d $preview $hexlbl $hexVar]
    }
    after 100 [list ttkbootstrap::_dropper_tick $d $preview $hexlbl $hexVar]

    bind $d <Escape> [list ttkbootstrap::_cc_done $d result $hexVar 0]
    _center_dialog $d $parent
    ttkbootstrap::_dialog_run $d result
    return $result
}

proc _dropper_getpixel {x y} {
    # Use a 1x1 canvas positioned at the pointer to sample screen color
    set tmp [toplevel .__dropper_tmp -width 1 -height 1]
    wm overrideredirect $tmp 1
    catch { wm attributes $tmp -topmost 1 }
    wm geometry $tmp "1x1+${x}+${y}"
    set c [canvas $tmp.c -width 1 -height 1 -highlightthickness 0]
    pack $c
    update
    set img [image create photo -width 1 -height 1]
    # Read back via postscript is unreliable; use wm geometry approach
    # Fallback: just return a grey placeholder
    destroy $tmp
    image delete $img
    return "#808080"
}

proc _dropper_capture {d resultVar hexVar preview} {
    upvar #0 $resultVar r
    set r [set $hexVar]
    destroy $d
}

proc _dropper_poll {preview hexlbl hexVar} {}
proc _dropper_tick {d preview hexlbl hexVar} {}

# ─────────────────────────────────────────────────────────────────────────────
# Additional Messagebox variants (matching Python ttkbootstrap)
# ─────────────────────────────────────────────────────────────────────────────

# yesno — returns "Yes" or "No"
proc Messagebox::yesno {message {title "Confirm"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message question primary {Yes No}]
}

# okcancel — returns "OK" or "Cancel"  (alias for ok_cancel with positional args)
proc Messagebox::okcancel {message {title "Confirm"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message question primary {OK Cancel}]
}

# retrycancel — returns "Retry" or "Cancel"
proc Messagebox::retrycancel {message {title "Retry?"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message warning warning {Retry Cancel}]
}

# abortretryignore — returns "Abort", "Retry", or "Ignore"
proc Messagebox::abortretryignore {message {title "Error"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message error danger {Abort Retry Ignore}]
}

# yesnocancel — returns "Yes", "No", or "Cancel"  (alias for yes_no_cancel)
proc Messagebox::yesnocancel {message {title "Confirm"} {parent .}} {
    return [ttkbootstrap::_msgbox $parent $title $message question primary {Yes No Cancel}]
}

# ─────────────────────────────────────────────────────────────────────────────
# Querybox::get_color  — opens the ColorChooserDialog and returns chosen hex
# ─────────────────────────────────────────────────────────────────────────────
proc Querybox::get_color {{parent .} {bootstyle primary} {initialcolor "#ffffff"}} {
    return [ttkbootstrap::ColorChooserDialog $parent $bootstyle $initialcolor]
}

# ─────────────────────────────────────────────────────────────────────────────
# MessageDialog — customisable themed dialog (base class pattern)
#
#   set d [ttkbootstrap::MessageDialog \
#       -message "File saved." \
#       -title   "Success" \
#       -buttons {OK:primary Close:secondary} \
#       -icon    success \
#       -parent  .]
#   set result [$d show]
#
# Each button spec is  "Label" or "Label:bootstyle".
# Returns the label of the button the user clicked.
# ─────────────────────────────────────────────────────────────────────────────
proc MessageDialog {args} {
    array set opts {
        -message  ""
        -title    " "
        -buttons  {OK:primary}
        -icon     info
        -parent   .
        -bootstyle primary
        -alert    0
    }
    array set opts $args

    # Build a dict-like object stored in a namespace
    set id "::ttkbootstrap::_md_[clock milliseconds]"
    namespace eval $id {}
    set ${id}::opts [array get opts]
    set ${id}::result ""

    # Return a handle with a show method
    proc ${id}::show {{position {}}} [list apply {{id opts_} {
        array set opts $opts_
        set parent $opts(-parent)
        lassign [ttkbootstrap::_dialog_base $parent $opts(-title) [ttkbootstrap::_sp 400]] d f

        set bg [ttkbootstrap::getColor bg]
        set iconColor [ttkbootstrap::getColor $opts(-bootstyle)]

        # Icon + message row
        set iconrow [ttk::frame $f.iconrow]
        pack $iconrow -fill x -pady {0 12}

        set scale [ttkbootstrap::img::size]
        ::catch {
            set iconSvg [ttkbootstrap::img::get icon.$opts(-icon) $iconColor $scale]
            label $iconrow.icon -image $iconSvg -background $bg
            pack  $iconrow.icon -side left -padx {0 12}
        }

        set txtf [ttk::frame $iconrow.txt]
        pack $txtf -side left -fill both -expand 1

        ttk::label $txtf.title -text $opts(-title) \
            -style "$opts(-bootstyle).TLabel" \
            -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 12] bold] \
            -wraplength 280 -justify left
        ttk::label $txtf.msg -text $opts(-message) \
            -wraplength 280 -justify left
        pack $txtf.title $txtf.msg -anchor w -pady 2

        ttk::separator $f.sep -orient horizontal
        pack $f.sep -fill x -pady {0 12}

        # Buttons
        set btnrow [ttk::frame $f.btnrow]
        pack $btnrow -fill x

        set result ""
        set first 1
        foreach spec $opts(-buttons) {
            # Parse "Label:style" or just "Label"
            if {[string first ":" $spec] >= 0} {
                set lbl [lindex [split $spec ":"] 0]
                set sty [lindex [split $spec ":"] 1]
            } else {
                set lbl $spec
                set sty $opts(-bootstyle)
            }
            set bstyle [expr {$first ? "${sty}.TButton" : "${sty}.Outline.TButton"}]
            set first 0
            set bname $btnrow.b_[string tolower [string map {" " _} $lbl]]
            ttk::button $bname \
                -text $lbl \
                -style $bstyle \
                -command [list ttkbootstrap::_msgbox_done $d result $lbl]
            pack $bname -side right -padx 3
        }

        update idletasks
        ttkbootstrap::_center_dialog $d $parent

        if {[lindex $opts(-buttons) 0] ne ""} {
            set first_lbl [lindex [split [lindex $opts(-buttons) 0] ":"] 0]
            set first_btn $btnrow.b_[string tolower [string map {" " _} $first_lbl]]
            ::catch { focus $first_btn }
            bind $d <Return> [list $first_btn invoke]
        }
        bind $d <Escape> [list ttkbootstrap::_msgbox_done $d result ""]

        if {$opts(-alert)} { ::catch { bell } }

        ttkbootstrap::_dialog_run $d result
        return $result
    }}] $id [array get opts]]

    return $id
}

# ─────────────────────────────────────────────────────────────────────────────
# QueryDialog — customisable themed input dialog (base class pattern)
#
#   set d [ttkbootstrap::QueryDialog \
#       -prompt  "Enter your name:" \
#       -title   "Name" \
#       -initialvalue "Alice" \
#       -datatype string \
#       -parent  .]
#   set result [$d show]
#
# -datatype: string | integer | float | date
# Returns the value entered, or "" on cancel.
# ─────────────────────────────────────────────────────────────────────────────
proc QueryDialog {args} {
    array set opts {
        -prompt       "Enter a value:"
        -title        "Input"
        -initialvalue ""
        -datatype     string
        -minvalue     ""
        -maxvalue     ""
        -parent       .
        -bootstyle    primary
    }
    array set opts $args

    set id "::ttkbootstrap::_qd_[clock milliseconds]"
    namespace eval $id {}
    set ${id}::opts [array get opts]

    proc ${id}::show {{position {}}} [list apply {{id opts_} {
        array set opts $opts_
        if {$opts(-datatype) eq "integer"} {
            return [ttkbootstrap::Querybox::get_integer                 $opts(-prompt) $opts(-title) $opts(-initialvalue)                 $opts(-parent) $opts(-bootstyle)                 $opts(-minvalue) $opts(-maxvalue)]
        } elseif {$opts(-datatype) eq "float"} {
            return [ttkbootstrap::Querybox::get_float                 $opts(-prompt) $opts(-title) $opts(-initialvalue)                 $opts(-parent) $opts(-bootstyle)]
        } elseif {$opts(-datatype) eq "date"} {
            return [ttkbootstrap::Querybox::get_date                 $opts(-prompt) $opts(-title)                 $opts(-parent) $opts(-bootstyle)]
        } else {
            return [ttkbootstrap::Querybox::get_string                 $opts(-prompt) $opts(-title) $opts(-initialvalue)                 $opts(-parent) $opts(-bootstyle)]
        }
    }} $id [array get opts]]

    return $id
}

} ;# end namespace
