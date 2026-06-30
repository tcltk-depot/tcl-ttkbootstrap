# =============================================================================
# toggleswitch.tcl — iOS-style on/off toggle switch
#
# A themed checkbutton presented as a sliding toggle.  Uses the existing
# Round.TCheckbutton image style from imgstyles.tcl so it automatically
# picks up the correct SVG pill/indicator for every theme.
#
# USAGE
#   ttkbootstrap::ToggleSwitch .ts \
#       -text     "Enable notifications" \
#       -variable myVar \
#       -bootstyle success \
#       -command  {puts "toggled: $myVar"}
#   pack .ts
#
# OPTIONS
#   -text       string   Label shown to the right of the toggle
#   -variable   varname  Global variable to link (0=off 1=on)
#   -onvalue    value    Value written when on  (default 1)
#   -offvalue   value    Value written when off (default 0)
#   -bootstyle  color    Colour when on (default primary)
#   -command    script   Called on every toggle
#   -state      normal|disabled
#
# METHODS
#   $w get       — returns current value
#   $w set value — sets value (fires -command)
#   $w toggle    — flip current state
# =============================================================================

namespace eval ttkbootstrap {

proc ToggleSwitch {w args} {
    array set opts {
        -text      {}
        -variable  {}
        -onvalue   1
        -offvalue  0
        -bootstyle primary
        -command   {}
        -state     normal
    }
    array set opts $args

    set ns ::ttkbootstrap::ts::$w
    namespace eval $ns {}
    array set ${ns}::opts [array get opts]

    # Use a private variable if none supplied
    if {$opts(-variable) eq {}} {
        set ${ns}::value $opts(-offvalue)
        set opts(-variable) ${ns}::value
        set ${ns}::opts(-variable) $opts(-variable)
    }

    set style "$opts(-bootstyle).Round.TCheckbutton"

    # Create checkbutton as a child, keep $w as the parent frame
    ttk::frame $w -padding 0
    set cb [ttk::checkbutton $w.cb \
        -text     $opts(-text) \
        -variable $opts(-variable) \
        -onvalue  $opts(-onvalue) \
        -offvalue $opts(-offvalue) \
        -style    $style \
        -state    $opts(-state) \
        -command  [list ttkbootstrap::_ts_cmd $w]]
    pack $cb -fill both -expand 1

    set ${ns}::cb $cb

    bind $cb <<ThemeChanged>> [list ttkbootstrap::_ts_restyle $w]

    return $w
}

proc _ts_dispatch {w cmd args} {
    # Direct method dispatch - no more interp alias needed
    set ns ::ttkbootstrap::ts::$w
    if {![namespace exists $ns]} { return }
    set cb [set ${ns}::cb]
    switch -- $cmd {
        get    { return [uplevel #0 [list set [set ${ns}::opts(-variable)]]] }
        set    {
            uplevel #0 [list set [set ${ns}::opts(-variable)] [lindex $args 0]]
            _ts_cmd $w
        }
        toggle {
            set var [set ${ns}::opts(-variable)]
            set cur [uplevel #0 [list set $var]]
            array set o [array get ${ns}::opts]
            if {$cur eq $o(-onvalue)} {
                uplevel #0 [list set $var $o(-offvalue)]
            } else {
                uplevel #0 [list set $var $o(-onvalue)]
            }
            _ts_cmd $w
        }
        configure {
            array set o $args
            array set ${ns}::opts $args
            if {[info exists o(-state)]}     { $cb configure -state $o(-state) }
            if {[info exists o(-text)]}      { $cb configure -text  $o(-text)  }
            if {[info exists o(-command)]}   { }
            if {[info exists o(-bootstyle)]} { _ts_restyle $w }
        }
        cget {
            set key [lindex $args 0]
            return [set ${ns}::opts($key)]
        }
        default { $w.cb {*}$cmd {*}$args }
    }
}

proc _ts_cmd {w} {
    set ns ::ttkbootstrap::ts::$w
    array set o [array get ${ns}::opts]
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _ts_restyle {w} {
    set ns ::ttkbootstrap::ts::$w
    if {![namespace exists $ns]} return
    set cb [set ${ns}::cb]
    if {![winfo exists $cb]} return
    set bs [set ${ns}::opts(-bootstyle)]
    $cb configure -style "$bs.Round.TCheckbutton"
}

} ;# end namespace ttkbootstrap
