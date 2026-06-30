# =============================================================================
# scaling.tcl — Automatic DPI / HiDPI scaling for ttkbootstrap
#
# Provides a single scaling factor (ttkbootstrap::_scale) derived from the
# system's actual DPI and exposes two helpers used throughout the package:
#
#   ttkbootstrap::_sp  ?pixels?        → scaled integer pixel value
#   ttkbootstrap::_sf  ?points?        → scaled font point size (integer)
#   ttkbootstrap::_sp2 ?x? ?y?         → scaled {x y} padding list
#   ttkbootstrap::_sp4 ?l? ?t? ?r? ?b? → scaled {l t r b} padding list
#   ttkbootstrap::_updateScale          → re-detect from tk scaling
#
# Called by ttkbootstrap::setTheme (via window.tcl patch) so that every
# style attribute is recomputed for the current DPI whenever the theme
# changes or the user manually calls ttkbootstrap::_updateScale.
#
# How the factor is determined (in priority order):
#   1. If tk scaling is available and > 0, use  (tk scaling) / 1.3339
#      (1.3339 ≈ 96 dpi baseline — typical non-HiDPI screen)
#   2. If winfo fpixels returns a DPI, use dpi / 96.0
#   3. Fall back to 1.0
#
# The factor is clamped to [1.0, 4.0] and rounded to one decimal place so
# tiny fluctuations don't cause constant theme rebuilds.
# =============================================================================

namespace eval ttkbootstrap {

    # Internal scale factor — 1.0 for 96 dpi, 2.0 for 192 dpi, etc.
    variable _scale 1.0

    # ── Detect and store the current scale factor ─────────────────────────────
    proc _updateScale {} {
        variable _scale

        # Method 1: use tk scaling (most reliable cross-platform)
        if {![catch {set s [tk scaling]} ] && $s > 0} {
            # Baseline: a nominal "1×" display has tk scaling ≈ 1.3339
            # (96 dpi / 72 pt = 1.3333…; Tk adds a small fudge)
            set raw [expr {$s / 1.3339}]
            set factor [expr {max(1.0, min(4.0, $raw))}]
            # Round to 1 decimal place so 1.04 and 1.06 both map to 1.0
            set _scale [expr {round($factor * 10) / 10.0}]

            # Method 1b: if DPI says 1x but screen is very large (e.g. 4K at 96dpi
            # via Xephyr or a large monitor), also scale by screen size.
            # Baseline: 1920x1080. A 3840x2160 screen at 96dpi should scale 2x.
            if {$_scale < 1.2 && ![catch {
                set sw [winfo screenwidth .]
                set sh [winfo screenheight .]
            }]} {
                set scrFactor [expr {min(double($sw)/1920.0, double($sh)/1080.0)}]
                if {$scrFactor > 1.2} {
                    set _scale [expr {round($scrFactor * 10) / 10.0}]
                    if {$_scale > 4.0} { set _scale 4.0 }
                }
            }

            # Also push to the image subsystem
            catch { ttkbootstrap::img::setScale $_scale }
            return $_scale
        }

        # Method 2: winfo fpixels (pixels per inch on the screen)
        if {![catch {set dpi [winfo fpixels . 1i]}] && $dpi > 0} {
            set raw   [expr {$dpi / 96.0}]
            set factor [expr {max(1.0, min(4.0, $raw))}]
            set _scale [expr {round($factor * 10) / 10.0}]
            catch { ttkbootstrap::img::setScale $_scale }
            return $_scale
        }

        # Fall back
        set _scale 1.0
        catch { ttkbootstrap::img::setScale 1.0 }
        return 1.0
    }

    # ── Scale a pixel value (returns an integer) ──────────────────────────────
    proc _sp {pixels} {
        variable _scale
        return [expr {int(ceil($pixels * $_scale))}]
    }

    # ── Scale a font point size (returns an integer, minimum 6) ──────────────
    proc _sf {points} {
        variable _scale
        set s [expr {int(round($points * $_scale))}]
        return [expr {$s < 6 ? 6 : $s}]
    }

    # ── Scale a 2-value padding list  {x y} ──────────────────────────────────
    proc _sp2 {x y} {
        return [list [_sp $x] [_sp $y]]
    }

    # ── Scale a 4-value padding list  {l t r b} ──────────────────────────────
    proc _sp4 {l t r b} {
        return [list [_sp $l] [_sp $t] [_sp $r] [_sp $b]]
    }

    # ── Public convenience: return the current factor ─────────────────────────
    proc scaleFactor {} {
        variable _scale
        return $_scale
    }

} ;# end namespace ttkbootstrap
