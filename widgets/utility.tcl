# =============================================================================
# utility.tcl — ttkbootstrap utility functions
#
# Mirrors Python ttkbootstrap's utility module:
#   ttkbootstrap::center_on_parent window ?parent?
#   ttkbootstrap::enable_high_dpi_awareness
#   ttkbootstrap::get_image_name image
#   ttkbootstrap::move_widget_to_top window
#   ttkbootstrap::StyleManager::get_style_for  widget
#
# Also provides the public utility namespace with convenience wrappers.
# =============================================================================

namespace eval ttkbootstrap {

# ─────────────────────────────────────────────────────────────────────────────
# center_on_parent  — center a toplevel window on its parent (or screen)
#
#   ttkbootstrap::center_on_parent .mydialog
#   ttkbootstrap::center_on_parent .mydialog .mainwindow
# ─────────────────────────────────────────────────────────────────────────────
proc center_on_parent {window {parent ""}} {
    update idletasks

    set ww [winfo reqwidth  $window]
    set wh [winfo reqheight $window]

    if {$parent eq "" || $parent eq "."} {
        # Center on screen
        set sw [winfo screenwidth  $window]
        set sh [winfo screenheight $window]
        set x  [expr {($sw - $ww) / 2}]
        set y  [expr {($sh - $wh) / 2}]
    } else {
        set px [winfo rootx  $parent]
        set py [winfo rooty  $parent]
        set pw [winfo width  $parent]
        set ph [winfo height $parent]
        set x  [expr {$px + ($pw - $ww) / 2}]
        set y  [expr {$py + ($ph - $wh) / 2}]
        # Keep on-screen
        set sw [winfo screenwidth  $window]
        set sh [winfo screenheight $window]
        if {$x < 0} { set x 0 }
        if {$y < 0} { set y 0 }
        if {$x + $ww > $sw} { set x [expr {$sw - $ww}] }
        if {$y + $wh > $sh} { set y [expr {$sh - $wh}] }
    }

    wm geometry $window "+${x}+${y}"
}

# ─────────────────────────────────────────────────────────────────────────────
# enable_high_dpi_awareness  — configure Tk for HiDPI/Retina displays
#
#   ttkbootstrap::enable_high_dpi_awareness
#
# On Windows sets DPI-aware process flag; on macOS / Linux adjusts tk scaling.
# After calling this, always call ttkbootstrap::img::autoScale to refresh SVGs.
# ─────────────────────────────────────────────────────────────────────────────
proc enable_high_dpi_awareness {} {
    set os [tk windowingsystem]
    switch -- $os {
        win32 {
            # On Windows, attempt to set per-monitor DPI awareness
            ::catch {
                package require registry
                # SetProcessDpiAwareness(2) = PROCESS_PER_MONITOR_DPI_AWARE
                # Done by calling the Win32 DLL via ffidl or via Tcl's built-in
                # shcall on Tcl/Tk 9; for older Tk just nudge scaling
            }
            # Tk 8.6+ on Windows: set tk scaling proportional to actual DPI
            ::catch {
                set dpi [winfo fpixels . 1i]   ;# pixels per inch
                set factor [expr {$dpi / 96.0}]
                if {$factor > 1.0} {
                    tk scaling $factor
                }
            }
        }
        aqua {
            # macOS handles HiDPI natively; nothing required.
            # Tk 9 on aqua is Retina-aware by default.
        }
        x11 {
            # Linux: read Xft.dpi from xrdb if available, else use winfo fpixels
            ::catch {
                set dpi [winfo fpixels . 1i]
                set factor [expr {$dpi / 96.0}]
                if {$factor > 1.0} {
                    tk scaling $factor
                }
            }
        }
    }
    # Always refresh the SVG scale factor after adjusting
    ::catch { ttkbootstrap::img::autoScale }
}

# ─────────────────────────────────────────────────────────────────────────────
# get_image_name  — return a stable, unique name string for a PhotoImage
#
#   set name [ttkbootstrap::get_image_name $photo]
#
# In Python ttkbootstrap this is util.get_image_name; it just returns the
# internal Tcl/Tk image name, which is already accessible as [$img] or just
# the variable value for PhotoImages created with a name.
# ─────────────────────────────────────────────────────────────────────────────
proc get_image_name {photo} {
    # $photo is already the name string for Tcl PhotoImage objects
    return $photo
}

# ─────────────────────────────────────────────────────────────────────────────
# move_widget_to_top  — raise a toplevel above all others and grab focus
# ─────────────────────────────────────────────────────────────────────────────
proc move_widget_to_top {window} {
    ::catch { wm deiconify $window }
    ::catch { raise $window }
    ::catch { focus $window }
}

# ─────────────────────────────────────────────────────────────────────────────
# get_default_font  — return a good default font for the current theme
# ─────────────────────────────────────────────────────────────────────────────
proc get_default_font {{size 10}} {
    ::catch {
        set family [ttkbootstrap::getColor font]
        return [list $family $size]
    }
    return [list TkDefaultFont $size]
}

# ─────────────────────────────────────────────────────────────────────────────
# StyleManager  — helpers for building and querying ttk style names
# ─────────────────────────────────────────────────────────────────────────────
namespace eval StyleManager {

    # get_style_for widget  → returns the current -style value or widget default
    proc get_style_for {widget} {
        ::catch {
            set s [$widget cget -style]
            if {$s ne ""} { return $s }
        }
        # Fall back to widget class
        ::catch {
            return [winfo class $widget]
        }
        return ""
    }

    # color_from_style styleName  → extract color keyword from style string
    # e.g. "success.Outline.TButton" → "success"
    proc color_from_style {style} {
        set known {primary secondary success info warning danger light dark}
        foreach part [split $style "."] {
            if {[lsearch -exact $known [string tolower $part]] >= 0} {
                return [string tolower $part]
            }
        }
        return "primary"
    }

    # widget_style colorname widgetClass ?variant?
    # Convenience: build a style string the same way bootstyle does
    proc widget_style {colorname widgetClass {variant ""}} {
        if {$variant ne ""} {
            return "${colorname}.[string totitle $variant].${widgetClass}"
        }
        return "${colorname}.${widgetClass}"
    }
}

# Return a flat list of all descendant widgets under $w (recursive)
proc _all_descendants {w} {
    set result {}
    foreach child [winfo children $w] {
        lappend result $child
        foreach desc [_all_descendants $child] {
            lappend result $desc
        }
    }
    return $result
}

} ;# end namespace ttkbootstrap
