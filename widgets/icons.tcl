# =============================================================================
# icons.tcl — ttkbootstrap Icons module
#
# Provides ~70 built-in SVG icons as PhotoImages, plus Emoji constants.
#
# Usage:
#   set img [ttkbootstrap::Icon get arrow-right primary 16]
#   ttk::button .b -image $img -text "Next" -compound left
#
#   ttk::label .l -text [ttkbootstrap::Emoji::check]
#
# Icon::get name ?color? ?size? ?scale?
#   name  — icon name (see Icon::names for full list)
#   color — hex or theme color keyword (default: current theme fg)
#   size  — pixel size (default: 16); images are square
#   scale — DPI scale (default: auto)
# =============================================================================

namespace eval ttkbootstrap::Icon {

    variable _cache

    # ── Public: get ──────────────────────────────────────────────────────────
    proc get {name {color ""} {size 16} {scale ""}} {
        variable _cache

        if {$color eq ""} {
            set color [ttkbootstrap::getColor fg]
        } elseif {[catch {ttkbootstrap::getColor $color} hex] == 0} {
            set color $hex
        }

        if {$scale eq ""} {
            set scale [ttkbootstrap::img::size]
        }

        set key "${name}|${color}|${size}|${scale}"
        if {[info exists _cache($key)]} { return $_cache($key) }

        set svg [_svg $name $color $size]
        if {$svg eq ""} { error "Unknown icon: $name" }

        set imgname "::ttkbs::icon::${name}_[string map {# _ . _} "${color}_${size}_${scale}"]"
        catch { image delete $imgname }
        image create photo $imgname \
            -data $svg \
            -format "svg -scale $scale"
        set _cache($key) $imgname
        return $imgname
    }

    # ── Public: names ────────────────────────────────────────────────────────
    proc names {} {
        return {
            arrow-up arrow-down arrow-left arrow-right
            arrow-up-circle arrow-down-circle arrow-left-circle arrow-right-circle
            chevron-up chevron-down chevron-left chevron-right
            chevron-double-up chevron-double-down chevron-double-left chevron-double-right
            check check-circle check-square x x-circle x-square
            plus plus-circle minus minus-circle
            info info-circle warning warning-triangle
            question question-circle bell bell-slash
            search zoom-in zoom-out filter sort-asc sort-desc
            home gear settings wrench
            folder folder-open file file-text file-plus file-minus
            save download upload cloud
            edit pencil trash delete
            copy cut paste clipboard
            eye eye-slash lock unlock
            user users person
            heart star star-fill bookmark
            share link external-link
            play pause stop rewind fast-forward
            volume volume-mute
            calendar clock timer
            image photo camera
            mail inbox send reply
            tag label flag
            refresh reset rotate-left rotate-right
            columns rows table grid list
            chart-bar chart-line chart-pie
            terminal code brackets
            wifi bluetooth battery
            sun moon
        }
    }

    # ── SVG definitions ──────────────────────────────────────────────────────
    proc _svg {name color size} {
        set s $size
        set h [expr {$s / 2.0}]
        set q [expr {$s / 4.0}]
        set sw [expr {max(1, $s / 16.0)}]  ;# stroke-width base

        # stroke-width scaled to icon size
        set sw1 [format "%.2f" [expr {$s * 0.09}]]
        set sw2 [format "%.2f" [expr {$s * 0.12}]]

        set head "<svg xmlns='http://www.w3.org/2000/svg' width='$s' height='$s' viewBox='0 0 24 24' fill='none' stroke='${color}' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>"
        set tail "</svg>"

        switch -- $name {
            arrow-up    { return "${head}<polyline points='18,15 12,9 6,15'/>$tail" }
            arrow-down  { return "${head}<polyline points='6,9 12,15 18,9'/>$tail" }
            arrow-left  { return "${head}<polyline points='15,18 9,12 15,6'/>$tail" }
            arrow-right { return "${head}<polyline points='9,6 15,12 9,18'/>$tail" }

            arrow-up-circle    { return "${head}<circle cx='12' cy='12' r='10'/><polyline points='16,14 12,10 8,14'/>$tail" }
            arrow-down-circle  { return "${head}<circle cx='12' cy='12' r='10'/><polyline points='8,10 12,14 16,10'/>$tail" }
            arrow-left-circle  { return "${head}<circle cx='12' cy='12' r='10'/><polyline points='14,8 10,12 14,16'/>$tail" }
            arrow-right-circle { return "${head}<circle cx='12' cy='12' r='10'/><polyline points='10,16 14,12 10,8'/>$tail" }

            chevron-up    { return "${head}<polyline points='18,14 12,8 6,14'/>$tail" }
            chevron-down  { return "${head}<polyline points='6,10 12,16 18,10'/>$tail" }
            chevron-left  { return "${head}<polyline points='14,18 8,12 14,6'/>$tail" }
            chevron-right { return "${head}<polyline points='10,6 16,12 10,18'/>$tail" }

            chevron-double-up    { return "${head}<polyline points='18,17 12,11 6,17'/><polyline points='18,11 12,5 6,11'/>$tail" }
            chevron-double-down  { return "${head}<polyline points='6,7 12,13 18,7'/><polyline points='6,13 12,19 18,13'/>$tail" }
            chevron-double-left  { return "${head}<polyline points='17,18 11,12 17,6'/><polyline points='11,18 5,12 11,6'/>$tail" }
            chevron-double-right { return "${head}<polyline points='7,6 13,12 7,18'/><polyline points='13,6 19,12 13,18'/>$tail" }

            check        { return "${head}<polyline points='20,6 9,17 4,12'/>$tail" }
            check-circle { return "${head}<path d='M22,11.08V12a10,10 0 1,1-5.93-9.14'/><polyline points='22,4 12,14.01 9,11.01'/>$tail" }
            check-square { return "${head}<polyline points='9,11 12,14 22,4'/><path d='M21,12v7a2,2 0 0,1-2,2H5a2,2 0 0,1-2-2V5a2,2 0 0,1,2-2h11'/>$tail" }

            x        { return "${head}<line x1='18' y1='6' x2='6' y2='18'/><line x1='6' y1='6' x2='18' y2='18'/>$tail" }
            x-circle { return "${head}<circle cx='12' cy='12' r='10'/><line x1='15' y1='9' x2='9' y2='15'/><line x1='9' y1='9' x2='15' y2='15'/>$tail" }
            x-square { return "${head}<rect x='3' y='3' width='18' height='18' rx='2'/><line x1='9' y1='9' x2='15' y2='15'/><line x1='15' y1='9' x2='9' y2='15'/>$tail" }

            plus        { return "${head}<line x1='12' y1='5' x2='12' y2='19'/><line x1='5' y1='12' x2='19' y2='12'/>$tail" }
            plus-circle { return "${head}<circle cx='12' cy='12' r='10'/><line x1='12' y1='8' x2='12' y2='16'/><line x1='8' y1='12' x2='16' y2='12'/>$tail" }
            minus        { return "${head}<line x1='5' y1='12' x2='19' y2='12'/>$tail" }
            minus-circle { return "${head}<circle cx='12' cy='12' r='10'/><line x1='8' y1='12' x2='16' y2='12'/>$tail" }

            info        { return "${head}<circle cx='12' cy='12' r='10'/><line x1='12' y1='8' x2='12' y2='8'/><line x1='12' y1='12' x2='12' y2='16'/>$tail" }
            info-circle { return "${head}<circle cx='12' cy='12' r='10'/><line x1='12' y1='16' x2='12' y2='12'/><line x1='12' y1='8' x2='12.01' y2='8'/>$tail" }
            warning         { return "${head}<path d='M10.29,3.86L1.82,18a2,2 0 0,0,1.71,3H20.47a2,2 0 0,0,1.71-3L13.71,3.86a2,2 0 0,0-3.42,0z'/><line x1='12' y1='9' x2='12' y2='13'/><line x1='12' y1='17' x2='12.01' y2='17'/>$tail" }
            warning-triangle { return "${head}<path d='M10.29,3.86L1.82,18a2,2 0 0,0,1.71,3H20.47a2,2 0 0,0,1.71-3L13.71,3.86a2,2 0 0,0-3.42,0z'/><line x1='12' y1='9' x2='12' y2='13'/><line x1='12' y1='17' x2='12.01' y2='17'/>$tail" }
            question        { return "${head}<circle cx='12' cy='12' r='10'/><path d='M9.09,9a3,3 0 0,1,5.83,1c0,2-3,3-3,3'/><line x1='12' y1='17' x2='12.01' y2='17'/>$tail" }
            question-circle { return "${head}<circle cx='12' cy='12' r='10'/><path d='M9.09,9a3,3 0 0,1,5.83,1c0,2-3,3-3,3'/><line x1='12' y1='17' x2='12.01' y2='17'/>$tail" }

            bell       { return "${head}<path d='M18,8A6,6 0 0,0,6,8c0,7-3,9-3,9H21s-3-2-3-9'/><path d='M13.73,21a2,2 0 0,1-3.46,0'/>$tail" }
            bell-slash { return "${head}<path d='M13.73,21a2,2 0 0,1-3.46,0'/><path d='M18.63,13A17.89,17.89 0 0,1,18,8'/><path d='M6.26,6.26A5.86,5.86 0 0,0,6,8c0,7-3,9-3,9H17'/><path d='M18,8a6,6 0 0,0-9.33-5'/><line x1='1' y1='1' x2='23' y2='23'/>$tail" }

            search  { return "${head}<circle cx='11' cy='11' r='8'/><line x1='21' y1='21' x2='16.65' y2='16.65'/>$tail" }
            zoom-in  { return "${head}<circle cx='11' cy='11' r='8'/><line x1='21' y1='21' x2='16.65' y2='16.65'/><line x1='11' y1='8' x2='11' y2='14'/><line x1='8' y1='11' x2='14' y2='11'/>$tail" }
            zoom-out { return "${head}<circle cx='11' cy='11' r='8'/><line x1='21' y1='21' x2='16.65' y2='16.65'/><line x1='8' y1='11' x2='14' y2='11'/>$tail" }
            filter   { return "${head}<polygon points='22,3 2,3 10,12.46 10,19 14,21 14,12.46 22,3'/>$tail" }
            sort-asc  { return "${head}<line x1='3' y1='9' x2='21' y2='9'/><line x1='3' y1='15' x2='15' y2='15'/><line x1='3' y1='21' x2='9' y2='21'/>$tail" }
            sort-desc { return "${head}<line x1='3' y1='5' x2='21' y2='5'/><line x1='3' y1='11' x2='15' y2='11'/><line x1='3' y1='17' x2='9' y2='17'/>$tail" }

            home    { return "${head}<path d='M3,9l9-7 9,7v11a2,2 0 0,1-2,2H5a2,2 0 0,1-2-2z'/><polyline points='9,22 9,12 15,12 15,22'/>$tail" }
            gear    { return "${head}<circle cx='12' cy='12' r='3'/><path d='M19.4,15a1.65,1.65 0 0,0,.33,1.82l.06.06a2,2 0 0,1-2.83,2.83l-.06-.06a1.65,1.65 0 0,0-1.82-.33 1.65,1.65 0 0,0-1,1.51V21a2,2 0 0,1-4,0v-.09A1.65,1.65 0 0,0,9,19.4a1.65,1.65 0 0,0-1.82.33l-.06.06a2,2 0 0,1-2.83-2.83l.06-.06A1.65,1.65 0 0,0,4.68,15a1.65,1.65 0 0,0-1.51-1H3a2,2 0 0,1,0-4h.09A1.65,1.65 0 0,0,4.6,9a1.65,1.65 0 0,0-.33-1.82l-.06-.06a2,2 0 0,1,2.83-2.83l.06.06A1.65,1.65 0 0,0,9,4.68a1.65,1.65 0 0,0,1-1.51V3a2,2 0 0,1,4,0v.09a1.65,1.65 0 0,0,1,1.51 1.65,1.65 0 0,0,1.82-.33l.06-.06a2,2 0 0,1,2.83,2.83l-.06.06A1.65,1.65 0 0,0,19.4,9a1.65,1.65 0 0,0,1.51,1H21a2,2 0 0,1,0,4h-.09a1.65,1.65 0 0,0-1.51,1z'/>$tail" }
            settings { return "${head}<circle cx='12' cy='12' r='3'/><path d='M19.4,15a1.65,1.65 0 0,0,.33,1.82l.06.06a2,2 0 0,1-2.83,2.83l-.06-.06a1.65,1.65 0 0,0-1.82-.33 1.65,1.65 0 0,0-1,1.51V21a2,2 0 0,1-4,0v-.09A1.65,1.65 0 0,0,9,19.4a1.65,1.65 0 0,0-1.82.33l-.06.06a2,2 0 0,1-2.83-2.83l.06-.06A1.65,1.65 0 0,0,4.68,15a1.65,1.65 0 0,0-1.51-1H3a2,2 0 0,1,0-4h.09A1.65,1.65 0 0,0,4.6,9a1.65,1.65 0 0,0-.33-1.82l-.06-.06a2,2 0 0,1,2.83-2.83l.06.06A1.65,1.65 0 0,0,9,4.68a1.65,1.65 0 0,0,1-1.51V3a2,2 0 0,1,4,0v.09a1.65,1.65 0 0,0,1,1.51 1.65,1.65 0 0,0,1.82-.33l.06-.06a2,2 0 0,1,2.83,2.83l-.06.06A1.65,1.65 0 0,0,19.4,9a1.65,1.65 0 0,0,1.51,1H21a2,2 0 0,1,0,4h-.09a1.65,1.65 0 0,0-1.51,1z'/>$tail" }
            wrench   { return "${head}<path d='M14.7,6.3a1,1 0 0,0,0,1.4l1.6,1.6a1,1 0 0,0,1.4,0l3.77-3.77a6,6 0 0,1-7.94,7.94l-6.91,6.91a2.12,2.12 0 0,1-3-3l6.91-6.91a6,6 0 0,1,7.94-7.94l-3.76,3.76z'/>$tail" }

            folder       { return "${head}<path d='M22,19a2,2 0 0,1-2,2H4a2,2 0 0,1-2-2V5A2,2 0 0,1,4,3H9l2,3H20a2,2 0 0,1,2,2z'/>$tail" }
            folder-open  { return "${head}<path d='M22,19a2,2 0 0,1-2,2H4a2,2 0 0,1-2-2V5A2,2 0 0,1,4,3H9l2,3H20a2,2 0 0,1,2,2z'/><polyline points='2,11 22,11'/>$tail" }
            file         { return "${head}<path d='M13,2H6A2,2 0 0,0,4,4V20a2,2 0 0,0,2,2H18a2,2 0 0,0,2-2V9z'/><polyline points='13,2 13,9 20,9'/>$tail" }
            file-text    { return "${head}<path d='M14,2H6A2,2 0 0,0,4,4V20a2,2 0 0,0,2,2H18a2,2 0 0,0,2-2V8z'/><polyline points='14,2 14,8 20,8'/><line x1='16' y1='13' x2='8' y2='13'/><line x1='16' y1='17' x2='8' y2='17'/><polyline points='10,9 9,9 8,9'/>$tail" }
            file-plus    { return "${head}<path d='M14,2H6A2,2 0 0,0,4,4V20a2,2 0 0,0,2,2H18a2,2 0 0,0,2-2V8z'/><polyline points='14,2 14,8 20,8'/><line x1='12' y1='18' x2='12' y2='12'/><line x1='9' y1='15' x2='15' y2='15'/>$tail" }
            file-minus   { return "${head}<path d='M14,2H6A2,2 0 0,0,4,4V20a2,2 0 0,0,2,2H18a2,2 0 0,0,2-2V8z'/><polyline points='14,2 14,8 20,8'/><line x1='9' y1='15' x2='15' y2='15'/>$tail" }

            save         { return "${head}<path d='M19,21H5a2,2 0 0,1-2-2V5a2,2 0 0,1,2-2h11l5,5V19a2,2 0 0,1-2,2z'/><polyline points='17,21 17,13 7,13 7,21'/><polyline points='7,3 7,8 15,8'/>$tail" }
            download     { return "${head}<path d='M21,15v4a2,2 0 0,1-2,2H5a2,2 0 0,1-2-2v-4'/><polyline points='7,10 12,15 17,10'/><line x1='12' y1='15' x2='12' y2='3'/>$tail" }
            upload       { return "${head}<path d='M21,15v4a2,2 0 0,1-2,2H5a2,2 0 0,1-2-2v-4'/><polyline points='17,8 12,3 7,8'/><line x1='12' y1='3' x2='12' y2='15'/>$tail" }
            cloud        { return "${head}<path d='M18,10h-1.26A8,8 0 1,0,9,20H18a5,5 0 0,0,0-10z'/>$tail" }

            edit         { return "${head}<path d='M11,4H4A2,2 0 0,0,2,6V20a2,2 0 0,0,2,2H16a2,2 0 0,0,2-2V13'/><path d='M18.5,2.5a2.121,2.121 0 0,1,3,3L12,15l-4,1 1-4 9.5-9.5z'/>$tail" }
            pencil       { return "${head}<path d='M17,3a2.828,2.828 0 1,1,4,4L7.5,20.5 2,22l1.5-5.5L17,3z'/>$tail" }
            trash        { return "${head}<polyline points='3,6 5,6 21,6'/><path d='M19,6v14a2,2 0 0,1-2,2H7a2,2 0 0,1-2-2V6m3,0V4a2,2 0 0,1,2-2h4a2,2 0 0,1,2,2v2'/><line x1='10' y1='11' x2='10' y2='17'/><line x1='14' y1='11' x2='14' y2='17'/>$tail" }
            delete       { return "${head}<polyline points='3,6 5,6 21,6'/><path d='M19,6v14a2,2 0 0,1-2,2H7a2,2 0 0,1-2-2V6'/>$tail" }

            copy      { return "${head}<rect x='9' y='9' width='13' height='13' rx='2'/><path d='M5,15H4a2,2 0 0,1-2-2V4A2,2 0 0,1,4,2H13a2,2 0 0,1,2,2v1'/>$tail" }
            cut       { return "${head}<circle cx='6' cy='6' r='3'/><circle cx='6' cy='18' r='3'/><line x1='20' y1='4' x2='8.12' y2='15.88'/><line x1='14.47' y1='14.48' x2='20' y2='20'/>$tail" }
            paste     { return "${head}<path d='M16,4h2a2,2 0 0,1,2,2V20a2,2 0 0,1-2,2H6a2,2 0 0,1-2-2V6A2,2 0 0,1,6,4H8'/><rect x='8' y='2' width='8' height='4' rx='1' ry='1'/>$tail" }
            clipboard { return "${head}<path d='M16,4h2a2,2 0 0,1,2,2V20a2,2 0 0,1-2,2H6a2,2 0 0,1-2-2V6A2,2 0 0,1,6,4H8'/><rect x='8' y='2' width='8' height='4' rx='1'/>$tail" }

            eye       { return "${head}<path d='M1,12s4-8,11-8 11,8 11,8-4,8-11,8-11-8-11-8z'/><circle cx='12' cy='12' r='3'/>$tail" }
            eye-slash { return "${head}<path d='M17.94,17.94A10.07,10.07 0 0,1,12,20c-7,0-11-8-11-8a18.45,18.45 0 0,1,5.06-5.94'/><path d='M9.9,4.24A9.12,9.12 0 0,1,12,4c7,0,11,8,11,8a18.5,18.5 0 0,1-2.16,3.19'/><line x1='1' y1='1' x2='23' y2='23'/>$tail" }
            lock      { return "${head}<rect x='3' y='11' width='18' height='11' rx='2'/><path d='M7,11V7a5,5 0 0,1,10,0v4'/>$tail" }
            unlock    { return "${head}<rect x='3' y='11' width='18' height='11' rx='2'/><path d='M7,11V7a5,5 0 0,1,9.9-1'/>$tail" }

            user      { return "${head}<path d='M20,21v-2a4,4 0 0,0-4-4H8a4,4 0 0,0-4,4v2'/><circle cx='12' cy='7' r='4'/>$tail" }
            users     { return "${head}<path d='M17,21v-2a4,4 0 0,0-4-4H5a4,4 0 0,0-4,4v2'/><circle cx='9' cy='7' r='4'/><path d='M23,21v-2a4,4 0 0,0-3-3.87'/><path d='M16,3.13a4,4 0 0,1,0,7.75'/>$tail" }
            person    { return "${head}<path d='M20,21v-2a4,4 0 0,0-4-4H8a4,4 0 0,0-4,4v2'/><circle cx='12' cy='7' r='4'/>$tail" }

            heart     { return "${head}<path d='M20.84,4.61a5.5,5.5 0 0,0-7.78,0L12,5.67l-1.06-1.06a5.5,5.5 0 0,0-7.78,7.78l1.06,1.06L12,21.23l7.78-7.78 1.06-1.06a5.5,5.5 0 0,0,0-7.78z'/>$tail" }
            star      { return "${head}<polygon points='12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26 12,2'/>$tail" }
            star-fill { return "<svg xmlns='http://www.w3.org/2000/svg' width='$s' height='$s' viewBox='0 0 24 24'><polygon points='12,2 15.09,8.26 22,9.27 17,14.14 18.18,21.02 12,17.77 5.82,21.02 7,14.14 2,9.27 8.91,8.26 12,2' fill='${color}' stroke='${color}' stroke-width='1'/>$tail" }
            bookmark  { return "${head}<path d='M19,21l-7-5-7,5V5a2,2 0 0,1,2-2H17a2,2 0 0,1,2,2z'/>$tail" }

            share         { return "${head}<circle cx='18' cy='5' r='3'/><circle cx='6' cy='12' r='3'/><circle cx='18' cy='19' r='3'/><line x1='8.59' y1='13.51' x2='15.42' y2='17.49'/><line x1='15.41' y1='6.51' x2='8.59' y2='10.49'/>$tail" }
            link          { return "${head}<path d='M10,13a5,5 0 0,0,7.54.54l3-3a5,5 0 0,0-7.07-7.07l-1.72,1.71'/><path d='M14,11a5,5 0 0,0-7.54-.54l-3,3a5,5 0 0,0,7.07,7.07l1.71-1.71'/>$tail" }
            external-link { return "${head}<path d='M18,13v6a2,2 0 0,1-2,2H5a2,2 0 0,1-2-2V8a2,2 0 0,1,2-2H11'/><polyline points='15,3 21,3 21,9'/><line x1='10' y1='14' x2='21' y2='3'/>$tail" }

            play         { return "${head}<polygon points='5,3 19,12 5,21 5,3'/>$tail" }
            pause        { return "${head}<rect x='6' y='4' width='4' height='16'/><rect x='14' y='4' width='4' height='16'/>$tail" }
            stop         { return "${head}<rect x='3' y='3' width='18' height='18' rx='2'/>$tail" }
            rewind       { return "${head}<polygon points='19,20 9,12 19,4 19,20'/><line x1='5' y1='19' x2='5' y2='5'/>$tail" }
            fast-forward { return "${head}<polygon points='5,4 15,12 5,20 5,4'/><line x1='19' y1='5' x2='19' y2='19'/>$tail" }

            volume      { return "${head}<polygon points='11,5 6,9 2,9 2,15 6,15 11,19 11,5'/><path d='M19.07,4.93a10,10 0 0,1,0,14.14'/><path d='M15.54,8.46a5,5 0 0,1,0,7.07'/>$tail" }
            volume-mute { return "${head}<polygon points='11,5 6,9 2,9 2,15 6,15 11,19 11,5'/><line x1='23' y1='9' x2='17' y2='15'/><line x1='17' y1='9' x2='23' y2='15'/>$tail" }

            calendar { return "${head}<rect x='3' y='4' width='18' height='18' rx='2'/><line x1='16' y1='2' x2='16' y2='6'/><line x1='8' y1='2' x2='8' y2='6'/><line x1='3' y1='10' x2='21' y2='10'/>$tail" }
            clock    { return "${head}<circle cx='12' cy='12' r='10'/><polyline points='12,6 12,12 16,14'/>$tail" }
            timer    { return "${head}<circle cx='12' cy='14' r='8'/><polyline points='12,6 12,14 16,14'/><line x1='8' y1='2' x2='16' y2='2'/>$tail" }

            image  { return "${head}<rect x='3' y='3' width='18' height='18' rx='2'/><circle cx='8.5' cy='8.5' r='1.5'/><polyline points='21,15 16,10 5,21'/>$tail" }
            photo  { return "${head}<path d='M23,19a2,2 0 0,1-2,2H3a2,2 0 0,1-2-2V8A2,2 0 0,1,3,6H7l2-3H15l2,3H21a2,2 0 0,1,2,2z'/><circle cx='12' cy='13' r='4'/>$tail" }
            camera { return "${head}<path d='M23,19a2,2 0 0,1-2,2H3a2,2 0 0,1-2-2V8A2,2 0 0,1,3,6H7l2-3H15l2,3H21a2,2 0 0,1,2,2z'/><circle cx='12' cy='13' r='4'/>$tail" }

            mail   { return "${head}<path d='M4,4H20a2,2 0 0,1,2,2V18a2,2 0 0,1-2,2H4a2,2 0 0,1-2-2V6A2,2 0 0,1,4,4z'/><polyline points='22,6 12,13 2,6'/>$tail" }
            inbox  { return "${head}<polyline points='22,12 16,12 14,15 10,15 8,12 2,12'/><path d='M5.45,5.11L2,12v6a2,2 0 0,0,2,2H20a2,2 0 0,0,2-2v-6L18.55,5.11A2,2 0 0,0,16.76,4H7.24A2,2 0 0,0,5.45,5.11z'/>$tail" }
            send   { return "${head}<line x1='22' y1='2' x2='11' y2='13'/><polygon points='22,2 15,22 11,13 2,9 22,2'/>$tail" }
            reply  { return "${head}<polyline points='9,17 4,12 9,7'/><path d='M20,18v-2a4,4 0 0,0-4-4H4'/>$tail" }

            tag      { return "${head}<path d='M20.59,13.41l-7.17,7.17a2,2 0 0,1-2.83,0L2,12V2H12L20.59,10.59A2,2 0 0,1,20.59,13.41z'/><line x1='7' y1='7' x2='7.01' y2='7'/>$tail" }
            label    { return "${head}<path d='M20.59,13.41l-7.17,7.17a2,2 0 0,1-2.83,0L2,12V2H12L20.59,10.59A2,2 0 0,1,20.59,13.41z'/><line x1='7' y1='7' x2='7.01' y2='7'/>$tail" }
            flag     { return "${head}<path d='M4,15s1-1,4-1 5,2 8,2 4-1,4-1V3S19,4 16,4s-5-2-8-2-4,1-4,1z'/><line x1='4' y1='22' x2='4' y2='15'/>$tail" }

            refresh      { return "${head}<polyline points='23,4 23,10 17,10'/><path d='M20.49,15a9,9 0 1,1-2.12-9.36L23,10'/>$tail" }
            reset        { return "${head}<path d='M2.5,2v6h6'/><path d='M2.66,15.57a10,10 0 1,0,.57-8.38'/>$tail" }
            rotate-left  { return "${head}<polyline points='1,4 1,10 7,10'/><path d='M3.51,15a9,9 0 1,0,.49-4.51L1,10'/>$tail" }
            rotate-right { return "${head}<polyline points='23,4 23,10 17,10'/><path d='M20.49,15a9,9 0 1,1-2.12-9.36L23,10'/>$tail" }

            columns  { return "${head}<path d='M12,3H5A2,2 0 0,0,3,5V19a2,2 0 0,0,2,2H19a2,2 0 0,0,2-2V12'/><path d='M12,3H19a2,2 0 0,1,2,2V12'/><line x1='12' y1='3' x2='12' y2='21'/>$tail" }
            rows     { return "${head}<path d='M3,5A2,2 0 0,1,5,3H19a2,2 0 0,1,2,2V12'/><path d='M3,12H21'/><path d='M3,12V19a2,2 0 0,0,2,2H19a2,2 0 0,0,2-2V12'/>$tail" }
            table    { return "${head}<rect x='3' y='3' width='18' height='18' rx='2'/><line x1='3' y1='9' x2='21' y2='9'/><line x1='3' y1='15' x2='21' y2='15'/><line x1='9' y1='9' x2='9' y2='21'/><line x1='15' y1='9' x2='15' y2='21'/>$tail" }
            grid     { return "${head}<rect x='3' y='3' width='7' height='7'/><rect x='14' y='3' width='7' height='7'/><rect x='3' y='14' width='7' height='7'/><rect x='14' y='14' width='7' height='7'/>$tail" }
            list     { return "${head}<line x1='8' y1='6' x2='21' y2='6'/><line x1='8' y1='12' x2='21' y2='12'/><line x1='8' y1='18' x2='21' y2='18'/><line x1='3' y1='6' x2='3.01' y2='6'/><line x1='3' y1='12' x2='3.01' y2='12'/><line x1='3' y1='18' x2='3.01' y2='18'/>$tail" }

            chart-bar  { return "${head}<line x1='18' y1='20' x2='18' y2='10'/><line x1='12' y1='20' x2='12' y2='4'/><line x1='6' y1='20' x2='6' y2='14'/><line x1='2' y1='20' x2='22' y2='20'/>$tail" }
            chart-line { return "${head}<polyline points='22,12 18,12 15,21 9,3 6,12 2,12'/>$tail" }
            chart-pie  { return "${head}<path d='M21.21,15.89A10,10 0 1,1,8,2.83'/><path d='M22,12A10,10 0 0,0,12,2v10z'/>$tail" }

            terminal  { return "${head}<polyline points='4,17 10,11 4,5'/><line x1='12' y1='19' x2='20' y2='19'/>$tail" }
            code      { return "${head}<polyline points='16,18 22,12 16,6'/><polyline points='8,6 2,12 8,18'/>$tail" }
            brackets  { return "${head}<polyline points='16,18 22,12 16,6'/><polyline points='8,6 2,12 8,18'/>$tail" }

            wifi      { return "${head}<path d='M5,12.55a11,11 0 0,1,14.08,0'/><path d='M1.42,9A16,16 0 0,1,22.58,9'/><path d='M8.53,16.11a6,6 0 0,1,6.95,0'/><line x1='12' y1='20' x2='12.01' y2='20'/>$tail" }
            bluetooth { return "${head}<polyline points='6.5,6.5 17.5,17.5 12,23 12,1 17.5,6.5 6.5,17.5'/>$tail" }
            battery   { return "${head}<rect x='1' y='6' width='18' height='12' rx='2'/><line x1='23' y1='13' x2='23' y2='11'/>$tail" }

            sun  { return "${head}<circle cx='12' cy='12' r='5'/><line x1='12' y1='1' x2='12' y2='3'/><line x1='12' y1='21' x2='12' y2='23'/><line x1='4.22' y1='4.22' x2='5.64' y2='5.64'/><line x1='18.36' y1='18.36' x2='19.78' y2='19.78'/><line x1='1' y1='12' x2='3' y2='12'/><line x1='21' y1='12' x2='23' y2='12'/><line x1='4.22' y1='19.78' x2='5.64' y2='18.36'/><line x1='18.36' y1='5.64' x2='19.78' y2='4.22'/>$tail" }
            moon { return "${head}<path d='M21,12.79A9,9 0 1,1,11.21,3 7,7 0 0,0,21,12.79z'/>$tail" }

            default { return "" }
        }
    }
}

# ─────────────────────────────────────────────────────────────────────────────
# Emoji constants
# ─────────────────────────────────────────────────────────────────────────────
namespace eval ttkbootstrap::Emoji {

    # Internal: generate a photo image from this namespace's _svg data
    proc _img {name} {
        set color [ttkbootstrap::getColor fg]
        set scale [ttkbootstrap::img::size]
        # Reuse images.tcl cache infrastructure for efficiency
        set key "${name}|${color}|${scale}"
        if {[info exists ::ttkbs::emoji_cache($key)]} {
            return $::ttkbs::emoji_cache($key)
        }
        set svg [ttkbootstrap::Icon::_svg $name $color]
        if {$svg eq {}} { return {} }
        set imgname "::ttkbs::emoji::${name}_[string map {# _} $color]_${scale}"
        catch { image delete $imgname }
        set iscale [expr {max(1, int(round($scale)))}]
        catch {
            image create photo $imgname                 -data $svg                 -format [list svg -scale $iscale]
            set ::ttkbs::emoji_cache($key) $imgname
        }
        return $imgname
    }
    proc check     {} { return "✓" }
    proc x         {} { return "✗" }
    proc warning   {} { return "⚠" }
    proc info      {} { return "ℹ" }
    proc question  {} { return "?" }
    proc star      {} { return "★" }
    proc heart     {} { return "♥" }
    proc left      {} { return "←" }
    proc right     {} { return "→" }
    proc up        {} { return "↑" }
    proc down      {} { return "↓" }
    proc plus      {} { return "+" }
    proc minus     {} { return "−" }
    proc refresh   {} { return "↻" }
    proc search     {} {
        set img [ttkbootstrap::Emoji::_img search]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc home      {} { return "⌂" }
    proc mail      {} { return "✉" }
    proc lock       {} {
        set img [ttkbootstrap::Emoji::_img lock]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc unlock     {} {
        set img [ttkbootstrap::Emoji::_img unlock]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc calendar  {} {
        return [ttkbootstrap::img::get icon.calendar             [ttkbootstrap::getColor fg] [ttkbootstrap::img::size]]
    }
    proc clock     {} {
        return [ttkbootstrap::img::get icon.clock             [ttkbootstrap::getColor fg] [ttkbootstrap::img::size]]
    }
    proc folder     {} {
        set img [ttkbootstrap::Emoji::_img folder]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc file       {} {
        set img [ttkbootstrap::Emoji::_img file]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc trash      {} {
        set img [ttkbootstrap::Emoji::_img trash]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc edit      {} { return "✏" }
    proc copy       {} {
        set img [ttkbootstrap::Emoji::_img copy]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc save       {} {
        set img [ttkbootstrap::Emoji::_img save]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc download   {} {
        set img [ttkbootstrap::Emoji::_img download]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc upload    {} { return "⬆" }
    proc play      {} { return "▶" }
    proc pause     {} { return "⏸" }
    proc stop      {} { return "⏹" }
    proc sun       {} { return "☀" }
    proc moon      {} { return "☾" }
    proc gear      {} { return "⚙" }
    proc bell       {} {
        set img [ttkbootstrap::Emoji::_img bell]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc tag        {} {
        set img [ttkbootstrap::Emoji::_img tag]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc pin        {} {
        set img [ttkbootstrap::Emoji::_img pin]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc link       {} {
        set img [ttkbootstrap::Emoji::_img link]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc eye        {} {
        set img [ttkbootstrap::Emoji::_img eye]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc user       {} {
        set img [ttkbootstrap::Emoji::_img user]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc users      {} {
        set img [ttkbootstrap::Emoji::_img users]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc chart      {} {
        set img [ttkbootstrap::Emoji::_img chart-bar]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc code      {} { return "⌨" }
    proc terminal  {} { return ">" }
    proc wifi       {} {
        set img [ttkbootstrap::Emoji::_img wifi]
        if {$img ne {}} { return $img }
        return "•"
    }
    proc battery    {} {
        set img [ttkbootstrap::Emoji::_img battery]
        if {$img ne {}} { return $img }
        return "•"
    }
}
