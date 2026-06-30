# filechooser.tcl — Pure Tk file/directory chooser
# Stays on top of overrideredirect gallery windows (no WM chrome).
#
# API (mirrors standard Tk):
#   ttkbootstrap::GetOpenFile    ?-title t? ?-filetypes list? ?-initialdir d?
#                                ?-initialfile f? ?-parent w?
#   ttkbootstrap::ChooseDirectory ?-title t? ?-initialdir d? ?-parent w?
# Both return the chosen path or "" if cancelled.
#
# Features vs native:
#   ✓ Bookmarks panel (Home, Desktop, common dirs)
#   ✓ Hidden files toggle
#   ✓ File type filter dropdown
#   ✓ Sort: name / date / size
#   ✓ -initialfile support
#   ✓ Theme-matched, borderless, centres over parent
#   ✗ Multiple selection  ✗ Recent files  ✗ Auto-complete

namespace eval ttkbootstrap {

proc _fc_dialog {mode args} {
    array set o {-title {} -filetypes {} -initialdir {}
                 -initialfile {} -parent .}
    array set o $args

    if {$o(-title) eq {}} {
        set o(-title) [expr {$mode eq "dir" ? "Choose Directory" : "Open File"}]
    }
    if {$o(-initialdir) eq {} || ![file isdirectory $o(-initialdir)]} {
        set o(-initialdir) [pwd]
    }

    # ── State variables ────────────────────────────────────────────────────────
    set ::__fc_locvar    $o(-initialdir)
    set ::__fc_fnvar     $o(-initialfile)
    set ::__fc_showhidden 0
    set ::__fc_sort      name        ;# name | date | size
    set ::__fc_result    __waiting__
    set ::__fc_entries   {}
    set ::__fc_filetypes $o(-filetypes)
    set ::__fc_ftlabels  {}
    set ::__fc_ftypes    {}
    set ::__fc_ftsel     {}

    if {$o(-filetypes) ne {}} {
        foreach ft $o(-filetypes) {
            lappend ::__fc_ftlabels [lindex $ft 0]
            lappend ::__fc_ftypes   [lindex $ft 1]
        }
        set ::__fc_ftsel [lindex $::__fc_ftlabels 0]
    }

    # ── Colours / fonts ────────────────────────────────────────────────────────
    set ac  [ttkbootstrap::getColor primary]
    set fg  [ttkbootstrap::_contrastFg $ac]
    set hbg [ttkbootstrap::_darken $ac 18]
    set bg  [ttkbootstrap::getColor bg]
    set bg2 [ttkbootstrap::getColor inputbg]
    set fgn [ttkbootstrap::getColor fg]
    set bdr [ttkbootstrap::getColor border]
    set sec [ttkbootstrap::getColor secondary]
    set fnm [ttkbootstrap::_safeFont $fgn]
    set fs  [ttkbootstrap::_sf 11]
    set fss [ttkbootstrap::_sf 10]

    # ── Dialog window ──────────────────────────────────────────────────────────
    set d [toplevel .__fc_dialog -relief solid -borderwidth 1]
    wm withdraw $d
    wm overrideredirect $d 1
    wm transient $d $o(-parent)

    # ── Title bar ──────────────────────────────────────────────────────────────
    frame $d.tb -bg $ac
    pack  $d.tb -fill x

    label $d.tb.t -text $o(-title) -bg $ac -fg $fg \
        -font [list $fnm $fs bold] -padx 10 -pady 5
    pack  $d.tb.t -side left

    label $d.tb.x -text " × " -bg $ac -fg $fg -cursor hand2 \
        -font [list $fnm [ttkbootstrap::_sf 13] bold] -padx 6
    pack  $d.tb.x -side right
    bind  $d.tb.x <Enter>    [list $d.tb.x configure -bg $hbg]
    bind  $d.tb.x <Leave>    [list $d.tb.x configure -bg $ac]
    bind  $d.tb.x <Button-1> [list set ::__fc_result {}]

    # ── Location bar ──────────────────────────────────────────────────────────
    frame $d.loc -bg $bg -padx 8 -pady 4
    pack  $d.loc -fill x

    label $d.loc.l -text "Location:" -bg $bg -fg $fgn \
        -font [list $fnm $fss] -width 9 -anchor w
    ttk::entry $d.loc.e -textvariable ::__fc_locvar \
        -style "primary.TEntry" -font [list $fnm $fss]
    pack $d.loc.l -side left
    pack $d.loc.e -side left -fill x -expand 1 -padx 4
    bind $d.loc.e <Return> [list ttkbootstrap::_fc_navigate $d $mode]

    # ── Nav bar: Up / Hidden / Sort ───────────────────────────────────────────
    frame $d.nav -bg $bg -padx 8 -pady 2
    pack  $d.nav -fill x

    ttk::button $d.nav.up -text "↑ Up" -style "secondary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::_fc_up $d $mode]

    # Sort menu
    menubutton $d.nav.sort -text "Sort ▾" \
        -bg $bg -fg $fgn -font [list $fnm $fss] \
        -relief flat -cursor hand2
    set sm [menu $d.nav.sort.m -tearoff 0 -bg $bg -fg $fgn \
        -font [list $fnm $fss]]
    $sm add command -label "By name" \
        -command [list ttkbootstrap::_fc_set_sort $d $mode name]
    $sm add command -label "By date (newest first)" \
        -command [list ttkbootstrap::_fc_set_sort $d $mode date]
    $sm add command -label "By size (largest first)" \
        -command [list ttkbootstrap::_fc_set_sort $d $mode size]
    $d.nav.sort configure -menu $sm

    ttk::checkbutton $d.nav.hid -text "Hidden" \
        -variable ::__fc_showhidden \
        -style "secondary.TCheckbutton" \
        -command [list ttkbootstrap::_fc_refresh $d $mode]

    pack $d.nav.up   -side left -padx {0 4}
    pack $d.nav.sort -side left -padx {0 4}
    pack $d.nav.hid  -side right

    # ── Main area: bookmarks + file list ──────────────────────────────────────
    frame $d.main -bg $bg
    pack  $d.main -fill both -expand 1

    # File list panel
    frame $d.main.lf -bg $bg
    pack  $d.main.lf -side left -fill both -expand 1

    set lb [listbox $d.main.lf.lb \
        -width 42 -height 16 \
        -selectmode single \
        -bg $bg2 -fg $fgn \
        -selectbackground $ac \
        -selectforeground $fg \
        -font [list $fnm $fss] \
        -relief flat -borderwidth 0 \
        -highlightthickness 1 \
        -highlightcolor $bdr \
        -yscrollcommand [list $d.main.lf.sb set]]
    set sb [ttk::scrollbar $d.main.lf.sb -orient vertical \
        -command [list $lb yview] -style "primary.Vertical.TScrollbar"]
    pack $sb -side right -fill y
    pack $lb -side left  -fill both -expand 1

    bind $lb <Double-Button-1> [list ttkbootstrap::_fc_activate $d $lb $mode]
    bind $lb <Return>          [list ttkbootstrap::_fc_activate $d $lb $mode]

    # ── Filename entry (file mode) ────────────────────────────────────────────
    if {$mode eq "file"} {
        frame $d.fn -bg $bg -padx 8 -pady 4
        pack  $d.fn -fill x

        label $d.fn.l -text "Filename:" -bg $bg -fg $fgn \
            -font [list $fnm $fss] -width 9 -anchor w
        ttk::entry $d.fn.e -textvariable ::__fc_fnvar \
            -style "primary.TEntry" -font [list $fnm $fss]
        pack $d.fn.l -side left
        pack $d.fn.e -side left -fill x -expand 1 -padx 4

        bind $lb <<ListboxSelect>> \
            [list ttkbootstrap::_fc_lb_select $lb $d.fn.e $mode]

        # File type filter dropdown (only when filetypes supplied)
        if {$o(-filetypes) ne {}} {
            frame $d.ft -bg $bg -padx 8 -pady 2
            pack  $d.ft -fill x

            label $d.ft.l -text "File type:" -bg $bg -fg $fgn \
                -font [list $fnm $fss] -width 9 -anchor w
            ttk::combobox $d.ft.cb \
                -textvariable ::__fc_ftsel \
                -values       $::__fc_ftlabels \
                -state        readonly \
                -style        "primary.TCombobox" \
                -font         [list $fnm $fss]
            bind $d.ft.cb <<ComboboxSelected>> \
                [list ttkbootstrap::_fc_filter_changed $d $lb $mode]
            pack $d.ft.l  -side left
            pack $d.ft.cb -side left -fill x -expand 1 -padx 4
        }
    }

    # ── Buttons ───────────────────────────────────────────────────────────────
    frame $d.sep2 -bg $bdr -height 1
    pack  $d.sep2 -fill x

    frame $d.foot -bg $bg -padx 12 -pady 8
    pack  $d.foot -fill x

    set ok_lbl [expr {$mode eq "dir" ? "Choose" : "Open"}]
    ttk::button $d.foot.ok -text $ok_lbl -style "primary.TButton" \
        -padding [ttkbootstrap::_sp2 20 4] \
        -command [list ttkbootstrap::_fc_confirm $d $lb $mode]
    ttk::button $d.foot.cancel -text "Cancel" \
        -style "secondary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 16 4] \
        -command [list set ::__fc_result {}]
    pack $d.foot.cancel -side right -padx 4
    pack $d.foot.ok     -side right

    bind $d <Escape> [list set ::__fc_result {}]

    # ── Populate and show ─────────────────────────────────────────────────────
    ttkbootstrap::_fc_populate $lb $o(-initialdir) $mode

    # Pre-select initialfile if given
    if {$mode eq "file" && $o(-initialfile) ne {}} {
        set target [file tail $o(-initialfile)]
        for {set i 0} {$i < [$lb size]} {incr i} {
            set info [lindex $::__fc_entries $i]
            if {[lindex $info 0] eq "file" &&
                [file tail [lindex $info 1]] eq $target} {
                $lb selection set $i
                $lb see $i
                set ::__fc_fnvar $target
                break
            }
        }
    }

    update idletasks
    set pw [winfo width  $o(-parent)]
    set ph [winfo height $o(-parent)]
    set px [winfo rootx  $o(-parent)]
    set py [winfo rooty  $o(-parent)]
    # Retheme if theme changes while dialog is open
    bind $d <<ThemeChanged>> [list apply {{d} {
        if {![winfo exists $d]} return
        set ac  [ttkbootstrap::getColor active]
        set bg  [ttkbootstrap::getColor bg]
        set fg  [ttkbootstrap::getColor fg]
        set fgn [ttkbootstrap::getColor fg]
        set bdr [ttkbootstrap::getColor border]
        # Title bar
        catch {
            $d.tb configure -bg $ac
            $d.tb.t configure -bg $ac -fg $fg
            $d.tb.x configure -bg $ac -fg $fg
        }
        # Location bar
        catch {
            $d.loc configure -bg $bg
            $d.loc.l configure -bg $bg -fg $fgn
        }
        # File list area
        catch {
            $d.fl configure -bg $bg
            $d.fl.lb configure -bg $bg -fg $fgn -selectbackground [ttkbootstrap::getColor selectbg] -selectforeground [ttkbootstrap::getColor selectfg]
        }
        # Buttons frame
        catch { $d.bf configure -bg $bg }
    }} $d]

    set dw [winfo reqwidth  $d]
    set dh [winfo reqheight $d]
    set gx [expr {max(0, $px + ($pw - $dw) / 2)}]
    set gy [expr {max(0, $py + ($ph - $dh) / 2)}]
    wm geometry $d +${gx}+${gy}
    wm deiconify $d
    raise $d
    grab  $d
    focus $lb

    vwait ::__fc_result
    grab release $d
    catch { destroy $d }
    return $::__fc_result
}

# ── Navigation helpers ─────────────────────────────────────────────────────────
proc _fc_goto {d mode path} {
    if {[file isdirectory $path]} {
        set ::__fc_locvar $path
        ttkbootstrap::_fc_populate $d.main.lf.lb $path $mode
    }
}

proc _fc_navigate {d mode} {
    set path $::__fc_locvar
    if {[file isdirectory $path]} {
        ttkbootstrap::_fc_populate $d.main.lf.lb $path $mode
    }
}

proc _fc_up {d mode} {
    set parent [file dirname $::__fc_locvar]
    if {$parent ne $::__fc_locvar} {
        set ::__fc_locvar $parent
        ttkbootstrap::_fc_populate $d.main.lf.lb $parent $mode
    }
}

proc _fc_refresh {d mode} {
    ttkbootstrap::_fc_populate $d.main.lf.lb $::__fc_locvar $mode
}

proc _fc_set_sort {d mode key} {
    set ::__fc_sort $key
    ttkbootstrap::_fc_populate $d.main.lf.lb $::__fc_locvar $mode
}

proc _fc_filter_changed {d lb mode} {
    ttkbootstrap::_fc_populate $lb $::__fc_locvar $mode
}

# ── Populate list ──────────────────────────────────────────────────────────────
proc _fc_populate {lb dir mode} {
    $lb delete 0 end
    set ::__fc_entries {}
    set ::__fc_locvar  $dir

    set show_hidden [expr {
        [info exists ::__fc_showhidden] && $::__fc_showhidden}]

    # Collect dirs and files
    set dirs  {}
    set files {}
    catch {
        foreach item [glob -nocomplain -directory $dir -tails *] {
            if {!$show_hidden && [string match .* $item]} continue
            set full [file join $dir $item]
            if {[file isdirectory $full]} {
                lappend dirs [list $item $full]
            } elseif {$mode eq "file"} {
                lappend files [list $item $full]
            }
        }
    }

    # Apply filetype filter to files
    if {$mode eq "file" && $::__fc_ftsel ne {}} {
        set idx [lsearch $::__fc_ftlabels $::__fc_ftsel]
        if {$idx >= 0} {
            set pats [lindex $::__fc_ftypes $idx]
            if {"*" ni $pats && $pats ne {}} {
                set filtered {}
                foreach f $files {
                    foreach pat $pats {
                        if {[string match $pat [lindex $f 0]]} {
                            lappend filtered $f; break
                        }
                    }
                }
                set files $filtered
            }
        }
    }

    # Sort
    set sort [expr {[info exists ::__fc_sort] ? $::__fc_sort : "name"}]
    switch $sort {
        date {
            set dirs  [lsort -decreasing -index 0 \
                [lmap d $dirs  {list [file mtime [lindex $d 1]] {*}$d}]]
            set files [lsort -decreasing -index 0 \
                [lmap f $files {list [file mtime [lindex $f 1]] {*}$f}]]
            set dirs  [lmap d $dirs  {lrange $d 1 end}]
            set files [lmap f $files {lrange $f 1 end}]
        }
        size {
            # Dirs first alphabetically, then files by size desc
            set dirs  [lsort -index 0 $dirs]
            set files [lsort -decreasing -index 0 \
                [lmap f $files {list [file size [lindex $f 1]] {*}$f}]]
            set files [lmap f $files {lrange $f 1 end}]
        }
        default {
            set dirs  [lsort -index 0 $dirs]
            set files [lsort -index 0 $files]
        }
    }

    # Insert dirs then files
    foreach d $dirs {
        $lb insert end "📁 [lindex $d 0]"
        lappend ::__fc_entries [list dir [lindex $d 1]]
    }
    foreach f $files {
        set sz ""
        catch {
            set bytes [file size [lindex $f 1]]
            if {$bytes > 1048576} {
                set sz "  [format %.1f [expr {$bytes/1048576.0}]] MB"
            } elseif {$bytes > 1024} {
                set sz "  [format %.1f [expr {$bytes/1024.0}]] KB"
            } else {
                set sz "  ${bytes} B"
            }
        }
        $lb insert end "   [lindex $f 0]${sz}"
        lappend ::__fc_entries [list file [lindex $f 1]]
    }
}

# ── Selection helpers ──────────────────────────────────────────────────────────
proc _fc_lb_select {lb entry mode} {
    set sel [$lb curselection]
    if {$sel eq {}} return
    set info [lindex $::__fc_entries [lindex $sel 0]]
    if {[lindex $info 0] eq "file"} {
        $entry delete 0 end
        $entry insert 0 [file tail [lindex $info 1]]
    }
}

proc _fc_activate {d lb mode} {
    set sel [$lb curselection]
    if {$sel eq {}} return
    set info [lindex $::__fc_entries [lindex $sel 0]]
    set type [lindex $info 0]
    set path [lindex $info 1]

    if {$type eq "dir"} {
        set ::__fc_locvar $path
        ttkbootstrap::_fc_populate $lb $path $mode
    } else {
        set ::__fc_result $path
    }
}

proc _fc_confirm {d lb mode} {
    if {$mode eq "dir"} {
        set sel [$lb curselection]
        if {$sel ne {}} {
            set info [lindex $::__fc_entries [lindex $sel 0]]
            if {[lindex $info 0] eq "dir"} {
                set ::__fc_result [lindex $info 1]
                return
            }
        }
        set ::__fc_result $::__fc_locvar
        return
    }
    # File mode
    set fn [string trim $::__fc_fnvar]
    if {$fn ne {}} {
        if {[file pathtype $fn] eq "absolute"} {
            set ::__fc_result $fn
        } else {
            set ::__fc_result [file join $::__fc_locvar $fn]
        }
        return
    }
    set sel [$lb curselection]
    if {$sel ne {}} {
        set info [lindex $::__fc_entries [lindex $sel 0]]
        if {[lindex $info 0] eq "file"} {
            set ::__fc_result [lindex $info 1]
            return
        }
    }
}

# ── Public API ─────────────────────────────────────────────────────────────────
proc GetOpenFile {args} {
    return [ttkbootstrap::_fc_dialog file {*}$args]
}

proc ChooseDirectory {args} {
    return [ttkbootstrap::_fc_dialog dir {*}$args]
}

} ;# end namespace ttkbootstrap
