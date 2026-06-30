# =============================================================================
# tableview.tcl — ttkbootstrap Tableview widget
#
# A feature-rich table built on Treeview with:
#   • Clickable sortable column headers
#   • Live filter/search bar
#   • Pagination (rows per page)
#   • Row striping
#   • Column show/hide
#   • Export to CSV
#
# Usage:
#   set tv [ttkbootstrap::Tableview .tv \
#       -bootstyle primary \
#       -coldata {
#           {text "Name"   stretch 1}
#           {text "Age"    stretch 0  width 60}
#           {text "City"   stretch 1}
#       } \
#       -rowdata {
#           {Alice 30 "New York"}
#           {Bob   25 "London"}
#           {Carol 35 "Sydney"}
#       } \
#       -stripecolor #f0f0f0 \
#       -pagesize 20 \
#       -searchable 1]
#
# Methods (via ${w}.<method>):
#   insert row ?index?           Add a row
#   delete row index             Delete a row by index
#   get row index                Return row values
#   get all                      Return all row data
#   clear                        Delete all rows
#   load rowdata                 Replace all rows
#   configure ?opts?             Reconfigure
# =============================================================================

namespace eval ttkbootstrap {

proc Tableview {w args} {
    array set opts {
        -bootstyle    primary
        -coldata      {}
        -rowdata      {}
        -stripecolor  {}
        -pagesize     0
        -searchable   1
        -height       15
        -selectmode   browse
    }
    array set opts $args

    set ns ::ttkbootstrap::tv::$w
    namespace eval $ns {}
    set ${ns}::opts       [array get opts]
    set ${ns}::sortcol    -1
    set ${ns}::sortdir    asc
    set ${ns}::filtertext {}
    set ${ns}::page       0
    set ${ns}::allrows    {}

    # Colours
    set primary [ttkbootstrap::getColor $opts(-bootstyle)]
    set bg      [ttkbootstrap::getColor bg]
    set fg      [ttkbootstrap::getColor fg]
    set light   [ttkbootstrap::getColor light]

    # Outer frame
    ttk::frame $w

    # ── Search bar ────────────────────────────────────────────────────────
    if {$opts(-searchable)} {
        set sbar [ttk::frame $w.sbar]
        pack $sbar -fill x -pady {0 4}

        # SVG magnifying glass icon — scales with DPI
        set _iscale [ttkbootstrap::scaleFactor]
        set _srch_svg "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>"
        append _srch_svg "<circle cx='7' cy='7' r='5' fill='none' stroke='[ttkbootstrap::getColor fg]' stroke-width='2'/>"
        append _srch_svg "<line x1='11' y1='11' x2='14' y2='14' stroke='[ttkbootstrap::getColor fg]' stroke-width='2' stroke-linecap='round'/>"
        append _srch_svg "</svg>"
        set _srch_img [image create photo ${w}::_srch_icon -data $_srch_svg -format [list svg -scale $_iscale]]
        ttk::label $sbar.lbl -image $_srch_img -padding [ttkbootstrap::_sp4 0 0 4 0]
        set svar ${ns}::filtertext
        set se [ttk::entry $sbar.e \
            -textvariable $svar \
            -style "$opts(-bootstyle).TEntry"]
        ttk::button $sbar.clr -text "✕" \
            -style "$opts(-bootstyle).Outline.TButton" \
            -padding [ttkbootstrap::_sp2 4 2] \
            -command [list ttkbootstrap::_tv_clearsearch $w]

        pack $sbar.lbl -side left
        pack $se       -side left -fill x -expand 1 -padx 2
        pack $sbar.clr -side left

        trace add variable ${ns}::filtertext write \
            [list ttkbootstrap::_tv_filter $w]
        # Remove trace when widget is destroyed
        bind $w <Destroy> [list catch \
            [list trace remove variable ${ns}::filtertext write \
                [list ttkbootstrap::_tv_filter $w]]]
    }

    # ── Treeview + scrollbars ─────────────────────────────────────────────
    set tframe [ttk::frame $w.tf]
    pack $tframe -fill both -expand 1

    # Build column ids
    set colids {}
    set coln 0
    foreach cdef $opts(-coldata) {
        lappend colids "col$coln"
        incr coln
    }

    set tree [ttk::treeview $tframe.tv \
        -columns     $colids \
        -show        headings \
        -height      $opts(-height) \
        -selectmode  $opts(-selectmode) \
        -style       "$opts(-bootstyle).Table.Treeview"]

    set vsb [ttk::scrollbar $tframe.vsb \
        -orient vertical \
        -style "$opts(-bootstyle).Vertical.TScrollbar" \
        -command [list $tree yview]]
    set hsb [ttk::scrollbar $tframe.hsb \
        -orient horizontal \
        -style "$opts(-bootstyle).Horizontal.TScrollbar" \
        -command [list $tree xview]]
    $tree configure \
        -yscrollcommand [list $vsb set] \
        -xscrollcommand [list $hsb set]

    grid $tree -row 0 -column 0 -sticky nsew
    grid $vsb  -row 0 -column 1 -sticky ns
    grid $hsb  -row 1 -column 0 -sticky ew
    grid columnconfigure $tframe 0 -weight 1
    grid rowconfigure    $tframe 0 -weight 1

    set ${ns}::tree $tree

    # Configure columns
    set coln 0
    foreach cdef $opts(-coldata) cid $colids {
        array set cd [list text {} stretch 1 width [ttkbootstrap::_sp 100] anchor w minwidth [ttkbootstrap::_sp 40]]
        array set cd $cdef
        $tree heading $cid \
            -text    $cd(text) \
            -anchor  $cd(anchor) \
            -command [list ttkbootstrap::_tv_sort $w $coln]
        $tree column $cid \
            -stretch  $cd(stretch) \
            -width    $cd(width) \
            -minwidth $cd(minwidth) \
            -anchor   $cd(anchor)
        incr coln
    }

    # Stripe tag — ensure text remains readable on dark themes
    if {$opts(-stripecolor) ne {}} {
        set _stripe_fg [ttkbootstrap::_contrastFg $opts(-stripecolor)]
        $tree tag configure stripe \
            -background $opts(-stripecolor) \
            -foreground $_stripe_fg
    }

    # ── Pagination bar ────────────────────────────────────────────────────
    if {$opts(-pagesize) > 0} {
        set pbar [ttk::frame $w.pbar]
        pack $pbar -fill x -pady {4 0}

        ttk::button $pbar.prev -text "‹ Prev" \
            -style "$opts(-bootstyle).Outline.TButton" \
            -padding [ttkbootstrap::_sp2 6 2] \
            -command [list ttkbootstrap::_tv_prevpage $w]
        ttk::button $pbar.next -text "Next ›" \
            -style "$opts(-bootstyle).Outline.TButton" \
            -padding [ttkbootstrap::_sp2 6 2] \
            -command [list ttkbootstrap::_tv_nextpage $w]

        set ${ns}::pageLabel "${ns}::pagelbl"
        ttk::label $pbar.lbl -textvariable ${ns}::pagelbl -anchor center
        set ${ns}::pagelbl "Page 1"

        pack $pbar.prev -side left
        pack $pbar.lbl  -side left -fill x -expand 1
        pack $pbar.next -side right
    }

    # Load initial data
    set ${ns}::allrows $opts(-rowdata)
    _tv_refresh $w

    # Public methods
    interp alias {} ${w}.insert    {} ttkbootstrap::_tv_insert $w
    interp alias {} ${w}.delete    {} ttkbootstrap::_tv_delete $w
    interp alias {} ${w}.get       {} ttkbootstrap::_tv_get    $w
    interp alias {} ${w}.clear     {} ttkbootstrap::_tv_clear  $w
    interp alias {} ${w}.load      {} ttkbootstrap::_tv_load   $w
    interp alias {} ${w}.selection {} $tree selection
    interp alias {} ${w}.configure {} ttkbootstrap::_tv_configure $w
    interp alias {} ${w}.export    {} ttkbootstrap::_tv_export  $w

    return $w
}

# ── Sorting ───────────────────────────────────────────────────────────────────
proc _tv_sort {w coln} {
    set ns ::ttkbootstrap::tv::$w
    set sortcol [set ${ns}::sortcol]
    set sortdir [set ${ns}::sortdir]
    array set opts [set ${ns}::opts]

    if {$sortcol == $coln} {
        set sortdir [expr {$sortdir eq "asc" ? "desc" : "asc"}]
    } else {
        set sortdir asc
    }
    set ${ns}::sortcol $coln
    set ${ns}::sortdir $sortdir

    # Sort allrows
    set rows [set ${ns}::allrows]
    set sorted [lsort -index $coln \
        {*}[expr {$sortdir eq "desc" ? "-decreasing" : ""}] \
        -dictionary $rows]
    set ${ns}::allrows $sorted

    # Update heading arrows
    set tree [set ${ns}::tree]
    set colids [$tree cget -columns]
    foreach cid $colids ci $colids {
        set idx [lsearch $colids $cid]
        set txt [$tree heading $cid -text]
        set txt [string trimright $txt " ↑↓"]
        if {$idx == $coln} {
            set arrow [expr {$sortdir eq "asc" ? " ↑" : " ↓"}]
            $tree heading $cid -text "${txt}${arrow}"
        } else {
            $tree heading $cid -text $txt
        }
    }

    _tv_refresh $w
}

# ── Filter ────────────────────────────────────────────────────────────────────
proc _tv_filter {w args} {
    if {![winfo exists $w]} return
    if {![namespace exists ::ttkbootstrap::tv::$w]} return
    set ns ::ttkbootstrap::tv::$w
    set ${ns}::page 0
    _tv_refresh $w
}

proc _tv_clearsearch {w} {
    set ns ::ttkbootstrap::tv::$w
    set ${ns}::filtertext {}
}

# ── Pagination ────────────────────────────────────────────────────────────────
proc _tv_prevpage {w} {
    set ns ::ttkbootstrap::tv::$w
    set page [set ${ns}::page]
    if {$page > 0} {
        set ${ns}::page [incr page -1]
        _tv_refresh $w
    }
}
proc _tv_nextpage {w} {
    set ns ::ttkbootstrap::tv::$w
    array set opts [set ${ns}::opts]
    set page  [set ${ns}::page]
    set rows  [_tv_filtered_rows $w]
    set total [llength $rows]
    set maxpage [expr {max(0, int(ceil($total / double($opts(-pagesize)))) - 1)}]
    if {$page < $maxpage} {
        set ${ns}::page [incr page]
        _tv_refresh $w
    }
}

proc _tv_filtered_rows {w} {
    set ns ::ttkbootstrap::tv::$w
    set filter [set ${ns}::filtertext]
    set allrows [set ${ns}::allrows]
    if {$filter eq {}} { return $allrows }
    set result {}
    foreach row $allrows {
        foreach cell $row {
            if {[string match -nocase "*${filter}*" $cell]} {
                lappend result $row
                break
            }
        }
    }
    return $result
}

# ── Main render ───────────────────────────────────────────────────────────────
proc _tv_refresh {w} {
    set ns ::ttkbootstrap::tv::$w
    array set opts [set ${ns}::opts]
    set tree [set ${ns}::tree]
    set page [set ${ns}::page]

    $tree delete [$tree children {}]

    set rows [_tv_filtered_rows $w]
    set total [llength $rows]

    if {$opts(-pagesize) > 0} {
        set ps    $opts(-pagesize)
        set start [expr {$page * $ps}]
        set end   [expr {min($start + $ps, $total) - 1}]
        set rows  [lrange $rows $start $end]
        set maxpage [expr {max(1, int(ceil($total / double($ps))))}]
        catch { set ${ns}::pagelbl "Page [expr {$page+1}] of $maxpage  ($total rows)" }
    }

    set rowidx 0
    foreach row $rows {
        set tags {}
        if {$opts(-stripecolor) ne {} && ($rowidx % 2 == 1)} {
            set tags stripe
        }
        $tree insert {} end -values $row -tags $tags
        incr rowidx
    }
}

# ── Data methods ──────────────────────────────────────────────────────────────
proc _tv_insert {w row {index end}} {
    set ns ::ttkbootstrap::tv::$w
    set rows [set ${ns}::allrows]
    if {$index eq "end"} {
        lappend rows $row
    } else {
        set rows [linsert $rows $index $row]
    }
    set ${ns}::allrows $rows
    _tv_refresh $w
}

proc _tv_delete {w index} {
    set ns ::ttkbootstrap::tv::$w
    set rows [set ${ns}::allrows]
    set rows [lreplace $rows $index $index]
    set ${ns}::allrows $rows
    _tv_refresh $w
}

proc _tv_get {w what {index 0}} {
    set ns ::ttkbootstrap::tv::$w
    if {$what eq "all"} {
        return [set ${ns}::allrows]
    } elseif {$what eq "row"} {
        return [lindex [set ${ns}::allrows] $index]
    }
}

proc _tv_clear {w} {
    set ns ::ttkbootstrap::tv::$w
    set ${ns}::allrows {}
    _tv_refresh $w
}

proc _tv_load {w rowdata} {
    set ns ::ttkbootstrap::tv::$w
    set ${ns}::allrows $rowdata
    set ${ns}::page 0
    _tv_refresh $w
}

proc _tv_configure {w args} {
    set ns ::ttkbootstrap::tv::$w
    array set opts [set ${ns}::opts]
    array set opts $args
    set ${ns}::opts [array get opts]
    _tv_refresh $w
}

proc _tv_export {w {filename {}}} {
    set ns ::ttkbootstrap::tv::$w
    set tree [set ${ns}::tree]

    set colids [$tree cget -columns]
    set headers {}
    foreach cid $colids {
        set h [$tree heading $cid -text]
        set h [string trimright $h " ↑↓"]
        lappend headers "\"$h\""
    }

    set lines [list [join $headers ","]]
    foreach row [set ${ns}::allrows] {
        set cells {}
        foreach cell $row { lappend cells "\"$cell\"" }
        lappend lines [join $cells ","]
    }

    set csv [join $lines "\n"]

    if {$filename eq {}} {
        set filename [tk_getSaveFile \
            -defaultextension .csv \
            -filetypes {{"CSV Files" .csv} {"All Files" *}}]
    }
    if {$filename ne {}} {
        set fh [open $filename w]
        puts $fh $csv
        close $fh
    }
    return $csv
}

} ;# end namespace

# =============================================================================
# TableColumn — represents a column in a Tableview
#
#   set col [ttkbootstrap::TableColumn .tv 0]
#   $col header                 → column header text
#   $col header "New Name"      → set header text
#   $col width                  → column width
#   $col width 120              → set column width
#   $col visible                → 1/0
#   $col visible 0              → hide column
#   $col stretch                → 1/0
#   $col stretch 1              → allow stretch
#   $col index                  → column index
# =============================================================================
namespace eval ttkbootstrap {

proc TableColumn {tableview colindex} {
    set id "::ttkbootstrap::_tc_[clock milliseconds]_${colindex}"
    namespace eval $id {}
    set ${id}::tv    $tableview
    set ${id}::colix $colindex

    proc ${id}::header {{newval "__QUERY__"}} \
        [list apply {{tv colix newval} {
            set ns ::ttkbootstrap::tv::$tv
            set tree [set ${ns}::tree]
            set cols [$tree cget -columns]
            set cid  [lindex $cols $colix]
            if {$cid eq ""} { error "Column $colix out of range" }
            if {$newval eq "__QUERY__"} {
                set h [$tree heading $cid -text]
                return [string trimright $h " ↑↓"]
            } else {
                $tree heading $cid -text $newval
            }
        }} $tableview $colindex]

    proc ${id}::width {{newval "__QUERY__"}} \
        [list apply {{tv colix newval} {
            set ns ::ttkbootstrap::tv::$tv
            set tree [set ${ns}::tree]
            set cols [$tree cget -columns]
            set cid  [lindex $cols $colix]
            if {$cid eq ""} { error "Column $colix out of range" }
            if {$newval eq "__QUERY__"} {
                return [$tree column $cid -width]
            } else {
                $tree column $cid -width $newval
            }
        }} $tableview $colindex]

    proc ${id}::visible {{newval "__QUERY__"}} \
        [list apply {{tv colix newval} {
            set ns ::ttkbootstrap::tv::$tv
            set tree [set ${ns}::tree]
            set cols [$tree cget -columns]
            set cid  [lindex $cols $colix]
            if {$cid eq ""} { error "Column $colix out of range" }
            if {$newval eq "__QUERY__"} {
                set w [$tree column $cid -width]
                return [expr {$w > 0 ? 1 : 0}]
            } else {
                if {$newval} {
                    $tree column $cid -width [ttkbootstrap::_sp 100] -minwidth [ttkbootstrap::_sp 30]
                } else {
                    $tree column $cid -width 0 -minwidth 0
                }
            }
        }} $tableview $colindex]

    proc ${id}::stretch {{newval "__QUERY__"}} \
        [list apply {{tv colix newval} {
            set ns ::ttkbootstrap::tv::$tv
            set tree [set ${ns}::tree]
            set cols [$tree cget -columns]
            set cid  [lindex $cols $colix]
            if {$cid eq ""} { error "Column $colix out of range" }
            if {$newval eq "__QUERY__"} {
                return [$tree column $cid -stretch]
            } else {
                $tree column $cid -stretch $newval
            }
        }} $tableview $colindex]

    proc ${id}::index {} \
        [list apply {{colix} { return $colix }} $colindex]

    return $id
}

# =============================================================================
# TableRow — represents a row in a Tableview
#
#   set row [ttkbootstrap::TableRow .tv 2]
#   $row values                 → list of cell values
#   $row values {a b c}        → update all cells
#   $row index                  → row index
#   $row delete                 → delete this row
#   $row select                 → select this row
# =============================================================================
proc TableRow {tableview rowindex} {
    set id "::ttkbootstrap::_tr_[clock milliseconds]_${rowindex}"
    namespace eval $id {}
    set ${id}::tv    $tableview
    set ${id}::rowix $rowindex

    proc ${id}::values {{newval "__QUERY__"}} \
        [list apply {{tv rowix newval} {
            set ns ::ttkbootstrap::tv::$tv
            set allrows [set ${ns}::allrows]
            if {$rowix < 0 || $rowix >= [llength $allrows]} {
                error "Row $rowix out of range"
            }
            if {$newval eq "__QUERY__"} {
                return [lindex $allrows $rowix]
            } else {
                lset ${ns}::allrows $rowix $newval
                ttkbootstrap::_tv_render $tv
            }
        }} $tableview $rowindex]

    proc ${id}::index {} \
        [list apply {{rowix} { return $rowix }} $rowindex]

    proc ${id}::delete {} \
        [list apply {{tv rowix} {
            set ns ::ttkbootstrap::tv::$tv
            set allrows [set ${ns}::allrows]
            set ${ns}::allrows [lreplace $allrows $rowix $rowix]
            ttkbootstrap::_tv_render $tv
        }} $tableview $rowindex]

    proc ${id}::select {} \
        [list apply {{tv rowix} {
            set ns ::ttkbootstrap::tv::$tv
            set tree [set ${ns}::tree]
            set items [$tree children {}]
            set item [lindex $items $rowix]
            if {$item ne ""} {
                $tree selection set $item
                $tree see $item
            }
        }} $tableview $rowindex]

    return $id
}

} ;# end namespace
