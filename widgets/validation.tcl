# =============================================================================
# validation.tcl — ttkbootstrap input validation framework
#
# Attaches real-time validation to ttk::Entry and ttk::Spinbox widgets,
# with visual feedback (border turns red/green) and optional messages.
#
# Usage:
#   ttkbootstrap::Validator::add_regex .entry {^\d{4}-\d{2}-\d{2}$} \
#       -message "Must be YYYY-MM-DD" -bootstyle primary
#
#   ttkbootstrap::Validator::add_numeric .entry \
#       -minval 0 -maxval 100 -message "Enter 0-100"
#
#   ttkbootstrap::Validator::add_predicate .entry \
#       {string length $value > 0} -message "Required"
#
# Validator::remove widget   — remove all validation
# Validator::get_state widget — returns valid|invalid|""
# =============================================================================

namespace eval ttkbootstrap::Validator {

    variable _states  ;# widget -> valid|invalid
    variable _configs ;# widget -> options dict

    # ── add_regex ─────────────────────────────────────────────────────────────
    proc add_regex {widget pattern args} {
        _setup $widget $args
        set ns ::ttkbootstrap::Validator
        set cmd [list apply [list {w pattern} {
            set val [${w} get]
            set ok [expr {[regexp $pattern $val] ? "valid" : "invalid"}]
            ttkbootstrap::Validator::_feedback $w $ok
        }] $widget $pattern]
        _attach $widget $cmd
    }

    # ── add_numeric ──────────────────────────────────────────────────────────
    proc add_numeric {widget args} {
        array set opts {-minval "" -maxval "" -message "" -bootstyle primary -allowfloat 0}
        array set opts $args
        _setup $widget [array get opts]

        set cmd [list apply [list {w minval maxval allowfloat} {
            set val [$w get]
            if {$allowfloat} {
                set ok [string is double -strict $val]
            } else {
                set ok [string is integer -strict $val]
            }
            if {$ok && $minval ne "" && $val < $minval} { set ok 0 }
            if {$ok && $maxval ne "" && $val > $maxval} { set ok 0 }
            ttkbootstrap::Validator::_feedback $w \
                [expr {$ok ? "valid" : "invalid"}]
        }] $widget $opts(-minval) $opts(-maxval) $opts(-allowfloat)]
        _attach $widget $cmd
    }

    # ── add_date ──────────────────────────────────────────────────────────────
    proc add_date {widget {fmt "%Y-%m-%d"} args} {
        _setup $widget $args
        set cmd [list apply [list {w fmt} {
            set val [$w get]
            set ok [expr {[catch {clock scan $val -format $fmt}] == 0 ? "valid" : "invalid"}]
            ttkbootstrap::Validator::_feedback $w $ok
        }] $widget $fmt]
        _attach $widget $cmd
    }

    # ── add_email ─────────────────────────────────────────────────────────────
    proc add_email {widget args} {
        add_regex $widget {^[^@\s]+@[^@\s]+\.[^@\s]+$} {*}$args
    }

    # ── add_phone ─────────────────────────────────────────────────────────────
    proc add_phone {widget args} {
        add_regex $widget {^[+\d\s\-\(\)]{7,20}$} {*}$args
    }

    # ── add_required ─────────────────────────────────────────────────────────
    proc add_required {widget args} {
        add_regex $widget {^.+$} {*}$args
    }

    # ── add_predicate ─────────────────────────────────────────────────────────
    # pred is a Tcl expression; $value is set to the current entry content
    proc add_predicate {widget pred args} {
        _setup $widget $args
        set cmd [list apply [list {w pred} {
            set value [$w get]
            set ok [expr {[uplevel #0 [list expr $pred]] ? "valid" : "invalid"}]
            ttkbootstrap::Validator::_feedback $w $ok
        }] $widget $pred]
        _attach $widget $cmd
    }

    # ── remove ────────────────────────────────────────────────────────────────
    proc remove {widget} {
        variable _states
        variable _configs
        catch { $widget configure -validate none }
        catch { $widget configure -validatecommand {} }
        _clear_feedback $widget
        catch { unset _states($widget) }
        catch { unset _configs($widget) }
        # Remove message label if exists
        set msglbl "${widget}.__valmsg"
        catch { destroy $msglbl }
    }

    # ── get_state ─────────────────────────────────────────────────────────────
    proc get_state {widget} {
        variable _states
        if {[info exists _states($widget)]} {
            return $_states($widget)
        }
        return ""
    }

    # ── validate_all ──────────────────────────────────────────────────────────
    # Trigger validation on all registered widgets; returns 1 if all valid
    proc validate_all {} {
        variable _states
        variable _configs
        foreach w [array names _configs] {
            if {[winfo exists $w]} {
                # Trigger the validatecommand
                catch { $w validate }
            }
        }
        foreach w [array names _states] {
            if {$_states($w) eq "invalid"} { return 0 }
        }
        return 1
    }

    # ─────────────────────────────────────────────────────────────────────────
    # Internal
    # ─────────────────────────────────────────────────────────────────────────
    proc _setup {widget arglist} {
        variable _configs
        array set opts {-message "" -bootstyle primary}
        array set opts $arglist
        set _configs($widget) [array get opts]
    }

    proc _attach {widget cmd} {
        # Wrap in validatecommand-compatible proc (must return bool)
        set vcmd [list apply [list {cmd w} {
            after 1 $cmd
            return 1
        }] $cmd $widget]

        catch {
            $widget configure \
                -validate key \
                -validatecommand $vcmd
        }
        # Also validate on focus-out
        bind $widget <FocusOut> $cmd
    }

    proc _feedback {widget state} {
        variable _states
        variable _configs

        set _states($widget) $state

        if {![winfo exists $widget]} return

        set primary [ttkbootstrap::getColor primary]
        set danger  [ttkbootstrap::getColor danger]
        set success [ttkbootstrap::getColor success]
        set border  [ttkbootstrap::getColor border]

        switch -- $state {
            valid {
                catch {
                    $widget configure \
                        -highlightcolor    $success \
                        -highlightthickness 1
                }
                # ttk entry border
                set style [$widget cget -style]
                if {$style eq ""} { set style TEntry }
                ttk::style map $style \
                    -bordercolor [list focus $success]
            }
            invalid {
                catch {
                    $widget configure \
                        -highlightcolor    $danger \
                        -highlightthickness 1
                }
                set style [$widget cget -style]
                if {$style eq ""} { set style TEntry }
                ttk::style map $style \
                    -bordercolor [list focus $danger]
            }
        }

        # Show/update message label if configured
        if {[info exists _configs($widget)]} {
            array set cfg $_configs($widget)
            if {$cfg(-message) ne ""} {
                set msglbl "${widget}.__valmsg"
                if {![winfo exists $msglbl]} {
                    set col [expr {$state eq "invalid" ? $danger : $success}]
                    ttk::label $msglbl \
                        -text $cfg(-message) \
                        -foreground $col \
                        -font [list [ttkbootstrap::getColor font] [ttkbootstrap::_sf 10]]
                    # Place below the widget
                    catch {
                        place $msglbl \
                            -in $widget \
                            -relx 0 -rely 1 -anchor nw \
                            -y 2
                    }
                } else {
                    set col [expr {$state eq "invalid" ? $danger : $success}]
                    $msglbl configure -foreground $col
                }
                if {$state eq "invalid"} {
                    catch { place $msglbl -in $widget -relx 0 -rely 1 -anchor nw -y 2 }
                } else {
                    catch { place forget $msglbl }
                }
            }
        }
    }

    proc _clear_feedback {widget} {
        variable _states
        catch { unset _states($widget) }
        set border [ttkbootstrap::getColor border]
        catch { $widget configure -highlightthickness 0 }
    }
}
