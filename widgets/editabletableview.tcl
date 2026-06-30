# =============================================================================
# editabletableview.tcl — Tableview with double-click in-place cell editing
#
# USAGE
#   set tv [ttkbootstrap::EditableTableview .tv \
#       -coldata {
#           {text "Name"   stretch 1}
#           {text "Email"  stretch 1}
#           {text "Role"   stretch 0 width 120}
#       } \
#       -rowdata {Alice alice@example.com Admin
#                 Bob   bob@example.com   User} \
#       -bootstyle  primary \
#       -editcolumns {0 1 2}]
#   pack $tv -fill both -expand 1
#
#   # Get current data (all rows)
#   set data [ttkbootstrap::EditableTableview::getdata .tv]
#
#   # Get a specific cell
#   set val [ttkbootstrap::EditableTableview::getcell .tv $rowid $colindex]
#
#   # Set a specific cell
#   ttkbootstrap::EditableTableview::setcell .tv $rowid $colindex "New Value"
#
#   # Called when a cell edit is committed
#   -editcommand { puts "Edited row=$rowid col=$colindex val=$newval" }
#
# OPTIONS  (all Tableview options, plus:)
#   -editcolumns  list  0-based column indices that are editable (default: all)
#   -editcommand  script Called after cell edit. Variables $rowid $colindex $newval
#                        are available via [list apply].
#   -validate     script Called before commit. Must return 1 (accept) or 0 (reject).
#                        Receives same variables as -editcommand.
#
# METHODS
#   EditableTableview::getdata  tv           → list of row value lists
#   EditableTableview::getrow   tv rowid     → list of values for one row
#   EditableTableview::getcell  tv rowid col → single cell value
#   EditableTableview::setcell  tv rowid col val → update a cell
#   EditableTableview::cancelEdit tv         → dismiss editor without committing
# =============================================================================

namespace eval ttkbootstrap {

proc EditableTableview {w args} {
    # Separate our options from Tableview options
    array set opts {
        -editcolumns  {}
        -editcommand  {}
        -validate     {}
    }
    # Extract our options, pass rest to Tableview
    set tv_args {}
    set coldata {}
    foreach {k v} $args {
        switch -- $k {
            -editcolumns  { set opts(-editcolumns)  $v }
            -editcommand  { set opts(-editcommand)  $v }
            -validate     { set opts(-validate)     $v }
            -coldata      { set coldata $v; lappend tv_args $k $v }
            default       { lappend tv_args $k $v }
        }
    }

    # Normalise -rowdata: accept both flat {v1 v2 v3 v4 v5 v6} and
    # pre-chunked {{v1 v2 v3} {v4 v5 v6}} formats.
    set ncols [llength $coldata]
    if {$ncols > 0} {
        set rd_idx [lsearch $tv_args -rowdata]
        if {$rd_idx >= 0} {
            set rowdata [lindex $tv_args [expr {$rd_idx + 1}]]
            # Already chunked if first element is itself a list of ncols items
            set first [lindex $rowdata 0]
            if {[llength $rowdata] > 0 && [llength $first] == $ncols} {
                # Already nested — pass through unchanged
            } else {
                # Flat — chunk into rows of ncols items
                set chunked {}
                set chunk {}
                set i 0
                foreach v $rowdata {
                    lappend chunk $v
                    incr i
                    if {$i == $ncols} {
                        lappend chunked $chunk
                        set chunk {}
                        set i 0
                    }
                }
                if {$chunked ne {}} {
                    lset tv_args [expr {$rd_idx + 1}] $chunked
                }
            }
        }
    }

    # Build base Tableview
    set tv [ttkbootstrap::Tableview $w {*}$tv_args]

    set ns ::ttkbootstrap::etv::$w
    namespace eval $ns {}
    set ${ns}::opts     [array get opts]
    set ${ns}::editor   {}    ;# current editor widget path
    set ${ns}::edit_row {}    ;# rowid being edited
    set ${ns}::edit_col {}    ;# column index being edited
    set ${ns}::coldata  $coldata

    # Get the underlying treeview
    set tree [set ::ttkbootstrap::tv::${w}::tree]
    set ${ns}::tree $tree

    # Bind double-click to start editing
    bind $tree <Double-Button-1> [list ttkbootstrap::_etv_start_edit $w %x %y]

    # Bind Escape to cancel
    bind $tree <Escape> [list ttkbootstrap::EditableTableview::cancelEdit $w]

    return $tv
}

proc _etv_start_edit {w x y} {
    set ns ::ttkbootstrap::etv::$w
    array set o [set ${ns}::opts]
    set tree [set ${ns}::tree]

    # Cancel any existing editor first
    _etv_cancel $w

    # Identify what was clicked
    set region [$tree identify region $x $y]
    if {$region ne "cell"} return

    set rowid [$tree identify row  $x $y]
    set col   [$tree identify column $x $y]
    if {$rowid eq {} || $col eq {}} return

    # Convert column id (#1, #2...) to 0-based index
    set colids [$tree cget -columns]
    set colidx [lsearch $colids $col]
    if {$colidx < 0} {
        # #1 = first data column
        set colidx [expr {[string range $col 1 end] - 1}]
    }

    # Check if this column is editable
    set edcols $o(-editcolumns)
    if {$edcols ne {} && $colidx ni $edcols} return

    set ${ns}::edit_row $rowid
    set ${ns}::edit_col $colidx

    # Get current cell value
    set vals [$tree item $rowid -values]
    set curval [lindex $vals $colidx]

    # Get cell bbox for positioning the editor
    set bbox [$tree bbox $rowid $col]
    if {$bbox eq {}} return
    lassign $bbox bx by bw bh

    # Create floating entry widget
    set entry [ttk::entry $tree.__editor \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12]]]
    $entry insert 0 $curval
    $entry selection range 0 end

    place $entry -in $tree -x $bx -y $by -width $bw -height $bh

    focus $entry
    set ${ns}::editor $entry

    # Commit on Return or Tab; cancel on Escape
    bind $entry <Return>    [list ttkbootstrap::_etv_commit $w]
    bind $entry <Tab>       [list ttkbootstrap::_etv_commit_and_next $w]
    bind $entry <Escape>    [list ttkbootstrap::_etv_cancel $w]
    bind $entry <FocusOut>  [list after 100 [list ttkbootstrap::_etv_commit $w]]
}

proc _etv_commit {w} {
    set ns ::ttkbootstrap::etv::$w
    set editor [set ${ns}::editor]
    if {$editor eq {} || ![winfo exists $editor]} return

    array set o [set ${ns}::opts]
    set rowid  [set ${ns}::edit_row]
    set colidx [set ${ns}::edit_col]
    set newval [$editor get]
    set tree   [set ${ns}::tree]

    # Validate
    if {$o(-validate) ne {}} {
        set ok [uplevel #0 [list apply \
            [list {rowid colindex newval} $o(-validate)] \
            $rowid $colidx $newval]]
        if {!$ok} {
            _etv_cancel $w
            return
        }
    }

    # Update the treeview
    set vals [$tree item $rowid -values]
    lset vals $colidx $newval
    $tree item $rowid -values $vals

    # Fire callback
    if {$o(-editcommand) ne {}} {
        uplevel #0 [list apply \
            [list {rowid colindex newval} $o(-editcommand)] \
            $rowid $colidx $newval]
    }

    _etv_destroy_editor $w
}

proc _etv_commit_and_next {w} {
    set ns ::ttkbootstrap::etv::$w
    set colidx [set ${ns}::edit_col]
    set rowid  [set ${ns}::edit_row]
    set tree   [set ${ns}::tree]

    _etv_commit $w

    # Move to next column; wrap to next row
    set colids [$tree cget -columns]
    set ncols  [llength $colids]
    set next_col [expr {$colidx + 1}]

    if {$next_col >= $ncols} {
        # Next row, first column
        set next_col 0
        set rows [$tree children {}]
        set ri [lsearch $rows $rowid]
        if {$ri >= 0 && $ri < [llength $rows]-1} {
            set rowid [lindex $rows [expr {$ri+1}]]
        } else { return }
    }

    # Simulate a click on that cell
    set col [lindex $colids $next_col]
    set bbox [$tree bbox $rowid $col]
    if {$bbox ne {}} {
        lassign $bbox bx by bw bh
        # Call start_edit directly with coordinates inside that bbox
        ttkbootstrap::_etv_start_edit $w \
            [expr {$bx + $bw/2}] [expr {$by + $bh/2}]
    }
}

proc _etv_cancel {w} {
    _etv_destroy_editor $w
}

proc _etv_destroy_editor {w} {
    set ns ::ttkbootstrap::etv::$w
    if {![namespace exists $ns]} return
    set editor [set ${ns}::editor]
    if {$editor ne {} && [winfo exists $editor]} {
        destroy $editor
    }
    set ${ns}::editor   {}
    set ${ns}::edit_row {}
    set ${ns}::edit_col {}
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::EditableTableview {}

proc ttkbootstrap::EditableTableview::cancelEdit {w} {
    ttkbootstrap::_etv_destroy_editor $w
}

proc ttkbootstrap::EditableTableview::getdata {w} {
    set ns   ::ttkbootstrap::etv::$w
    set tree [set ${ns}::tree]
    set result {}
    foreach rowid [$tree children {}] {
        lappend result [$tree item $rowid -values]
    }
    return $result
}

proc ttkbootstrap::EditableTableview::getrow {w rowid} {
    set ns   ::ttkbootstrap::etv::$w
    set tree [set ${ns}::tree]
    return [$tree item $rowid -values]
}

proc ttkbootstrap::EditableTableview::getcell {w rowid colidx} {
    set ns   ::ttkbootstrap::etv::$w
    set tree [set ${ns}::tree]
    return [lindex [$tree item $rowid -values] $colidx]
}

proc ttkbootstrap::EditableTableview::setcell {w rowid colidx val} {
    set ns   ::ttkbootstrap::etv::$w
    set tree [set ${ns}::tree]
    set vals [$tree item $rowid -values]
    lset vals $colidx $val
    $tree item $rowid -values $vals
}
