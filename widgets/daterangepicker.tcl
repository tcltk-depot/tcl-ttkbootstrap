# =============================================================================
# daterangepicker.tcl — Two linked calendars for start/end date selection
#
# USAGE
#   set drp [ttkbootstrap::DateRangePicker .drp \
#       -bootstyle   primary \
#       -startvar    ::start_date \
#       -endvar      ::end_date \
#       -command     { puts "Range: $::start_date to $::end_date" } \
#       -dateformat  "%Y-%m-%d"]
#   pack $drp -fill x
#
#   # Get current range as a list {start end}
#   set range [ttkbootstrap::DateRangePicker::get .drp]
#   set start [ttkbootstrap::DateRangePicker::start .drp]
#   set end   [ttkbootstrap::DateRangePicker::end   .drp]
#
#   # Set programmatically
#   ttkbootstrap::DateRangePicker::set .drp "2024-01-01" "2024-01-31"
#
# OPTIONS
#   -bootstyle   color    Calendar accent colour  (default: primary)
#   -startvar    varname  Variable for start date string
#   -endvar      varname  Variable for end date string
#   -command     script   Called when both dates are selected
#   -dateformat  string   strftime format for date strings (default: %Y-%m-%d)
#   -firstweekday 0|1     0=Sunday first, 1=Monday first (default: 0)
#   -allowpast   0|1      Allow past dates (default: 1)
#   -mindate     list     {year month day} minimum selectable date
#   -maxdate     list     {year month day} maximum selectable date
#
# METHODS
#   DateRangePicker::get   drp         → {start end} formatted date list
#   DateRangePicker::start drp         → formatted start date string
#   DateRangePicker::end   drp         → formatted end date string
#   DateRangePicker::clear drp         → clear both selections
#   DateRangePicker::set   drp s e     → set start/end programmatically
# =============================================================================

namespace eval ttkbootstrap {

proc DateRangePicker {w args} {
    array set opts {
        -bootstyle    primary
        -startvar     {}
        -endvar       {}
        -command      {}
        -dateformat   {%Y-%m-%d}
        -firstweekday 0
        -allowpast    1
        -mindate      {}
        -maxdate      {}
    }
    array set opts $args

    set ns ::ttkbootstrap::drp::$w
    namespace eval $ns {}
    # Store each option as a separate namespace variable
    foreach {k v} [array get opts] {
        set ${ns}::opt$k $v
    }
    set ${ns}::start_sel  {}   ;# {year month day} or {}
    set ${ns}::end_sel    {}
    set ${ns}::picking    start  ;# which end is being picked: start|end

    # Private variables if none supplied
    if {$opts(-startvar) eq {}} {
        set ${ns}::start_str {}
        set ${ns}::opt-startvar ${ns}::start_str
    }
    if {$opts(-endvar) eq {}} {
        set ${ns}::end_str {}
        set ${ns}::opt-endvar ${ns}::end_str
    }

    # Outer frame
    set f [ttk::frame $w]

    # Header row: start label — end label, clear button
    set hdr [ttk::frame $f.hdr -padding [ttkbootstrap::_sp2 4 4]]
    pack $hdr -fill x

    ttk::label $hdr.sl -text "From:" -anchor w \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 11] bold]
    set start_disp [ttk::label $hdr.sd \
        -text        "—" \
        -foreground  [ttkbootstrap::getColor $opts(-bootstyle)] \
        -font        [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                          [ttkbootstrap::_sf 11]]]

    ttk::label $hdr.arrow -text " → " \
        -foreground [ttkbootstrap::getColor secondary]

    ttk::label $hdr.el -text "To:" -anchor w \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 11] bold]
    set end_disp [ttk::label $hdr.ed \
        -text        "—" \
        -foreground  [ttkbootstrap::getColor secondary] \
        -font        [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                          [ttkbootstrap::_sf 11]]]

    ttk::button $hdr.clear -text "Clear" \
        -style   "secondary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 6 2] \
        -command [list ttkbootstrap::DateRangePicker::clear $w]

    pack $hdr.sl $hdr.sd $hdr.arrow $hdr.el $hdr.ed -side left \
        -padx [ttkbootstrap::_sp 4]
    pack $hdr.clear -side right -padx [ttkbootstrap::_sp 4]

    set ${ns}::start_disp $start_disp
    set ${ns}::end_disp   $end_disp

    # Picking mode indicator
    set pick_lbl [ttk::label $f.pick \
        -text       "Select start date" \
        -foreground [ttkbootstrap::getColor $opts(-bootstyle)] \
        -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                         [ttkbootstrap::_sf 11]]]
    pack $pick_lbl -anchor w -padx [ttkbootstrap::_sp 8] -pady [ttkbootstrap::_sp2 0 4]
    set ${ns}::pick_lbl $pick_lbl

    # Two-calendar row
    set cals [ttk::frame $f.cals -padding [ttkbootstrap::_sp 4]]
    pack $cals -fill x

    # Build left calendar (start month)
    set today [ttkbootstrap::_date_today]
    lassign $today ty tm td

    # Left calendar popup frame
    set lf [ttk::frame $cals.left]
    set rf [ttk::frame $cals.right]
    pack $lf -side left -padx [ttkbootstrap::_sp 8]
    pack $rf -side left -padx [ttkbootstrap::_sp 8]

    # Build the two calendars
    _drp_build_cal $w $lf start $ty $tm $opts(-firstweekday) $opts(-bootstyle)
    # Right calendar: next month
    set rm [expr {$tm % 12 + 1}]
    set ry [expr {$rm == 1 ? $ty + 1 : $ty}]
    _drp_build_cal $w $rf end $ry $rm $opts(-firstweekday) $opts(-bootstyle)

    set ${ns}::left_frame  $lf
    set ${ns}::right_frame $rf

    # Footer: Quick selection buttons
    set foot [ttk::frame $f.foot -padding [ttkbootstrap::_sp2 8 4]]
    pack $foot -fill x

    ttk::label $foot.lbl -text "Quick:" \
        -foreground [ttkbootstrap::getColor secondary] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 11]]
    pack $foot.lbl -side left

    foreach {label days} {
        "7 days"  7
        "30 days" 30
        "90 days" 90
        "This month" 0
        "This year"  -1
    } {
        ttk::button $foot.q$days \
            -text    $label \
            -style   "$opts(-bootstyle).Outline.TButton" \
            -padding [ttkbootstrap::_sp2 6 2] \
            -command [list ttkbootstrap::_drp_quickset $w $days]
        pack $foot.q$days -side left -padx [ttkbootstrap::_sp 2]
    }

    bind $f <<ThemeChanged>> [list ttkbootstrap::_drp_restyle $w]
    # Clean up namespace when widget is destroyed (prevents stale data on rebuild)
    bind $f <Destroy> [list catch [list namespace delete ::ttkbootstrap::drp::$w]]

    return $f
}

proc _drp_build_cal {w frame side year month firstweekday bootstyle} {
    set ns  ::ttkbootstrap::drp::$w
    set dns ::ttkbootstrap::drp::${w}::cal_$side
    namespace eval $dns {}
    set ${dns}::year  $year
    set ${dns}::month $month
    set ${dns}::side  $side

    # Header with prev/next month nav
    set hdr [ttk::frame $frame.hdr]
    pack $hdr -fill x -pady [ttkbootstrap::_sp 4]

    set prev_cmd [list ttkbootstrap::_drp_nav $w $side prev]
    set next_cmd [list ttkbootstrap::_drp_nav $w $side next]

    ttk::button $hdr.prev \
        -text    "‹" \
        -style   "$bootstyle.TButton" \
        -padding [ttkbootstrap::_sp2 4 2] \
        -command $prev_cmd

    set mon_lbl [ttk::label $hdr.mon \
        -text   [_drp_month_label $year $month] \
        -anchor center \
        -font   [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                      [ttkbootstrap::_sf 12] bold]]
    ttk::button $hdr.next \
        -text    "›" \
        -style   "$bootstyle.TButton" \
        -padding [ttkbootstrap::_sp2 4 2] \
        -command $next_cmd

    pack $hdr.prev -side left
    pack $hdr.mon  -side left -fill x -expand 1
    pack $hdr.next -side right

    set ${dns}::mon_lbl $mon_lbl
    set ${dns}::frame   $frame

    # Day-of-week headers
    set dow_row [ttk::frame $frame.dow]
    pack $dow_row -fill x

    set days {Su Mo Tu We Th Fr Sa}
    if {$firstweekday == 1} { set days {Mo Tu We Th Fr Sa Su} }
    foreach d $days {
        ttk::label $dow_row.d$d \
            -text       $d \
            -width      3 \
            -anchor     center \
            -foreground [ttkbootstrap::getColor secondary] \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                              [ttkbootstrap::_sf 10] bold]
        pack $dow_row.d$d -side left -padx [ttkbootstrap::_sp 1]
    }

    # Day buttons grid
    set grid [ttk::frame $frame.grid]
    pack $grid -fill x

    set ${dns}::grid $grid
    _drp_render $w $side
}

proc _drp_month_label {year month} {
    set months {January February March April May June
                July August September October November December}
    return "[lindex $months [expr {$month-1}]] $year"
}

proc _drp_render {w side} {
    if {![winfo exists $w]} return
    set ns  ::ttkbootstrap::drp::$w
    set dns ::ttkbootstrap::drp::${w}::cal_$side
    array set o [list {*}[list -bootstyle [set ${ns}::opt-bootstyle] -startvar [set ${ns}::opt-startvar] -endvar [set ${ns}::opt-endvar] -command [set ${ns}::opt-command] -dateformat [set ${ns}::opt-dateformat] -firstweekday [set ${ns}::opt-firstweekday]]]

    set year   [set ${dns}::year]
    set month  [set ${dns}::month]
    set grid   [set ${dns}::grid]
    set mon_lbl [set ${dns}::mon_lbl]

    # Update month label
    $mon_lbl configure -text [_drp_month_label $year $month]

    # Clear existing buttons
    foreach child [winfo children $grid] { destroy $child }

    set start_sel [set ${ns}::start_sel]
    set end_sel   [set ${ns}::end_sel]

    set today   [ttkbootstrap::_date_today]
    lassign $today ty tm td

    set bg_hex   [ttkbootstrap::getColor bg]
    set fg_hex   [ttkbootstrap::getColor fg]
    set sel_hex  [ttkbootstrap::getColor $o(-bootstyle)]
    set sel_fg   [ttkbootstrap::_contrastFg $sel_hex]
    set rng_hex  [ttkbootstrap::Colors::update_hsv $sel_hex -sd -0.4 -vd 0.3]
    set sec_hex  [ttkbootstrap::getColor secondary]
    set bdr_hex  [ttkbootstrap::getColor border]
    set lgt_hex  [ttkbootstrap::getColor light]

    set fwd    [expr {[set ${ns}::opt-firstweekday] == 1 ? 1 : 0}]
    set first  [ttkbootstrap::_date_dow $year $month 1]
    set startcol [expr {($first - $fwd + 7) % 7}]
    set dim    [ttkbootstrap::_date_dim $year $month]
    set sz     [ttkbootstrap::_sp 28]
    set font   [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                     [ttkbootstrap::_sf 11]]

    set row 0
    set col $startcol

    for {set day 1} {$day <= $dim} {incr day} {
        set date [list $year $month $day]

        # Determine state
        set is_today   [expr {$year==$ty && $month==$tm && $day==$td}]
        set is_start   [expr {$start_sel ne {} && $date eq $start_sel}]
        set is_end     [expr {$end_sel   ne {} && $date eq $end_sel}]
        set in_range   [_drp_in_range $date $start_sel $end_sel]

        # Choose colours
        if {$is_start || $is_end} {
            set bg $sel_hex; set fg $sel_fg
        } elseif {$in_range} {
            set bg $rng_hex; set fg $fg_hex
        } elseif {$is_today} {
            set bg $lgt_hex; set fg $fg_hex
        } else {
            set bg $bg_hex; set fg $fg_hex
        }

        set btn [label $grid.d${row}_${col} \
            -text       $day \
            -background $bg \
            -foreground $fg \
            -font       $font \
            -width      2 \
            -anchor     center \
            -relief     [expr {$is_start||$is_end ? "flat" : "flat"}] \
            -padx       [ttkbootstrap::_sp 2] \
            -pady       [ttkbootstrap::_sp 3] \
            -cursor     hand2]

        grid $btn -row $row -column $col \
            -padx [ttkbootstrap::_sp 1] -pady [ttkbootstrap::_sp 1]

        bind $btn <Button-1> [list ttkbootstrap::_drp_click $w $date]
        bind $btn <Enter>    [list $btn configure -background $lgt_hex]
        bind $btn <Leave>    [list $btn configure -background $bg]

        incr col
        if {$col > 6} { set col 0; incr row }
    }
}

proc _drp_in_range {date start_sel end_sel} {
    if {$start_sel eq {} || $end_sel eq {}} { return 0 }
    lassign $date  y  m  d
    lassign $start_sel sy sm sd
    lassign $end_sel   ey em ed
    set dn  [expr {$y*10000  + $m*100  + $d}]
    set s   [expr {$sy*10000 + $sm*100 + $sd}]
    set e   [expr {$ey*10000 + $em*100 + $ed}]
    return  [expr {$dn > $s && $dn < $e}]
}

proc _drp_click {w date} {
    if {![winfo exists $w]} return
    if {![namespace exists ::ttkbootstrap::drp::$w]} return
    set ns ::ttkbootstrap::drp::$w
    set picking [set ${ns}::picking]

    if {$picking eq "start"} {
        set ${ns}::start_sel $date
        set ${ns}::end_sel   {}
        set ${ns}::picking   end
        _drp_update_display $w
        [set ${ns}::pick_lbl] configure -text "Select end date"
    } else {
        # Ensure end >= start
        set start [set ${ns}::start_sel]
        lassign $date ey em ed
        lassign $start sy sm sd
        set dn [expr {$ey*10000 + $em*100 + $ed}]
        set ds [expr {$sy*10000 + $sm*100 + $sd}]
        if {$dn < $ds} {
            # Clicked before start — swap: new start is this date
            set ${ns}::start_sel $date
            _drp_update_display $w
            return
        }
        set ${ns}::end_sel $date
        set ${ns}::picking start
        _drp_update_display $w
        _drp_notify $w
        [set ${ns}::pick_lbl] configure -text "Range selected — click to change start"
    }

    # Re-render both calendars
    _drp_render $w start
    _drp_render $w end
}

proc _drp_nav {w side dir} {
    set dns ::ttkbootstrap::drp::${w}::cal_$side
    set year  [set ${dns}::year]
    set month [set ${dns}::month]

    if {$dir eq "prev"} {
        incr month -1
        if {$month < 1} { set month 12; incr year -1 }
    } else {
        incr month
        if {$month > 12} { set month 1; incr year }
    }
    set ${dns}::year  $year
    set ${dns}::month $month
    _drp_render $w $side
}

proc _drp_update_display {w} {
    set ns ::ttkbootstrap::drp::$w
    array set o [list {*}[list -bootstyle [set ${ns}::opt-bootstyle] -startvar [set ${ns}::opt-startvar] -endvar [set ${ns}::opt-endvar] -command [set ${ns}::opt-command] -dateformat [set ${ns}::opt-dateformat] -firstweekday [set ${ns}::opt-firstweekday]]]

    set start [set ${ns}::start_sel]
    set end   [set ${ns}::end_sel]
    set fmt   $o(-dateformat)

    set sd [set ${ns}::start_disp]
    set ed [set ${ns}::end_disp]
    set sv [set ${ns}::opt-startvar]
    set ev [set ${ns}::opt-endvar]

    if {$start ne {}} {
        lassign $start y m d
        set str [ttkbootstrap::_date_format $y $m $d $fmt]
        $sd configure -text $str
        set $sv $str
    } else {
        $sd configure -text "—"
        set $sv {}
    }
    if {$end ne {}} {
        lassign $end y m d
        set str [ttkbootstrap::_date_format $y $m $d $fmt]
        $ed configure -text $str
        set $ev $str
    } else {
        $ed configure -text "—"
        set $ev {}
    }
}

proc _drp_notify {w} {
    set ns ::ttkbootstrap::drp::$w
    array set o [list {*}[list -bootstyle [set ${ns}::opt-bootstyle] -startvar [set ${ns}::opt-startvar] -endvar [set ${ns}::opt-endvar] -command [set ${ns}::opt-command] -dateformat [set ${ns}::opt-dateformat] -firstweekday [set ${ns}::opt-firstweekday]]]
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _drp_quickset {w days} {
    set ns ::ttkbootstrap::drp::$w
    set today [ttkbootstrap::_date_today]
    lassign $today ty tm td

    if {$days == 0} {
        # This month
        set start [list $ty $tm 1]
        set end   [list $ty $tm [ttkbootstrap::_date_dim $ty $tm]]
    } elseif {$days == -1} {
        # This year
        set start [list $ty 1 1]
        set end   [list $ty 12 31]
    } else {
        set start $today
        # End = today + days
        set end_time [clock add [clock scan "$ty-$tm-$td"] $days days]
        set end [list \
            [clock format $end_time -format %Y] \
            [clock format $end_time -format %m] \
            [clock format $end_time -format %d]]
    }

    set ${ns}::start_sel $start
    set ${ns}::end_sel   $end
    set ${ns}::picking   start
    _drp_update_display $w
    _drp_notify $w
    _drp_render $w start
    _drp_render $w end
    [set ${ns}::pick_lbl] configure -text "Range selected — click to change start"
}

proc _drp_restyle {w} {
    set ns ::ttkbootstrap::drp::$w
    if {![namespace exists $ns]} return
    _drp_render $w start
    _drp_render $w end
}

} ;# end namespace ttkbootstrap

namespace eval ttkbootstrap::DateRangePicker {}

proc ttkbootstrap::DateRangePicker::get {w} {
    ::set ns ::ttkbootstrap::drp::$w
    array set o [list {*}[list -bootstyle [::set ${ns}::opt-bootstyle] -startvar [::set ${ns}::opt-startvar] -endvar [::set ${ns}::opt-endvar] -command [::set ${ns}::opt-command] -dateformat [::set ${ns}::opt-dateformat] -firstweekday [::set ${ns}::opt-firstweekday]]]
    return [list [::set $o(-startvar)] [::set $o(-endvar)]]
}

proc ttkbootstrap::DateRangePicker::start {w} {
    ::set ns ::ttkbootstrap::drp::$w
    return [::set [::set ${ns}::opt-startvar]]
}

proc ttkbootstrap::DateRangePicker::end {w} {
    ::set ns ::ttkbootstrap::drp::$w
    return [::set [::set ${ns}::opt-endvar]]
}

proc ttkbootstrap::DateRangePicker::clear {w} {
    ::set ns ::ttkbootstrap::drp::$w
    ::set ${ns}::start_sel {}
    ::set ${ns}::end_sel   {}
    ::set ${ns}::picking   start
    ttkbootstrap::_drp_update_display $w
    ttkbootstrap::_drp_render $w start
    ttkbootstrap::_drp_render $w end
    [::set ${ns}::pick_lbl] configure -text "Select start date"
}

proc ttkbootstrap::DateRangePicker::set {w start_str end_str} {
    ::set ns ::ttkbootstrap::drp::$w
    array set o [list {*}[list -bootstyle [::set ${ns}::opt-bootstyle] -startvar [::set ${ns}::opt-startvar] -endvar [::set ${ns}::opt-endvar] -command [::set ${ns}::opt-command] -dateformat [::set ${ns}::opt-dateformat] -firstweekday [::set ${ns}::opt-firstweekday]]]
    ::set fmt $o(-dateformat)
    # Parse date strings into {year month day} lists
    ::set ss [clock scan $start_str -format $fmt]
    ::set es [clock scan $end_str   -format $fmt]
    ::set ${ns}::start_sel [list \
        [clock format $ss -format %Y] \
        [clock format $ss -format %m] \
        [clock format $ss -format %d]]
    ::set ${ns}::end_sel [list \
        [clock format $es -format %Y] \
        [clock format $es -format %m] \
        [clock format $es -format %d]]
    ttkbootstrap::_drp_update_display $w
    ttkbootstrap::_drp_notify $w
    ttkbootstrap::_drp_render $w start
    ttkbootstrap::_drp_render $w end
}
