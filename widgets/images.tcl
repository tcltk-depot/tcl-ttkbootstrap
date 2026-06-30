# =============================================================================
# images.tcl — SVG-based image asset generator for ttkbootstrap
#
# All widget decorations (checkbox, radio, scrollbar thumb, scale knob,
# arrow, sizegrip, etc.) are generated from inline SVG strings so they
# scale cleanly on any DPI.
#
# Public API:
#   ttkbootstrap::img::get  name color ?scale?  → PhotoImage name
#   ttkbootstrap::img::size                     → current scale factor
#   ttkbootstrap::img::setScale factor          → force a scale
#   ttkbootstrap::img::flush                    → clear all cached images
#
# SVG images are parameterised by color (hex string) and re-rendered
# whenever a new combination is requested; results are cached.
# =============================================================================

namespace eval ttkbootstrap::img {

    variable _cache   ;# name,color,scale → photo name
    variable _scale 1.0

    # ── Auto-detect HiDPI scale ──────────────────────────────────────────────
    proc autoScale {} {
        variable _scale
        if {[catch {
            set s [tk scaling]
            # 96 dpi = scale 1.0  (baseline ~1.3339 on most platforms)
            set raw [expr {max(1.0, $s / 1.3339)}]
            # Round to nearest integer for SVG format string compatibility
            set _scale [expr {max(1, int(round($raw)))}]
        }]} {
            set _scale 1
        }
        return $_scale
    }

    proc setScale {factor} {
        variable _scale
        set _scale $factor
    }

    proc size {} {
        variable _scale
        return $_scale
    }

    proc flush {} {
        variable _cache
        foreach key [array names _cache] {
            catch { image delete $_cache($key) }
        }
        array unset _cache
    }

    # ── Core renderer ────────────────────────────────────────────────────────
    # get name color ?scale? — returns a PhotoImage name (creates if needed)
    proc get {name color {scale ""}} {
        variable _cache
        variable _scale
        if {$scale eq ""} { set scale $_scale }
        set key "${name}|${color}|${scale}"
        if {[info exists _cache($key)]} {
            return $_cache($key)
        }
        set svg [_svg $name $color]
        if {$svg eq ""} {
            error "Unknown image: $name"
        }
        set imgname "::ttkbs::img::${name}_[string map {# _} $color]_[string map {. _} $scale]"
        catch { image delete $imgname }
        set iscale [expr {max(1, int(round($scale)))}]
        # Use -format as a proper Tcl list (braces, not quotes)
        # -scale N multiplies the SVG's intrinsic size by N
        image create photo $imgname \
            -data $svg \
            -format [list svg -scale $iscale]
        set _cache($key) $imgname
        return $imgname
    }

    # get_multi — returns list of image names for state variants
    # spec is a list of {stateName color} pairs, first color is normal
    proc get_multi {name colors scale} {
        set result {}
        foreach color $colors {
            lappend result [get $name $color $scale]
        }
        return $result
    }

    # ── SVG definitions ──────────────────────────────────────────────────────
    proc _svg {name color} {
        switch -- $name {

            check.unchecked {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <rect x='2' y='2' width='12' height='12' rx='3'
    fill='#ffffff' stroke='${color}' stroke-width='2'/>
</svg>"
            }

            check.checked {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <rect x='1' y='1' width='14' height='14' rx='3'
    fill='${color}' stroke='${color}' stroke-width='1'/>
  <polyline points='3,8 6,11 13,4'
    fill-opacity='0' stroke='#ffffff' stroke-width='2'
    stroke-linecap='round' stroke-linejoin='round'/>
</svg>"
            }

            check.indeterminate {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <rect x='1' y='1' width='14' height='14' rx='3'
    fill='${color}' stroke='${color}' stroke-width='1'/>
  <line x1='4' y1='8' x2='12' y2='8'
    stroke='#ffffff' stroke-width='2' stroke-linecap='round'/>
</svg>"
            }

            check.disabled {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <rect x='2' y='2' width='12' height='12' rx='3'
    fill='#f5f5f5' stroke='${color}' stroke-width='2'/>
</svg>"
            }

            radio.unchecked {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <circle cx='8' cy='8' r='7'
    fill='#ffffff' stroke='${color}' stroke-width='2'/>
</svg>"
            }

            radio.checked {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <circle cx='8' cy='8' r='7'
    fill='${color}' stroke='${color}' stroke-width='1'/>
  <circle cx='8' cy='8' r='3' fill='#ffffff'/>
</svg>"
            }

            radio.disabled {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <circle cx='8' cy='8' r='7'
    fill='#f5f5f5' stroke='${color}' stroke-width='2'/>
</svg>"
            }

            toggle.round.off {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='32' height='18'>
  <circle cx='9' cy='9' r='8' fill='#ffffff' stroke='${color}' stroke-width='2'/>
  <rect x='9' y='1' width='14' height='16' fill='#ffffff'/>
  <line x1='9' y1='1' x2='23' y2='1' stroke='${color}' stroke-width='2'/>
  <line x1='9' y1='17' x2='23' y2='17' stroke='${color}' stroke-width='2'/>
  <circle cx='23' cy='9' r='8' fill='#ffffff' stroke='${color}' stroke-width='2'/>
  <circle cx='9' cy='9' r='5' fill='${color}'/>
</svg>"
            }

            toggle.round.on {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='32' height='18'>
  <circle cx='9' cy='9' r='9' fill='${color}'/>
  <rect x='9' y='0' width='14' height='18' fill='${color}'/>
  <circle cx='23' cy='9' r='9' fill='${color}'/>
  <circle cx='23' cy='9' r='6' fill='#ffffff'/>
</svg>"
            }

            toggle.square.off {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='32' height='18'>
  <rect x='1' y='1' width='30' height='16' rx='2'
    fill='#ffffff' stroke='${color}' stroke-width='2'/>
  <rect x='4' y='4' width='10' height='10' fill='${color}'/>
</svg>"
            }

            toggle.square.on {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='32' height='18'>
  <rect x='1' y='1' width='30' height='16' rx='2'
    fill='${color}' stroke='${color}' stroke-width='1'/>
  <rect x='18' y='4' width='10' height='10' fill='#ffffff'/>
</svg>"
            }


            scale.slider {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <circle cx='8' cy='8' r='7'
    fill='${color}' stroke-width='0'/>
</svg>"
            }

            scale.slider.hover {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <circle cx='8' cy='8' r='7'
    fill='${color}' stroke='#ffffff' stroke-width='2'/>
</svg>"
            }

            scale.slider.disabled {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <circle cx='8' cy='8' r='7'
    fill='${color}' stroke-width='0' opacity='0.4'/>
</svg>"
            }

            scale.htrack {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='40' height='6'>
  <rect x='0' y='2' width='40' height='2' fill='${color}'/>
</svg>"
            }

            scale.vtrack {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='6' height='40'>
  <rect x='2' y='0' width='2' height='40' fill='${color}'/>
</svg>"
            }

            scrollbar.thumb.h {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='28' height='8'>
  <rect x='1' y='1' width='26' height='6' fill='${color}'/>
</svg>"
            }

            scrollbar.thumb.v {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='8' height='28'>
  <rect x='1' y='1' width='6' height='26' fill='${color}'/>
</svg>"
            }

            scrollbar.round.thumb.h {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='28' height='9'>
  <rect x='1' y='1' width='26' height='7' fill='${color}'/>
</svg>"
            }

            scrollbar.round.thumb.v {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='9' height='28'>
  <rect x='1' y='1' width='7' height='26' fill='${color}'/>
</svg>"
            }

            arrow.down {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12'>
  <polygon points='2,4 10,4 6,9' fill='${color}'/>
</svg>"
            }

            arrow.up {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12'>
  <polygon points='2,8 10,8 6,3' fill='${color}'/>
</svg>"
            }

            arrow.left {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12'>
  <polygon points='8,2 8,10 3,6' fill='${color}'/>
</svg>"
            }

            arrow.right {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='12' height='12'>
  <polygon points='4,2 4,10 9,6' fill='${color}'/>
</svg>"
            }

            sizegrip {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='14' height='14'>
  <circle cx='11' cy='11' r='2' fill='${color}' opacity='0.8'/>
  <circle cx='7'  cy='11' r='2' fill='${color}' opacity='0.5'/>
  <circle cx='11' cy='7'  r='2' fill='${color}' opacity='0.5'/>
  <circle cx='3'  cy='11' r='2' fill='${color}' opacity='0.3'/>
  <circle cx='7'  cy='7'  r='2' fill='${color}' opacity='0.3'/>
  <circle cx='11' cy='3'  r='2' fill='${color}' opacity='0.15'/>
</svg>"
            }

            progress.stripe.h {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20'>
  <rect width='20' height='20' fill='${color}' opacity='0.7'/>
  <polygon points='0,0 8,0 20,12 20,20 12,20 0,8'
    fill='${color}'/>
  <polygon points='0,12 8,20 0,20' fill='${color}'/>
</svg>"
            }

            progress.stripe.v {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20'>
  <rect width='20' height='20' fill='${color}' opacity='0.7'/>
  <polygon points='0,0 0,8 12,20 20,20 20,12 8,0'
    fill='${color}'/>
  <polygon points='12,0 20,0 20,8' fill='${color}'/>
</svg>"
            }

            link.underline {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='100' height='2'>
  <line x1='0' y1='1' x2='100' y2='1'
    stroke='${color}' stroke-width='1'/>
</svg>"
            }

            notebook.close {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='10' height='10'>
  <line x1='2' y1='2' x2='8' y2='8' stroke='${color}' stroke-width='2' stroke-linecap='round'/>
  <line x1='8' y1='2' x2='2' y2='8' stroke='${color}' stroke-width='2' stroke-linecap='round'/>
</svg>"
            }

            cal.prev {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='14' height='14'>
  <polygon points='10,2 10,12 4,7' fill='${color}'/>
</svg>"
            }

            cal.next {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='14' height='14'>
  <polygon points='4,2 4,12 10,7' fill='${color}'/>
</svg>"
            }

            sep.horizontal {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='40' height='2'>
  <rect x='0' y='0' width='40' height='2' fill='${color}'/>
</svg>"
            }

            sep.vertical {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='2' height='40'>
  <rect x='0' y='0' width='2' height='40' fill='${color}'/>
</svg>"
            }

            icon.info {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48'>
  <circle cx='24' cy='24' r='22' fill='${color}'/>
  <circle cx='24' cy='14' r='3' fill='#ffffff'/>
  <rect x='21' y='20' width='6' height='18' fill='#ffffff'/>
</svg>"
            }

            icon.warning {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48'>
  <polygon points='24,4 46,44 2,44' fill='${color}'
    stroke='${color}' stroke-linejoin='round'/>
  <rect x='22' y='16' width='5' height='16' fill='#ffffff'/>
  <circle cx='24' cy='37' r='3' fill='#ffffff'/>
</svg>"
            }

            icon.error {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48'>
  <circle cx='24' cy='24' r='22' fill='${color}'/>
  <line x1='15' y1='15' x2='33' y2='33'
    stroke='#ffffff' stroke-width='4' stroke-linecap='round'/>
  <line x1='33' y1='15' x2='15' y2='33'
    stroke='#ffffff' stroke-width='4' stroke-linecap='round'/>
</svg>"
            }

            icon.question {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48'>
  <circle cx='24' cy='24' r='22' fill='${color}'/>
  <path d='M16,18 Q16,10 24,10 Q32,10 32,18 Q32,24 24,26 L24,30'
    fill-opacity='0' stroke='#ffffff' stroke-width='4' stroke-linecap='round'/>
  <circle cx='24' cy='36' r='3' fill='#ffffff'/>
</svg>"
            }

            icon.success {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='48' height='48'>
  <circle cx='24' cy='24' r='22' fill='${color}'/>
  <polyline points='12,24 20,33 36,15'
    fill-opacity='0' stroke='#ffffff' stroke-width='4'
    stroke-linecap='round' stroke-linejoin='round'/>
</svg>"
            }

            icon.dropper {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24'>
  <path d='M17,3 L21,7 L10,18 L6,14 Z'
    fill='${color}' stroke='${color}' stroke-width='1'/>
  <rect x='3' y='18' width='6' height='4'
    fill='${color}' opacity='0.6'/>
  <line x1='6' y1='14' x2='3' y2='21'
    stroke='${color}' stroke-width='2' stroke-linecap='round'/>
</svg>"
            }

            icon.calendar {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <rect x='1' y='2' width='14' height='13'
    fill-opacity='0' stroke='${color}' stroke-width='2'/>
  <line x1='5' y1='1' x2='5' y2='4'
    stroke='${color}' stroke-width='2' stroke-linecap='round'/>
  <line x1='11' y1='1' x2='11' y2='4'
    stroke='${color}' stroke-width='2' stroke-linecap='round'/>
  <line x1='1' y1='7' x2='15' y2='7'
    stroke='${color}' stroke-width='1'/>
  <rect x='4' y='9' width='2' height='2' fill='${color}' opacity='0.7'/>
  <rect x='7' y='9' width='2' height='2' fill='${color}' opacity='0.7'/>
  <rect x='10' y='9' width='2' height='2' fill='${color}' opacity='0.7'/>
  <rect x='4' y='12' width='2' height='2' fill='${color}' opacity='0.7'/>
  <rect x='7' y='12' width='2' height='2' fill='${color}' opacity='0.7'/>
</svg>"
            }

            icon.clock {
                return "<svg xmlns='http://www.w3.org/2000/svg' width='16' height='16'>
  <circle cx='8' cy='8' r='6.5'
    fill-opacity='0' stroke='${color}' stroke-width='1.5'/>
  <line x1='8' y1='4' x2='8' y2='8'
    stroke='${color}' stroke-width='1.5' stroke-linecap='round'/>
  <line x1='8' y1='8' x2='11' y2='10'
    stroke='${color}' stroke-width='1.5' stroke-linecap='round'/>
</svg>"
            }

            default { return "" }
        }
    }
}
