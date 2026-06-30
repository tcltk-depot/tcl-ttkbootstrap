# =============================================================================
# gallery_icons.tcl — Asset-free icon loader for the gallery demo apps.
#
# The original ttkbootstrap demos shipped icons8 PNG files under
# gallery/assets/. Those binaries were never bundled, so the apps crashed with
# "couldn't open ...png: no such file or directory". Since this is an SVG
# widget library, we regenerate the icons from SVG at runtime instead — using
# the built-in ttkbootstrap::Icon set where possible, plus a handful of custom
# glyphs for shapes the set doesn't include (broom, mouse, move, backup).
#
#   gallery_make_icon  imgName  icons8Filename  ?color?
#     Creates (or replaces) a photo image named imgName for the given legacy
#     icons8 filename. Size is parsed from the "_NNpx" token (default 24).
#     color may be a hex, a theme keyword (primary/fg/...), or white/black;
#     defaults to the theme foreground.
# =============================================================================

# Legacy-name → icon mapping. {icon NAME} uses the built-in Icon set;
# {svg NAME} uses a custom glyph from gallery_icon_svg below.
set ::gallery_icon_map {
    reset            {icon reset}
    submit_progress  {icon check-circle}
    question_mark    {icon question}
    move             {svg move}
    bluetooth        {icon bluetooth}
    buy              {icon tag}
    magic_mouse      {svg mouse}
    broom            {svg broom}
    registry_editor  {icon list}
    wrench           {icon wrench}
    settings         {icon settings}
    spy              {icon eye}
    trash_can        {icon trash}
    protect          {icon lock}
    add_folder       {icon folder}
    add_book         {icon bookmark}
    cancel           {icon x}
    play             {icon play}
    refresh          {icon refresh}
    stop             {icon stop}
    opened_folder    {icon folder-open}
    double_up        {icon chevron-double-up}
    double_right     {icon chevron-double-right}
    backup           {svg backup}
}

proc gallery_resolve_color {color} {
    if {$color eq ""} { return [ttkbootstrap::getColor fg] }
    if {[string match "#*" $color]} { return $color }
    switch -- $color {
        white { return "#ffffff" }
        black { return "#000000" }
    }
    if {![catch {ttkbootstrap::getColor $color} hx] && $hx ne ""} { return $hx }
    return $color
}

# Custom SVG glyphs (24x24 viewBox) for shapes not in the Icon set.
proc gallery_icon_svg {name color size} {
    set h "<svg xmlns='http://www.w3.org/2000/svg' width='$size' height='$size' viewBox='0 0 24 24'>"
    switch -- $name {
        move {
            set body "<g fill='$color'>\
<polygon points='12,1 8,6 16,6'/><polygon points='12,23 8,18 16,18'/>\
<polygon points='1,12 6,8 6,16'/><polygon points='23,12 18,8 18,16'/>\
<rect x='11' y='5' width='2' height='14'/><rect x='5' y='11' width='14' height='2'/></g>"
        }
        mouse {
            set body "<rect x='6' y='2' width='12' height='20' rx='6' ry='6' fill='none' stroke='$color' stroke-width='2'/>\
<line x1='12' y1='4.5' x2='12' y2='9' stroke='$color' stroke-width='2' stroke-linecap='round'/>"
        }
        broom {
            set body "<line x1='20' y1='4' x2='11.5' y2='12.5' stroke='$color' stroke-width='2' stroke-linecap='round'/>\
<path d='M11 12 L4 17 L8 21 L15 16 Z' fill='$color'/>"
        }
        backup {
            set body "<g fill='none' stroke='$color' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>\
<path d='M6.5 18 H16.5 A3.5 3.5 0 0 0 17 11 A5 5 0 0 0 7.2 9.5 A3.8 3.8 0 0 0 6.5 18 Z'/>\
<polyline points='9.5,13.5 12,11 14.5,13.5'/><line x1='12' y1='11' x2='12' y2='17'/></g>"
        }
        default {
            set body "<rect x='3' y='3' width='18' height='18' rx='4' fill='none' stroke='$color' stroke-width='2'/>\
<circle cx='12' cy='12' r='2' fill='$color'/>"
        }
    }
    return "$h$body</svg>"
}

proc gallery_make_icon {imgname file {color ""}} {
    set color [gallery_resolve_color $color]

    set size 24
    if {[regexp {_([0-9]+)px} $file -> s]} { set size $s }

    set base [file rootname $file]
    regsub {^icons8_} $base "" base
    regsub {_[0-9]+px} $base "" base
    regsub {_[0-9]+$} $base "" base

    set svg ""
    if {[dict exists $::gallery_icon_map $base]} {
        lassign [dict get $::gallery_icon_map $base] kind val
        if {$kind eq "icon"} {
            set src ""
            catch { set src [ttkbootstrap::Icon::get $val $color $size] }
            if {$src ne "" && [lsearch -exact [image names] $src] >= 0} {
                catch { image delete $imgname }
                image create photo $imgname
                $imgname copy $src
                return $imgname
            }
        } else {
            set svg [gallery_icon_svg $val $color $size]
        }
    }
    if {$svg eq ""} { set svg [gallery_icon_svg generic $color $size] }

    set scale 1.0
    catch { set scale [ttkbootstrap::img::size] }
    catch { image delete $imgname }
    image create photo $imgname -data $svg -format "svg -scale $scale"
    return $imgname
}
