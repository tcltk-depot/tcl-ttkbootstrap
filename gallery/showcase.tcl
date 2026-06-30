# =============================================================================
# showcase.tcl — ttkbootstrap unified widget showcase
# =============================================================================
#
# WHAT THIS FILE IS
# -----------------
# A single sidebar-driven application that demonstrates every widget in the
# ttkbootstrap package with live, interactive examples. Pick a section in the
# left sidebar and the right-hand area rebuilds to show that group of widgets.
#
#   Run:  tclkit showcase.tcl        (or:  wish showcase.tcl)
#
# This file doubles as the project's primary worked example, so the sections
# below explain not just WHAT the code does but WHY — especially the handful of
# non-obvious patterns that are easy to get wrong. If you are learning the
# library, the most reusable techniques are also extracted as short standalone
# recipes in  docs/cookbook/svg-widget-patterns.md  — start there if you only
# want the pattern without the surrounding showcase scaffolding.
#
# HOW THE FILE IS ORGANISED
# -------------------------
#   1. Window setup + DPI/desktop scaling          (top of file)
#   2. Gallery-app launcher + splash helpers        (launch_gallery, splash)
#   3. show_page / section_hdr / page_sf helpers     (the page engine)
#   4. build_<section> procs, one per sidebar entry  (build_buttons, ...)
#   5. Chrome: sidebar, navbar, theme controls, status bar (bottom of file)
#
# KEY PATTERNS DEMONSTRATED HERE (and why they matter)
# ----------------------------------------------------
# * Per-page REBUILD model. show_page destroys every child of the page frame
#   ($::pf) and calls build_<section> fresh. Because widget paths are derived
#   from per-section counters (e.g. .gb1, .gb2), every counter is reset at the
#   top of show_page so rebuilt pages reuse the same paths instead of growing
#   unboundedly across visits. If you add a new build_ proc that uses an
#   incrementing index, add that counter to the reset list in show_page.
#
# * DPI / scaling helpers. Never hard-code pixel sizes. ttkbootstrap::_sp N
#   scales a pixel value for the current DPI; _sp2 a b scales a {pad pad} pair;
#   _sf N scales a font point size. Every size in this file goes through them so
#   the UI looks right on HiDPI and large desktops.
#
# * SVG transparent-corner technique. nanosvg renders the area OUTSIDE a rounded
#   shape as transparent, which composites to black/white "tips" at the corners
#   unless handled. Two safe approaches are used throughout:
#     (a) leave the corners transparent and set the host widget's -bg to match
#         the surrounding surface (used for canvas-hosted widgets), or
#     (b) draw a full-canvas <rect> in the page background colour BEHIND the
#         rounded shape so the antialiased corner blends colour->page-bg inside
#         the image (used for label-hosted images such as the theme swatches).
#   See the theme-swatch block on the Settings page for a worked example,
#   including why the swatch image must be REGENERATED on <<ThemeChanged>>.
#
# * Live theming. Switching theme fires the virtual event <<ThemeChanged>>.
#   Widgets that cache a rendered SVG image (rather than re-reading theme
#   colours on the fly) must rebind <<ThemeChanged>> to regenerate themselves,
#   or they will keep stale colours. The Settings theme-swatches show this.
#
# * In-window slide-in. A floating toplevel cannot be clipped by another
#   window, so to make a notification banner appear to "slide in from the edge"
#   it is rendered as a place-managed CHILD of the page area and animated with
#   place -x; the parent frame clips the part that has not arrived yet. See the
#   Overlays page (SVGNotificationBanner -parent ...).
#
# =============================================================================

package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

# ── Main window ────────────────────────────────────────────────────────────────
ttkbootstrap::Window \
    -themename litera \
    -title     "ttkbootstrap — Widget Showcase" \
    -size      {1100 720}

# Scale the window to fill the screen proportionally so the demo looks right on
# everything from a laptop to a 4K desktop. The logic: take the baseline design
# size (1100x720 at 1920x1080), grow it by whichever is larger of the desktop
# scale factor or the DPI scale factor, then clamp to the actual screen and
# centre it. _sp-based widget sizing handles the rest of the HiDPI scaling.
after idle {
    set _scrw [winfo screenwidth .]
    set _scrh [winfo screenheight .]
    # Scale factor: how much bigger is this screen vs the baseline 1920x1080
    set _sx [expr {$_scrw / 1920.0}]
    set _sy [expr {$_scrh / 1080.0}]
    # Use the smaller factor so it fits, minimum 1.0
    set _sfactor [expr {min($_sx, $_sy)}]
    if {$_sfactor < 1.0} { set _sfactor 1.0 }
    # Also apply DPI scaling
    set _dpiscale [ttkbootstrap::scaleFactor]
    set _factor [expr {max($_sfactor, $_dpiscale)}]
    set _sw [expr {int(1100 * $_factor)}]
    set _sh [expr {int(720 * $_factor)}]
    # Clamp to screen size with margin
    set _maxw [expr {$_scrw - 40}]
    set _maxh [expr {$_scrh - 60}]
    if {$_sw > $_maxw} { set _sw $_maxw }
    if {$_sh > $_maxh} { set _sh $_maxh }
    # Centre on screen
    set _gx [expr {($_scrw - $_sw) / 2}]
    set _gy [expr {($_scrh - $_sh) / 2}]
    wm geometry . ${_sw}x${_sh}+${_gx}+${_gy}
}

wm protocol . WM_DELETE_WINDOW { exit }


# ── Per-section widget-path counters ───────────────────────────────────────────
# Each build_<section> proc names its widgets with an incrementing index so it
# can create several of the same widget type (.gb1, .gb2, ...). show_page resets
# every one of these to 0 before rebuilding a page, so revisiting a page reuses
# the same widget paths rather than leaking new ones. ADD NEW COUNTERS HERE *and*
# to the reset list in show_page if you introduce a new indexed widget.
set ::hdr_idx 0
set ::card_idx 0
set ::rr 0
set ::svg_idx 0
set ::svgc_idx 0
set ::svgr_idx 0
set ::svgm_idx 0

# ═══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════

proc ttkbootstrap::_ring_animate {step} {
    foreach item $::ring_widgets {
        lassign $item w target
        if {![winfo exists $w]} continue
        set cur [expr {min($target, $step * 5)}]
        ttkbootstrap::SVGProgressRing_set $w $cur
    }
    if {$step < 20} {
        after 50 [list ttkbootstrap::_ring_animate [expr {$step + 1}]]
    }
}


# ═══════════════════════════════════════════════════════════════════════════════
# BUTTONS
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# INPUTS
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY
# ═══════════════════════════════════════════════════════════════════════════════
# ═══════════════════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# DATE & TIME
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# NAVIGATION
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# OVERLAYS
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# LAYOUT
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# GALLERY APPS
# ═══════════════════════════════════════════════════════════════════════════════

proc _do_close_gallery {interp} {
    catch { interp eval $interp { destroy . } }
    after 50 [list catch [list interp delete $interp]]
}

proc launch_gallery {key gallery_dir} {
    set file [file join $gallery_dir ${key}.tcl]
    if {![file exists $file]} {
        ttkbootstrap::StatusBar::msg $::sbbar "File not found: $file" -clear 3000
        return
    }

    # MDI launches as its own standalone window — no custom chrome wrapper
    if {$key eq "mdi"} {
        set i [interp create]
        interp alias $i _close_gallery {} _do_close_gallery $i
        interp eval $i [list package require Tk]
        interp eval $i [list lappend auto_path [file join $gallery_dir ..]]
        interp eval $i [list package require ttkbootstrap]
        interp eval $i [list ttkbootstrap::setTheme [ttkbootstrap::currentTheme]]
        interp eval $i [list source $file]
        ttkbootstrap::StatusBar::msg $::sbbar "Launched: MDI Desktop" -clear 2000
        return
    }

    set i     [interp create]
    set title [string totitle [string map {_ " "} $key]]
    set theme [ttkbootstrap::currentTheme]
    set apath [file join $gallery_dir ..]

    # Safe close — runs in parent interp, not child
    # _close_gallery: clear hover bindings first so they don't fire
    # into a deleted interp, then destroy after current event completes.
    proc _do_close_gallery {interp} {
        # Destroy all widgets first — this cancels all pending Tk events
        # and binding callbacks before the interp is torn down.
        # Without this, buttons/widgets fire their release events into
        # a dead interpreter and produce background errors.
        catch { interp eval $interp { destroy . } }
        # Small delay lets the event queue drain before deleting the interp
        after 50 [list catch [list interp delete $interp]]
    }
    interp alias $i _close_gallery {} _do_close_gallery $i

    # Initialise Tk + ttkbootstrap in child
    interp eval $i [list package require Tk]
    interp eval $i [list lappend auto_path $apath]
    interp eval $i [list package require ttkbootstrap]
    interp eval $i [list ttkbootstrap::setTheme $theme]

    # Window setup now handled after title bar build (below)

    # Use per-app natural size (measured from actual rendering)
    # Add 36px for our custom title bar
    # Per-app sizes: natural width x (height + 36px title bar)
    array set _app_sizes {
        mdi                       {1200 814}
        calculator                {350 486}
        back_me_up                {900 680}
        collapsing_frame          {420 470}
        data_entry                {500 300}
        equalizer                 {900 330}
        file_search_engine        {720 550}
        long_running_determinate  {440 280}
        long_running_indeterminate {440 280}
        magic_mouse               {900 610}
        media_player              {700 616}
        pc_cleaner                {900 650}
        stopwatch                 {420 220}
        text_reader               {800 730}
    }
    set _appkey [file rootname [file tail $file]]
    if {[info exists _app_sizes($_appkey)]} {
        set _w [lindex $_app_sizes($_appkey) 0]
        set _h [lindex $_app_sizes($_appkey) 1]
    } else {
        set _w 800; set _h 600
    }
    interp eval $i [list set _w $_w]
    interp eval $i [list set _h $_h]
    # Centre over the main showcase window (not the screen)
    set _mx [winfo rootx .]
    set _my [winfo rooty .]
    set _mw [winfo width  .]
    set _mh [winfo height .]
    set _gx [expr {$_mx + ($_mw - $_w) / 2}]
    set _gy [expr {$_my + ($_mh - $_h) / 2}]
    # Clamp to screen bounds
    set _sw [winfo screenwidth  .]
    set _sh [winfo screenheight .]
    set _gx [expr {max(0, min($_gx, $_sw - $_w))}]
    set _gy [expr {max(0, min($_gy, $_sh - $_h))}]
    interp eval $i [list wm geometry . ${_w}x${_h}+${_gx}+${_gy}]
    interp eval $i [list wm minsize . [expr {min($_w,400)}] [expr {min($_h,300)}]]
    interp eval $i {wm deiconify .}

    # Build custom title bar directly inside child interp
    set ac  [ttkbootstrap::getColor primary]
    set fg  [ttkbootstrap::_contrastFg $ac]
    set hbg [ttkbootstrap::_darken $ac 18]
    set bdr [ttkbootstrap::getColor border]
    set fnm [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs  [ttkbootstrap::_sf 12]
    set fsx [ttkbootstrap::_sf 15]

    interp eval $i [list frame  .tb -bg $ac -height 34]
    interp eval $i [list pack   .tb -fill x -side top]
    interp eval $i [list label  .tb.t         -text $title -bg $ac -fg $fg -anchor w -padx 12         -font [list $fnm $fs bold]]
    interp eval $i [list pack   .tb.t -side left -fill y]
    interp eval $i [list label  .tb.x         -text " × " -bg $ac -fg $fg -cursor hand2         -font [list $fnm $fsx bold] -padx 6]
    interp eval $i [list pack   .tb.x -side right]
    interp eval $i [list bind   .tb.x <Enter>    [list .tb.x configure -bg $hbg]]
    interp eval $i [list bind   .tb.x <Leave>    [list .tb.x configure -bg $ac]]
    interp eval $i {bind .tb.x <Button-1> _close_gallery}
    interp eval $i {
        foreach _w {.tb .tb.t} {
            bind $_w <Button-1>  { set ::_gx %X; set ::_gy %Y }
            bind $_w <B1-Motion> {
                set _nx [expr {[winfo x .] + %X - $::_gx}]
                set _ny [expr {[winfo y .] + %Y - $::_gy}]
                wm geometry . +${_nx}+${_ny}
                set ::_gx %X; set ::_gy %Y
            }
        }
    }
    interp eval $i [list frame .tbb -bg $bdr -height 1]
    interp eval $i [list pack  .tbb -fill x -side top]

    # Inject a custom tk_messageBox that stays on top of our borderless window
    interp eval $i {
        rename tk_messageBox _tk_messageBox_orig
        proc tk_messageBox {args} {
            array set o {-title "Message" -message "" -type ok
                         -icon info -default ok}
            array set o $args

            # Build a centred borderless dialog over the gallery window
            set d [toplevel .__gallery_msg -relief solid -borderwidth 1]
            wm withdraw $d
            wm overrideredirect $d 1
            wm transient $d .

            set ac  [ttkbootstrap::getColor primary]
            set fg  [ttkbootstrap::_contrastFg $ac]
            set bg  [ttkbootstrap::getColor bg]
            set fgn [ttkbootstrap::getColor fg]

            # Title bar
            frame $d.tb -bg $ac
            pack  $d.tb -fill x
            label $d.tb.t -text $o(-title) -bg $ac -fg $fg                 -font [list [ttkbootstrap::_safeFont $fgn]                            [ttkbootstrap::_sf 11] bold]                 -padx 8 -pady 4
            pack $d.tb.t -side left

            # Message
            frame $d.body -bg $bg -padx 16 -pady 12
            pack  $d.body -fill x
            label $d.body.msg -text $o(-message) -bg $bg -fg $fgn                 -wraplength 320 -justify left                 -font [list [ttkbootstrap::_safeFont $fgn] [ttkbootstrap::_sf 11]]
            pack  $d.body.msg

            # Buttons
            frame $d.foot -bg $bg -padx 12 -pady 8
            pack  $d.foot -fill x

            set ::__gallery_dialog_result "ok"
            set btns [dict create                 ok     "OK"     cancel "Cancel"                 yes    "Yes"    no     "No"                     abort  "Abort"  retry  "Retry"                  ignore "Ignore"]
            set btnlist {}
            switch -- $o(-type) {
                ok             { set btnlist {ok} }
                okcancel       { set btnlist {ok cancel} }
                yesno          { set btnlist {yes no} }
                yesnocancel    { set btnlist {yes no cancel} }
                retrycancel    { set btnlist {retry cancel} }
                abortretryignore { set btnlist {abort retry ignore} }
                default        { set btnlist {ok} }
            }
            foreach btn $btnlist {
                set lbl [dict get $btns $btn]
                set style [expr {$btn in {ok yes retry} ?                     "primary.TButton" : "secondary.Outline.TButton"}]
                ttk::button $d.foot.$btn                     -text    $lbl                     -style   $style                     -padding [ttkbootstrap::_sp2 16 4]                     -command [list set ::__gallery_dialog_result $btn]
                pack $d.foot.$btn -side right -padx 4
            }

            # Centre over the gallery window
            update idletasks
            set pw [winfo width  .]
            set ph [winfo height .]
            set px [winfo rootx  .]
            set py [winfo rooty  .]
            set dw [winfo reqwidth  $d]
            set dh [winfo reqheight $d]
            wm geometry $d +[expr {$px+($pw-$dw)/2}]+[expr {$py+($ph-$dh)/2}]
            wm deiconify $d
            raise $d
            grab $d
            focus $d.foot.[lindex $btnlist 0]
            vwait ::__gallery_dialog_result
            grab release $d
            destroy $d
            return $::__gallery_dialog_result
        }
    }

    # Inject pure-Tk replacements for file dialogs so they stay on top
    # Inject pure-Tk replacements for file dialogs so they stay on top
    # and don't get WM decorations
    interp eval $i {
        rename tk_getOpenFile    _tk_getOpenFile_orig
        rename tk_chooseDirectory _tk_chooseDirectory_orig
        rename tk_getSaveFile    _tk_getSaveFile_orig

        proc tk_getOpenFile {args} {
            array set o {-title "Open File" -filetypes {} -initialdir {} -parent .}
            array set o $args
            return [ttkbootstrap::GetOpenFile                 -title      $o(-title)                 -filetypes  $o(-filetypes)                 -initialdir $o(-initialdir)                 -parent     .]
        }

        proc tk_chooseDirectory {args} {
            array set o {-title "Choose Directory" -initialdir {} -parent .}
            array set o $args
            return [ttkbootstrap::ChooseDirectory                 -title      $o(-title)                 -initialdir $o(-initialdir)                 -parent     .]
        }

        proc tk_getSaveFile {args} {
            array set o {-title "Save File" -filetypes {} -initialdir {} -parent .}
            array set o $args
            return [ttkbootstrap::GetOpenFile                 -title      $o(-title)                 -filetypes  $o(-filetypes)                 -initialdir $o(-initialdir)                 -parent     .]
        }
    }

    # Override ttkbootstrap::Window so app can't reset our geometry
    interp eval $i {
        proc ttkbootstrap::Window {args} {
            array set o {-themename {} -title {} -size {}}
            catch { array set o $args }
            if {$o(-themename) ne {}} { catch { ttkbootstrap::setTheme $o(-themename) } }
        }
    }

    # Keyboard focus: when entry clicked in child interp, grab X11 focus
    interp eval $i {
        bind GalleryFocus <Button-1> {
            catch { focus -force . ; focus %W }
        }
        proc _gallery_add_focus_tag {w} {
            set tags [bindtags $w]
            if {"GalleryFocus" ni $tags} {
                bindtags $w [linsert $tags 0 GalleryFocus]
            }
        }
        foreach _cls {TEntry Entry TSpinbox Spinbox TCombobox Text TText} {
            bind $_cls <Map> {+ catch { _gallery_add_focus_tag %W }}
        }
    }

    # Source the gallery app — its widgets pack below our title bar
    # wm deiconify MUST be before source because source blocks on vwait
    interp eval $i {wm withdraw .}
    catch { interp eval $i {wm attributes . -type dialog} }
    interp eval $i {wm title . ""}
    interp eval $i {wm deiconify .}
    interp eval $i [list source $file]

    # Suppress any vwait/WM_DELETE that the app may have set
    catch { interp eval $i {wm protocol . WM_DELETE_WINDOW {}} }

    ttkbootstrap::StatusBar::msg $::sbbar "Launched: $key" -clear 2000
}


# ── SplashScreen (after window maps) ──────────────────────────────────────────
proc launch_splash {} { show_splash_startup }

proc show_splash_startup {} {
    set ss [ttkbootstrap::SplashScreen \
        -title     "ttkbootstrap" \
        -version   "Widget Showcase" \
        -message   "Loading all widgets..." \
        -bootstyle dark \
        -progress  1 \
        -width     380 -height 210 \
        -parent    .]
    foreach {pct msg} {
        25  "Registering widgets..."
        55  "Building sidebar..."
        85  "Preparing demos..."
        100 "Ready!"
    } {
        ttkbootstrap::SplashScreen::progress $ss $pct $msg
        after 250; update
    }
    after 500
    ttkbootstrap::SplashScreen::close $ss
}

# ── Root layout ────────────────────────────────────────────────────────────────
set ::root [ttk::frame .root]
pack $::root -fill both -expand 1

# ── Sidebar ─────────────────────────────────────────────────────────────────
set ::sb [ttkbootstrap::Sidebar $::root.sb \
    -bootstyle   dark \
    -width       185 \
    -minwidth    50 \
    -collapsible 1 \
    -on-toggle   show_sidebar_badge]
pack $::sb -side left -fill y

# Show the "N widgets" badge only when the sidebar is expanded; when collapsed
# to the icon-only strip there is no room for it, so hide it. Called by the
# Sidebar's -on-toggle callback with 1 (expanded) or 0 (collapsed).
proc show_sidebar_badge {expanded} {
    if {![winfo exists $::sb.countbadge]} return
    if {$expanded} {
        catch { pack $::sb.countbadge -side bottom -pady [ttkbootstrap::_sp 8] }
    } else {
        catch { pack forget $::sb.countbadge }
    }
}

set ::_showing_page 0

# Navigation items
ttkbootstrap::Sidebar::add $::sb overview  "Overview"     -icon dashboard   -command { show_page overview }
ttkbootstrap::Sidebar::separator $::sb
ttkbootstrap::Sidebar::add $::sb buttons   "Buttons"      -icon check       -command { show_page buttons }
ttkbootstrap::Sidebar::add $::sb inputs    "Inputs"       -icon edit        -command { show_page inputs }
ttkbootstrap::Sidebar::add $::sb display   "Display"      -icon chart-bar   -command { show_page display }
ttkbootstrap::Sidebar::add $::sb data      "Data"         -icon table       -command { show_page data }
ttkbootstrap::Sidebar::separator $::sb
ttkbootstrap::Sidebar::add $::sb datetime  "Date & Time"  -icon calendar    -command { show_page datetime }
ttkbootstrap::Sidebar::add $::sb nav       "Navigation"   -icon arrows-right -command { show_page nav }
ttkbootstrap::Sidebar::add $::sb overlays  "Overlays"     -icon bell        -command { show_page overlays }
ttkbootstrap::Sidebar::separator $::sb
ttkbootstrap::Sidebar::add $::sb layout    "Layout"       -icon layers      -command { show_page layout }
ttkbootstrap::Sidebar::add $::sb gallery   "Gallery Apps" -icon star        -command { show_page gallery }
ttkbootstrap::Sidebar::add $::sb splash    "Splash Screen" -icon ripple      -command { launch_splash }
ttkbootstrap::Sidebar::separator $::sb
ttkbootstrap::Sidebar::add $::sb settings  "Settings"     -icon settings    -command { show_page settings }

# Widget counter badge at the bottom of the sidebar
set ::sb_count_frame [ttk::frame $::sb.countbadge]
ttkbootstrap::SVGBadge $::sb.countbadge.badge -text "64 widgets" -bootstyle info
catch { pack $::sb.countbadge.badge -pady [ttkbootstrap::_sp 4] }
catch { pack $::sb.countbadge -side bottom -pady [ttkbootstrap::_sp 8] }

# ── Main area ──────────────────────────────────────────────────────────────────
set ::main [ttk::frame $::root.main]
pack $::main -side left -fill both -expand 1

# Breadcrumb navigation bar
set ::navbar [ttk::frame $::main.navbar -padding [ttkbootstrap::_sp2 12 6]]
pack $::navbar -fill x

set ::bc [ttkbootstrap::Breadcrumb $::navbar.bc \
    -items     {Home} \
    -bootstyle primary \
    -command   {
        set items [ttkbootstrap::Breadcrumb::get $::bc]
        ttkbootstrap::Breadcrumb::load $::bc [lrange $items 0 $idx]
        show_page [lindex $::page_keys $idx]
    }]
pack $::bc -side left

# Theme selector — visible on every page in the top-right of the navbar
ttk::label $::navbar.themelbl -text "Theme:" \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 11]]
ttk::combobox $::navbar.themecb \
    -values [ttkbootstrap::themeNames] \
    -width 14 -state readonly \
    -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                [ttkbootstrap::_sf 11]]
$::navbar.themecb set [ttkbootstrap::currentTheme]
bind $::navbar.themecb <<ComboboxSelected>> {
    ttkbootstrap::setTheme [$::navbar.themecb get]
    ttkbootstrap::StatusBar::msg $::sbbar "Theme: [$::navbar.themecb get]" -clear 2000
    ttkbootstrap::StatusBar::right $::sbbar [$::navbar.themecb get] 0
}
# Leave room on the right for the floating dark-mode toggle (placed at the
# top-right corner) so the two controls never overlap.
pack $::navbar.themecb -side right -padx {4 90}
pack $::navbar.themelbl -side right

set ::page_keys {overview}

ttk::separator $::main.sep1 -orient horizontal
pack $::main.sep1 -fill x

# Page container
set ::pf [ttk::frame $::main.pf]
pack $::pf -fill both -expand 1

# Status bar
set ::sbbar [ttkbootstrap::StatusBar $::main]
ttkbootstrap::StatusBar::msg  $::sbbar "ttkbootstrap Widget Showcase"

    # Dark mode floating toggle — a small container with the switch on top and
    # a caption underneath so its purpose is clear.
    set ::_dm_var [expr {[ttkbootstrap::getColor type] eq "dark"}]
    set ::dmbox [ttk::frame .root.dmbox]
    ttkbootstrap::SVGToggleSwitch $::dmbox.sw \
        -text "" -variable ::_dm_var -bootstyle secondary \
        -command {
            if {$::_dm_var} {
                ttkbootstrap::setTheme darkly
            } else {
                ttkbootstrap::setTheme litera
            }
            set ::_dm_var [expr {[ttkbootstrap::getColor type] eq "dark"}]
            $::dmbox.cap configure -text [expr {$::_dm_var ? "Dark mode" : "Light mode"}]
        }
    ttk::label $::dmbox.cap \
        -text [expr {$::_dm_var ? "Dark mode" : "Light mode"}] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 9]] \
        -anchor center
    pack $::dmbox.sw -anchor center
    pack $::dmbox.cap -anchor center -pady [ttkbootstrap::_sp2 1 0]
    place $::dmbox -relx 1.0 -rely 0.0 -anchor ne \
        -x [ttkbootstrap::_sp -10] -y [ttkbootstrap::_sp 4]
ttkbootstrap::StatusBar::right $::sbbar "litera" 0

# ── Page machinery ─────────────────────────────────────────────────────────────
set ::lmap {
    overview  "Overview"     buttons  "Buttons"
    inputs    "Inputs"       display  "Display"
    data      "Data"         datetime "Date & Time"
    nav       "Navigation"   overlays "Overlays"
    layout    "Layout"       gallery  "Gallery Apps"
    settings  "Settings"
}

proc ttkbootstrap::_showcase_pb_animate {w target} {
    if {![winfo exists $w]} return
    set cur [$w cget -value]
    if {$cur >= $target} return
    $w configure -value [expr {min($cur + 3, $target)}]
    after 20 [list ttkbootstrap::_showcase_pb_animate $w $target]
}

proc ttkbootstrap::_showcase_pb_replay {} {
    # Reset all determinate bars to 0 and re-run animation
    foreach w $::pb_widgets t $::pb_targets {
        if {[winfo exists $w]} {
            $w configure -value 0
            after 50 [list ttkbootstrap::_showcase_pb_animate $w $t]
        }
    }
}


# Keyboard shortcuts for page navigation
set _page_keys {overview buttons inputs display data datetime nav overlays layout settings}
for {set i 0} {$i < [llength $_page_keys]} {incr i} {
    set key [expr {($i + 1) % 10}]
    bind . <Control-Key-$key> [list show_page [lindex $_page_keys $i]]
}
bind . <Control-Key-0> [list show_page settings]
# ── The page engine ────────────────────────────────────────────────────────────
# show_page is the heart of the navigation model. Rather than creating every
# page once and hiding/showing them, the showcase keeps a single page frame
# ($::pf) and REBUILDS it from scratch each time you navigate. This keeps memory
# flat and guarantees each page always reflects the current theme.
#
#   1. A re-entrancy guard ($::_showing_page) prevents overlapping rebuilds if
#      the user clicks quickly.
#   2. Every per-section widget-path counter is reset to 0 so the rebuilt page
#      reuses paths like .gb1/.gb2 instead of leaking .gb3/.gb4 on each visit.
#   3. All existing children of $::pf are destroyed.
#   4. The breadcrumb + sidebar selection are updated, then build_<key> runs.
proc show_page {key} {
    if {$::_showing_page} return
    set ::_showing_page 1
    # Reset every per-page widget index counter so rebuilt pages reuse the
    # same widget paths instead of growing unboundedly (.gb1, .gb2, ...).
    # If you add a new build_ proc that uses [incr ::something_idx], add that
    # counter name to this list or its widgets will accumulate across visits.
    foreach _ctr {
        hdr_idx card_idx rr cb_idx ts_idx fg_idx pb_idx bdg_idx
        slr_idx tt_idx si av_idx chip_idx grad_idx icon_idx pl_idx
        ring_idx sbdg_idx sfg_idx shcd_idx snb_idx sq_idx sslr_idx
        svg_idx svgc_idx svgcd_idx svge_idx svgpbd_idx svgr_idx
        svgts_idx svgtt_idx nav_step svgnav_step
    } {
        set ::$_ctr 0
    }
    foreach w [winfo children $::pf] { destroy $w }

    array set lm $::lmap
    if {$key eq "overview"} {
        ttkbootstrap::Breadcrumb::load $::bc {Home}
        set ::page_keys {overview}
    } else {
        ttkbootstrap::Breadcrumb::load $::bc [list Home $lm($key)]
        set ::page_keys [list overview $key]
    }
    ttkbootstrap::Sidebar::select $::sb $key
    build_$key $::pf
    ttkbootstrap::StatusBar::msg $::sbbar "Viewing: $lm($key)" -clear 3000
    set ::_showing_page 0
}

# ── Helper: section header ─────────────────────────────────────────────────────
# Every group of widgets on a page is introduced by a bold title and an optional
# grey sub-line. Centralising this here keeps the build_ procs readable and the
# typography consistent. Note the use of _sf for font sizes and _sp/_sp2 for
# padding so headers scale on HiDPI like everything else.
proc section_hdr {parent text {sub {}}} {
    ttk::label $parent.h[incr ::hdr_idx] \
        -text $text \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 15] bold]
    pack $parent.h$::hdr_idx -anchor w \
        -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 14 4]
    if {$sub ne {}} {
        ttk::label $parent.hs$::hdr_idx \
            -text $sub \
            -foreground [ttkbootstrap::getColor secondary] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 12]] \
            -justify left
        pack $parent.hs$::hdr_idx -anchor w \
            -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]
    }
}

# Every page's content lives inside a ScrolledFrame so long pages scroll
# vertically. build_ procs call [page_sf $f] and add their widgets to the
# returned interior frame rather than to $f directly.
proc page_sf {f} {
    set sf [ttkbootstrap::ScrolledFrame $f.sf]
    pack $sf -fill both -expand 1
    return [$f.sf.interior]
}

set ::hdr_idx 0
set ::card_idx 0
set ::rr 0

# ═══════════════════════════════════════════════════════════════════════════════
# OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════
proc build_overview {f} {
    set p [page_sf $f]
    set ::card_idx 0

    ttk::label $p.title \
        -text "ttkbootstrap — Widget Showcase" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 18] bold]
    pack $p.title -anchor w \
        -padx [ttkbootstrap::_sp 20] -pady [ttkbootstrap::_sp2 20 4]
    ttk::label $p.sub \
        -text "64 widgets · 18 themes · DPI-aware scaling · Click a section in the sidebar to explore." \
        -foreground [ttkbootstrap::getColor secondary]
    pack $p.sub -anchor w -padx [ttkbootstrap::_sp 20] -pady [ttkbootstrap::_sp2 0 16]

    # Summary cards grid — one per sidebar section
    set grid [ttk::frame $p.grid -padding [ttkbootstrap::_sp 16]]
    pack $grid -fill x

    foreach {key label icon bs desc} {
        buttons   "Buttons"      check      primary  "Styles, states, outline, link"
        inputs    "Inputs"       edit       success  "Entry, Combobox, Scale, Spinbox, ToggleSwitch, AutocompleteEntry, TagEntry"
        display   "Display"      chart-bar  info     "Meter, Floodgauge, Progressbar, Badge, RatingBar, SparkLine"
        data      "Data"         table      warning  "Tableview, EditableTableview, Treeview"
        datetime  "Date & Time"  calendar   danger   "DateEntry, TimePicker, DateRangePicker"
        nav       "Navigation"   arrows-right secondary "Breadcrumb, StepProgress, Notebook, CollapsingFrame"
        overlays  "Overlays"     bell       primary  "Toast, NotificationBanner, ProgressDialog, SplashScreen"
        layout    "Layout"       layers     success  "Card, StatusBar, ScrolledText, Timeline, ScrolledFrame"
        gallery   "Gallery Apps" star       info     "Calculator, Stopwatch, Back Me Up + more"
        settings  "Settings"     settings   secondary "Theme switcher, sidebar options"
    } {
        set c [ttkbootstrap::SVGShadowCard $grid.c[incr ::card_idx] \
            -title     $label \
            -bootstyle $bs \
            -padding   [ttkbootstrap::_sp 10] \
            -width     [ttkbootstrap::_sp 260] \
            -height    [ttkbootstrap::_sp 220] \
            -shadow    10]
        set body [ttkbootstrap::SVGShadowCard::body $grid.c$::card_idx]
        # Pack button first at bottom, then description fills remaining space
        ttkbootstrap::PillButton $body.go \
            -text    "Open →" \
            -bootstyle $bs \
            -outline 1 \
            -command [list show_page $key]
        pack $body.go -side bottom -anchor e
        ttk::label $body.desc \
            -text       $desc \
            -wraplength [ttkbootstrap::_sp 140] \
            -justify    left \
            -foreground [ttkbootstrap::getColor secondary]
        pack $body.desc -fill both -expand 1

        set col [expr {($::card_idx-1) % 3}]
        set row [expr {($::card_idx-1) / 3}]
        grid $grid.c$::card_idx \
            -row $row -column $col \
            -padx [ttkbootstrap::_sp 6] -pady [ttkbootstrap::_sp 6] -sticky nsew
    }
    for {set c 0} {$c < 3} {incr c} { grid columnconfigure $grid $c -weight 1 }

    # Live sparkline strip at bottom
    set srow [ttk::frame $p.srow -padding [ttkbootstrap::_sp 16]]
    pack $srow -fill x
    ttk::label $srow.lbl \
        -text "Live metrics:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    pack $srow.lbl -anchor w -pady [ttkbootstrap::_sp2 0 6]

    set ::overview_sparks {}
    foreach {lbl bs} {CPU primary Memory success Errors danger} {
        set row [ttk::frame $srow.r$lbl -padding [ttkbootstrap::_sp2 0 3]]
        pack $row -fill x
        ttk::label $row.l -text "${lbl}:" -width 10 -anchor w
        set sl [ttkbootstrap::SparkLine $row.sl \
            -data      [list {*}[lmap i [lrepeat 12 0] {expr {int(rand()*70+15)}}]] \
            -bootstyle $bs \
            -width     140 -height 22 -type line]
        ttk::label $row.v \
            -text [lindex [ttkbootstrap::SparkLine::get $row.sl] end] \
            -width 4 -anchor e \
            -foreground [ttkbootstrap::getColor $bs] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 12] bold]
        pack $row.l $sl $row.v -side left -padx [ttkbootstrap::_sp 4]
        lappend ::overview_sparks [list $row.sl $row.v]
    }
    proc _overview_tick {} {
        foreach pair $::overview_sparks {
            lassign $pair sl val_lbl
            if {![winfo exists $sl]} return
            ttkbootstrap::SparkLine::push $sl [expr {int(rand()*70+15)}] -maxpoints 12
            catch { $val_lbl configure \
                -text [lindex [ttkbootstrap::SparkLine::get $sl] end] }
        }
        set ::_overview_after [after 800 _overview_tick]
    }
    after 800 _overview_tick
}

# ═══════════════════════════════════════════════════════════════════════════════
# BUTTONS
# ═══════════════════════════════════════════════════════════════════════════════
proc build_buttons {f} {
    set p [page_sf $f]

    # ══ BUTTONS ═══════════════════════════════════════════════════════════════
    section_hdr $p "Buttons (Original)" \
        "Every bootstyle variant shown in solid, outline, and link modes."

    foreach bs {primary secondary success info warning danger light dark} {
        set row [ttk::frame $p.br$bs -padding [ttkbootstrap::_sp2 16 3]]
        pack $row -fill x
        ttk::label $row.l -text $bs -width 12 -anchor w \
            -foreground [ttkbootstrap::getColor secondary]
        foreach style {"" ".Outline" ".Link"} {
            set lbl [string map {. ""} [string trim $style .]]
            set lbl [expr {$lbl eq "" ? "Solid" : $lbl}]
            ttk::button $row.b$lbl \
                -text    $lbl \
                -style   "${bs}${style}.TButton" \
                -padding [ttkbootstrap::_sp2 10 4] \
                -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                    "Button: $bs $lbl" -clear 2000]
            pack $row.b$lbl -side left -padx [ttkbootstrap::_sp 3]
        }
        set b [ttk::button $row.bdis -text "Disabled" \
            -style "${bs}.TButton" -padding [ttkbootstrap::_sp2 10 4] -state disabled]
        pack $b -side left -padx [ttkbootstrap::_sp 3]
        pack $row.l -side left -before $row.bSolid
    }

    ttk::separator $p.sep_sb -orient horizontal
    pack $p.sep_sb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Square Buttons (SVG \u2014 New)" \
        "SVG-rendered buttons with square corners. Solid and outline."

    set sqbrow [ttk::frame $p.sqbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $sqbrow -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::SVGButton $sqbrow.sb[incr ::svg_idx] \
            -text [string totitle $bs] \
            -bootstyle $bs \
            -radius 0 \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Square SVG: [string totitle $bs]" -clear 2000]
        pack $sqbrow.sb$::svg_idx -side left -padx [ttkbootstrap::_sp 4]
    }
    set sqbrow2 [ttk::frame $p.sqbrow2 -padding [ttkbootstrap::_sp2 16 4]]
    pack $sqbrow2 -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::SVGButton $sqbrow2.sb[incr ::svg_idx] \
            -text "Outline" \
            -bootstyle $bs \
            -outline 1 \
            -radius 0 \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Square outline: $bs" -clear 2000]
        pack $sqbrow2.sb$::svg_idx -side left -padx [ttkbootstrap::_sp 4]
    }

    ttk::separator $p.sep_rndb -orient horizontal
    pack $p.sep_rndb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Rounded Buttons (SVG \u2014 New)" \
        "SVG-rendered buttons with rounded corners. Solid and outline."

    set rndbrow [ttk::frame $p.rndbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $rndbrow -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::SVGButton $rndbrow.sb[incr ::svg_idx] \
            -text [string totitle $bs] \
            -bootstyle $bs \
            -radius [ttkbootstrap::_sp 8] \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Rounded SVG: [string totitle $bs]" -clear 2000]
        pack $rndbrow.sb$::svg_idx -side left -padx [ttkbootstrap::_sp 4]
    }
    set rndbrow2 [ttk::frame $p.rndbrow2 -padding [ttkbootstrap::_sp2 16 4]]
    pack $rndbrow2 -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::SVGButton $rndbrow2.sb[incr ::svg_idx] \
            -text "Outline" \
            -bootstyle $bs \
            -outline 1 \
            -radius [ttkbootstrap::_sp 8] \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Rounded outline: $bs" -clear 2000]
        pack $rndbrow2.sb$::svg_idx -side left -padx [ttkbootstrap::_sp 4]
    }

    ttk::separator $p.sep_pill -orient horizontal
    pack $p.sep_pill -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Pill Buttons (SVG \u2014 New)" \
        "Fully rounded pill-shaped buttons using SVG."

    set plrow [ttk::frame $p.plrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $plrow -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::PillButton $plrow.pb[incr ::pl_idx] \
            -text [string totitle $bs] \
            -bootstyle $bs \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Pill: [string totitle $bs]" -clear 2000]
        pack $plrow.pb$::pl_idx -side left -padx [ttkbootstrap::_sp 4]
    }
    set plrow2 [ttk::frame $p.plrow2 -padding [ttkbootstrap::_sp2 16 4]]
    pack $plrow2 -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::PillButton $plrow2.pb[incr ::pl_idx] \
            -text "Outline" \
            -bootstyle $bs \
            -outline 1 \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Pill outline: $bs" -clear 2000]
        pack $plrow2.pb$::pl_idx -side left -padx [ttkbootstrap::_sp 4]
    }

    # ══ CHECKBUTTONS & RADIOBUTTONS ═══════════════════════════════════════════
    ttk::separator $p.sep_ck -orient horizontal
    pack $p.sep_ck -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Checkbuttons & Radiobuttons (Original)"

    set cbrow [ttk::frame $p.cbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $cbrow -fill x
    foreach {var text bs} {
        ::sc_cb1 "Selected"   primary
        ::sc_cb2 "Deselected" success
        ::sc_cb3 "Disabled"   danger
    } {
        set ::$var [expr {$text eq "Selected" ? 1 : 0}]
        set cb [ttk::checkbutton $cbrow.cb[incr ::cb_idx] \
            -text $text -variable $var -style "$bs.TCheckbutton"]
        if {$text eq "Disabled"} { $cb configure -state disabled }
        pack $cb -side left -padx [ttkbootstrap::_sp 8]
    }

    set rbrow [ttk::frame $p.rbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $rbrow -fill x
    set ::sc_rb 1
    foreach {val text bs} {1 "Option A" primary 2 "Option B" success 3 "Option C" info} {
        ttk::radiobutton $rbrow.rb$val \
            -text $text -variable ::sc_rb -value $val \
            -style "$bs.TRadiobutton"
        pack $rbrow.rb$val -side left -padx [ttkbootstrap::_sp 8]
    }

    ttk::separator $p.sep_svgck -orient horizontal
    pack $p.sep_svgck -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Checkboxes & Radio Buttons (SVG \u2014 New)" \
        "Crisp SVG checkmarks and radio circles."

    set chkrow [ttk::frame $p.chkrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $chkrow -fill x
    foreach {var lbl bs} {
        ::svgchk1 "Primary check"   primary
        ::svgchk2 "Success check"   success
        ::svgchk3 "Danger check"    danger
        ::svgchk4 "Warning check"   warning
    } {
        set ::$var 0
        ttkbootstrap::SVGCheck $chkrow.c[incr ::svgc_idx] \
            -text $lbl -variable $var -bootstyle $bs
        pack $chkrow.c$::svgc_idx -side left -padx [ttkbootstrap::_sp 10]
    }

    set radrow [ttk::frame $p.radrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $radrow -fill x
    set ::svgradio "a"
    foreach {val lbl bs} {a "Option A" primary b "Option B" success c "Option C" info d "Option D" warning} {
        ttkbootstrap::SVGRadio $radrow.r[incr ::svgr_idx] \
            -text $lbl -variable ::svgradio -value $val -bootstyle $bs
        pack $radrow.r$::svgr_idx -side left -padx [ttkbootstrap::_sp 10]
    }

    # ══ TOGGLE SWITCHES ═══════════════════════════════════════════════════════
    ttk::separator $p.sep_ts -orient horizontal
    pack $p.sep_ts -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "ToggleSwitch (Round)" \
        "iOS-style toggle. Uses the Round.TCheckbutton style."

    set tsrow [ttk::frame $p.tsrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $tsrow -fill x
    foreach {var label bs} {
        ::ts1 "Notifications" primary
        ::ts2 "Auto-save"     success
        ::ts3 "Dark mode"     secondary
        ::ts4 "Sounds"        info
    } {
        set ::$var 0
        set ts [ttkbootstrap::ToggleSwitch $tsrow.ts[incr ::ts_idx] \
            -text $label -variable $var -bootstyle $bs \
            -command [list apply {{lbl} {
                ttkbootstrap::StatusBar::msg $::sbbar \
                    "Toggle: $lbl" -clear 2000
            }} $label]]
        pack $ts -side left -padx [ttkbootstrap::_sp 10]
    }

    # ── Square Toggle Switches (between Round and SVG) ──
    ttk::separator $p.sep_sq -orient horizontal
    pack $p.sep_sq -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Square Toggle Switches" \
        "Square variant using the Square.TCheckbutton style."

    set sqrow [ttk::frame $p.sqrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $sqrow -fill x
    foreach {var label bs} {
        ::sq1 "Wi-Fi"     primary
        ::sq2 "Bluetooth" success
        ::sq3 "Location"  warning
        ::sq4 "Airplane"  danger
    } {
        set ::$var 0
        ttk::checkbutton $sqrow.sq[incr ::sq_idx] \
            -text $label -variable $var \
            -style "$bs.Square.TCheckbutton" \
            -command [list apply {{lbl} {
                ttkbootstrap::StatusBar::msg $::sbbar \
                    "Square toggle: $lbl" -clear 2000
            }} $label]
        pack $sqrow.sq$::sq_idx -side left -padx [ttkbootstrap::_sp 10]
    }

    # ── SVG Toggle ──
    ttk::separator $p.sep_svgts -orient horizontal
    pack $p.sep_svgts -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "ToggleSwitch (SVG \u2014 New)" \
        "Animated SVG toggle with smooth sliding thumb."
    set svgtsrow [ttk::frame $p.svgtsrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $svgtsrow -fill x
    set ::svgts_dark 0; set ::svgts_notify 1; set ::svgts_auto 0
    foreach {lbl var bs} {"Dark mode" ::svgts_dark primary "Notifications" ::svgts_notify success "Auto-save" ::svgts_auto info} {
        ttkbootstrap::SVGToggleSwitch $svgtsrow.ts[incr ::svgts_idx] \
            -text $lbl -variable $var -bootstyle $bs \
            -command [list apply {{lbl var sb} {
                set state [expr {[set $var] ? "ON" : "OFF"}]
                ttkbootstrap::StatusBar::msg $sb "SVG Toggle: $lbl $state" -clear 2000
            }} $lbl $var $::sbbar]
        pack $svgtsrow.ts$::svgts_idx -side left -padx [ttkbootstrap::_sp 12]
    }

    # ── Gradient Buttons ──
    ttk::separator $p.sep_grad -orient horizontal
    pack $p.sep_grad -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Gradient Buttons (SVG \u2014 New)" \
        "Buttons with a faked vertical gradient and hover effect."
    set gradrow [ttk::frame $p.gradrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $gradrow -fill x
    foreach bs {primary success info warning danger secondary} {
        ttkbootstrap::SVGGradientButton $gradrow.gb[incr ::grad_idx] \
            -text [string totitle $bs] -bootstyle $bs \
            -command [list ttkbootstrap::StatusBar::msg $::sbbar \
                "Gradient: $bs" -clear 2000]
        pack $gradrow.gb$::grad_idx -side left -padx [ttkbootstrap::_sp 4]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# INPUTS
# ═══════════════════════════════════════════════════════════════════════════════
proc build_inputs {f} {
    set p [page_sf $f]
    section_hdr $p "Entry, Combobox, Spinbox, Scale (Original)" \
        "Standard input widgets with ttkbootstrap styling."

    set rows [ttk::frame $p.rows -padding [ttkbootstrap::_sp 16]]
    pack $rows -fill x

    # Entry
    set r1 [ttk::frame $rows.r1 -padding [ttkbootstrap::_sp2 0 4]]
    pack $r1 -fill x
    ttk::label $r1.l -text "Entry:" -width 14 -anchor w
    ttk::entry $r1.e1 -style "primary.TEntry" -width 20
    $r1.e1 insert 0 "Primary entry"
    ttk::entry $r1.e2 -style "success.TEntry" -width 20
    $r1.e2 insert 0 "Success entry"
    ttk::entry $r1.e3 -style "danger.TEntry" -width 20 -state disabled
    $r1.e3 configure -state normal
    $r1.e3 insert 0 "Disabled"
    $r1.e3 configure -state disabled
    pack $r1.l $r1.e1 $r1.e2 $r1.e3 -side left -padx [ttkbootstrap::_sp 4]

    # Combobox
    set r2 [ttk::frame $rows.r2 -padding [ttkbootstrap::_sp2 0 4]]
    pack $r2 -fill x
    ttk::label $r2.l -text "Combobox:" -width 14 -anchor w
    ttk::combobox $r2.c -values {Option1 Option2 Option3} -state readonly -width 18
    $r2.c set Option1
    pack $r2.l $r2.c -side left -padx [ttkbootstrap::_sp 4]

    # Spinbox
    set r3 [ttk::frame $rows.r3 -padding [ttkbootstrap::_sp2 0 4]]
    pack $r3 -fill x
    ttk::label $r3.l -text "Spinbox:" -width 14 -anchor w
    set ::sc_spin 50
    ttk::spinbox $r3.s -from 0 -to 100 -textvariable ::sc_spin \
        -style "primary.TSpinbox" -width 10
    pack $r3.l $r3.s -side left -padx [ttkbootstrap::_sp 4]

    # Scale
    set r4 [ttk::frame $rows.r4 -padding [ttkbootstrap::_sp2 0 4]]
    pack $r4 -fill x
    ttk::label $r4.l -text "Scale:" -width 14 -anchor w
    set ::sc_scale 60
    trace add variable ::sc_scale write {apply {{args} {
        set ::sc_scale [expr {int($::sc_scale)}]
    }}}
    ttk::scale $r4.sc -from 0 -to 100 -variable ::sc_scale \
        -orient horizontal -length [ttkbootstrap::_sp 200]
    ttk::label $r4.v -textvariable ::sc_scale -width 6 -anchor e
    pack $r4.l -side left -padx [ttkbootstrap::_sp 4]
    pack $r4.v -side right -padx [ttkbootstrap::_sp 8]
    pack $r4.sc -side left -padx [ttkbootstrap::_sp 4] -fill x -expand 1


    ttk::separator $p.sep_ssb -orient horizontal
    pack $p.sep_ssb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Search Bar (SVG \u2014 New)" \
        "SVG pill-shaped search entry with icon and clear button."
    set ssbrow [ttk::frame $p.ssbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $ssbrow -fill x
    # The -command runs on every keystroke and on Enter. Inside it, the special
    # variable $query holds the current text (the widget sets it before calling
    # the command), so the command is written with a LITERAL \$query that the
    # widget substitutes at call time — hence the backslash here.
    ttkbootstrap::SVGSearchBar $ssbrow.sb -bootstyle primary \
        -placeholder "Search widgets..." -width 30 \
        -command [list ttkbootstrap::StatusBar::msg $::sbbar \
            "Search: \$query" -clear 2000]
    pack $ssbrow.sb -anchor w
    # The clear (x) button only appears while the entry has text — standard
    # search-bar behaviour. We pre-populate via ::set so the button is visible
    # in the demo immediately; ::set also triggers the show/hide logic so the
    # button state stays in sync. Click the x to clear and type your own query.
    ttkbootstrap::SVGSearchBar::set $ssbrow.sb "widgets"
    ttk::separator $p.sep_scbx -orient horizontal
    pack $p.sep_scbx -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Combobox (SVG \u2014 New)" \
        "SVG pill-shaped combobox with focus highlight."
    set scbrow [ttk::frame $p.scbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $scbrow -fill x
    ttk::label $scbrow.l -text "Colour:" -width 8 -anchor w
    ttkbootstrap::SVGCombobox $scbrow.cb -values {Red Green Blue Yellow Purple} -bootstyle primary -width 18
    pack $scbrow.l -side left
    pack $scbrow.cb -side left -padx [ttkbootstrap::_sp 8]
    ttk::separator $p.sep_sspb -orient horizontal
    pack $p.sep_sspb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Spinbox (SVG \u2014 New)" \
        "SVG pill-shaped spinbox."
    set ssprow [ttk::frame $p.ssprow -padding [ttkbootstrap::_sp2 16 6]]
    pack $ssprow -fill x
    ttk::label $ssprow.l -text "Qty:" -width 8 -anchor w
    ttkbootstrap::SVGSpinbox $ssprow.sp -from 1 -to 100 -bootstyle primary -width 8
    pack $ssprow.l -side left
    pack $ssprow.sp -side left -padx [ttkbootstrap::_sp 8]
    ttk::separator $p.sep_sff -orient horizontal
    pack $p.sep_sff -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Form Field (SVG \u2014 New)" \
        "SVG entry with label and live validation."
    set sffrow [ttk::frame $p.sffrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $sffrow -fill x
    set ::ff_email ""
    ttkbootstrap::SVGFormField $sffrow.ff \
        -label "Email Address" -bootstyle primary \
        -textvariable ::ff_email -width 30 \
        -validate {regexp {.+@.+\..+} $value} \
        -validmsg "\u2713 Valid email" \
        -invalidmsg "\u2717 Enter a valid email address"
    pack $sffrow.ff -anchor w
    ttk::separator $p.sep_sff2 -orient horizontal
    pack $p.sep_sff2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]

    section_hdr $p "Entry (SVG — New)" \
        "SVG-bordered entry field with focus highlight. Crisp pill-shaped border."

    set svgerow [ttk::frame $p.svgerow -padding [ttkbootstrap::_sp 16]]
    pack $svgerow -fill x
    set ::svge_val ""
    foreach {lbl bs} {Name: primary  Email: success  Search: info} {
        ttk::label $svgerow.l[incr ::svge_idx] -text $lbl -width 8 -anchor w
        ttkbootstrap::SVGEntry $svgerow.e$::svge_idx \
            -bootstyle $bs -textvariable ::svge_val_$::svge_idx -width 18
        pack $svgerow.l$::svge_idx -side left -padx {4 0}
        pack $svgerow.e$::svge_idx -side left -padx {0 12}
    }

    ttk::separator $p.sep_svgp -orient horizontal
    pack $p.sep_svgp -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Progress Bar (SVG — New)" \
        "SVG-rendered progress bar with rounded track and coloured fill."

    set svgprow [ttk::frame $p.svgprow -padding [ttkbootstrap::_sp 16]]
    pack $svgprow -fill x
    set ::svgprog 65
    ttkbootstrap::SVGProgress $svgprow.pb \
        -bootstyle success -variable ::svgprog -maximum 100 \
        -length [ttkbootstrap::_sp 400] -height [ttkbootstrap::_sp 18]
    pack $svgprow.pb -fill x -expand 1

    ttk::separator $p.sep_svgsc -orient horizontal
    pack $p.sep_svgsc -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Scale / Slider (SVG — New)" \
        "SVG-rendered slider with rounded track and circle thumb."

    set svgscrow [ttk::frame $p.svgscrow -padding [ttkbootstrap::_sp 16]]
    pack $svgscrow -fill x
    set ::svgscale 65
    ttkbootstrap::SVGScale $svgscrow.sc \
        -from 0 -to 100 -bootstyle info -variable ::svgscale \
        -length [ttkbootstrap::_sp 400] -height [ttkbootstrap::_sp 30] \
        -command [list apply {{val} { set ::svgprog [expr {int($val)}] }}]
    ttk::label $svgscrow.val -textvariable ::svgscale -width 4
    pack $svgscrow.sc -side left -fill x -expand 1
    pack $svgscrow.val -side left -padx [ttkbootstrap::_sp 8]

    ttk::separator $p.sep1 -orient horizontal
    pack $p.sep1 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "AutocompleteEntry" \
        "Entry with live-filtered dropdown. Start typing to see suggestions."

    set ::ac_val {}
    set acrow [ttk::frame $p.acrow -padding [ttkbootstrap::_sp 16]]
    pack $acrow -fill x
    ttk::label $acrow.l -text "Fruit:" -anchor w
    ttkbootstrap::AutocompleteEntry $acrow.ac \
        -values      {Apple Apricot Avocado Banana Blackberry Blueberry Cherry
                      Coconut Fig Grape Grapefruit Guava Kiwi Lemon Lime Mango
                      Nectarine Orange Papaya Peach Pear Pineapple Plum
                      Raspberry Strawberry Watermelon} \
        -textvariable ::ac_val \
        -bootstyle    primary \
        -width        24 \
        -command      { ttkbootstrap::StatusBar::msg $::sbbar \
                            "Selected: $::ac_val" -clear 2000 }
    ttk::label $acrow.hint -text "(type 'a', 'b', etc.)" \
        -foreground [ttkbootstrap::getColor secondary]
    pack $acrow.l $acrow.ac $acrow.hint -side left -padx [ttkbootstrap::_sp 6]

    ttk::separator $p.sep2 -orient horizontal
    pack $p.sep2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "TagEntry" \
        "Convert typed text into removable pill tags. Press comma or Enter."

    set terow [ttk::frame $p.terow -padding [ttkbootstrap::_sp 16]]
    pack $terow -fill x
    ttkbootstrap::TagEntry $terow.te \
        -tags      {Python Tcl Go} \
        -bootstyle primary \
        -command   {
            catch {
                ttkbootstrap::StatusBar::msg $::sbbar                     "Tags: [join [ttkbootstrap::TagEntry::_dispatch $::inputs_te get] {, }]"                     -clear 2000
            }
        }
    set ::inputs_te $terow.te
    pack $terow.te -fill x
    set te_presets [ttk::frame $terow.presets -padding [ttkbootstrap::_sp2 0 4]]
    pack $te_presets -fill x
    ttk::label $te_presets.l -text "Add:" \
        -foreground [ttkbootstrap::getColor secondary]
    pack $te_presets.l -side left
    foreach preset {Rust Swift Ruby Kotlin} {
        ttk::button $te_presets.b$preset \
            -text    $preset \
            -style   "secondary.Outline.TButton" \
            -padding [ttkbootstrap::_sp2 6 2] \
            -command [list ttkbootstrap::TagEntry::_dispatch $terow.te add $preset]
        pack $te_presets.b$preset -side left -padx [ttkbootstrap::_sp 2]
    }

    # ══ CHIP (moved to end, with a clearer demo) ══════════════════════════════
    ttk::separator $p.sep_chip -orient horizontal
    pack $p.sep_chip -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Chip (SVG \u2014 New)" \
        "Compact, removable tags \u2014 e.g. active filters or selected items. Click a chip's \u00d7 to remove it."

    set chipwrap [ttk::frame $p.chipwrap -padding [ttkbootstrap::_sp2 16 6]]
    pack $chipwrap -fill x

    ttk::label $chipwrap.caption -text "Active filters:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 11]]
    pack $chipwrap.caption -anchor w -pady [ttkbootstrap::_sp2 0 6]

    set chiprow [ttk::frame $chipwrap.row]
    pack $chiprow -anchor w -fill x

    # Each chip represents a filter the user can remove by clicking its ×.
    # Removing one actually destroys the chip so the demo is self-explanatory.
    foreach {txt bs} {"In Stock" success "Under \$50" primary "Free Shipping" info "4+ Stars" warning "On Sale" danger} {
        set cid $chiprow.ch[incr ::chip_idx]
        ttkbootstrap::SVGChip $cid \
            -text $txt -bootstyle $bs -closeable 1 \
            -command [list apply {{w txt} {
                catch { destroy $w }
                ttkbootstrap::StatusBar::msg $::sbbar "Filter removed: $txt" -clear 2000
            }} $cid $txt]
        pack $cid -side left -padx [ttkbootstrap::_sp 4] -pady [ttkbootstrap::_sp 2]
    }

    ttk::label $chipwrap.hint -text "Tip: click the \u00d7 on any chip to remove that filter." \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 9]] \
        -foreground [ttkbootstrap::getColor secondary]
    pack $chipwrap.hint -anchor w -pady [ttkbootstrap::_sp2 8 0]
}

# ═══════════════════════════════════════════════════════════════════════════════
# DISPLAY
# ═══════════════════════════════════════════════════════════════════════════════
proc build_display {f} {
    set p [page_sf $f]

    # ══ METER ═════════════════════════════════════════════════════════════════
    section_hdr $p "Meter (Original)" \
        "Original canvas-drawn circular arc gauge."

    set mrow [ttk::frame $p.mrow -padding [ttkbootstrap::_sp 16]]
    pack $mrow -fill x
    foreach {val label bs} {74 "CPU" primary  61 "Mem" info  88 "Disk" warning  42 "Net" success} {
        set ::mv_$label $val
        ttkbootstrap::Meter $mrow.m$label \
            -metersize   [ttkbootstrap::_sp 130] \
            -amountused  $val \
            -amounttotal 100 \
            -subtext     $label \
            -bootstyle   $bs \
            -interactive 1
        pack $mrow.m$label -side left -padx [ttkbootstrap::_sp 8]
    }

    ttk::separator $p.sep_m2 -orient horizontal
    pack $p.sep_m2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Meter (SVG \u2014 New)" \
        "SVG-rendered circular gauge \u2014 crisp at any size and DPI."

    set mrow2 [ttk::frame $p.mrow2 -padding [ttkbootstrap::_sp 16]]
    pack $mrow2 -fill x
    foreach {val label bs} {74 "CPU" primary  61 "Mem" info  88 "Disk" warning  42 "Net" success} {
        ttkbootstrap::SVGMeter $mrow2.sm$label \
            -metersize   [ttkbootstrap::_sp 130] \
            -amountused  $val \
            -amounttotal 100 \
            -subtext     $label \
            -textright   "%" \
            -bootstyle   $bs \
            -interactive 1
        pack $mrow2.sm$label -side left -padx [ttkbootstrap::_sp 8]
    }

    # ══ FLOODGAUGE ════════════════════════════════════════════════════════════
    ttk::separator $p.sep_fg -orient horizontal
    pack $p.sep_fg -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Floodgauge (Original)" \
        "Progressbar with text overlay. Good for showing a single primary metric."

    set frow [ttk::frame $p.frow -padding [ttkbootstrap::_sp 16]]
    pack $frow -fill x
    foreach {val bs orient} {65 primary horizontal  40 success horizontal  80 danger horizontal} {
        set fg [ttkbootstrap::Floodgauge $frow.fg[incr ::fg_idx] \
            -bootstyle  $bs \
            -orient     $orient \
            -value      $val \
            -maximum    100 \
            -text       "$val%" \
            -font       [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                              [ttkbootstrap::_sf 12] bold]]
        pack $fg -anchor w -pady [ttkbootstrap::_sp 4]
    }

    ttk::separator $p.sep_fgs -orient horizontal
    pack $p.sep_fgs -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Floodgauge (SVG \u2014 New)" \
        "SVG-rendered flood gauge \u2014 same size, crisp at any DPI."

    set sfrow [ttk::frame $p.sfrow -padding [ttkbootstrap::_sp 16]]
    pack $sfrow -fill x
    foreach {val bs} {65 primary  40 success  80 danger} {
        ttkbootstrap::SVGFloodgauge $sfrow.sfg[incr ::sfg_idx] \
            -bootstyle $bs -value $val -maximum 100 \
            -text "$val%" -width [ttkbootstrap::_sp 300] -height [ttkbootstrap::_sp 40] -radius [ttkbootstrap::_sp 8]
        pack $sfrow.sfg$::sfg_idx -anchor w -pady [ttkbootstrap::_sp 4]
    }

    # ══ PROGRESSBAR ═══════════════════════════════════════════════════════════
    ttk::separator $p.sep_pb -orient horizontal
    pack $p.sep_pb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    # Progressbar header row with Replay button
    set pb_hdr [ttk::frame $p.pbhdr -padding [ttkbootstrap::_sp2 16 4]]
    pack $pb_hdr -fill x

    ttk::label $pb_hdr.title -text "Progressbar (Original)" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    ttk::label $pb_hdr.sub -text "Determinate and indeterminate modes." \
        -foreground [ttkbootstrap::getColor secondary]
    ttk::button $pb_hdr.replay -text "\u21ba Replay" \
        -style "primary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 8 2] \
        -command { ttkbootstrap::_showcase_pb_replay }
    pack $pb_hdr.title  -side left
    pack $pb_hdr.sub    -side left -padx [ttkbootstrap::_sp 12]
    pack $pb_hdr.replay -side right -padx [ttkbootstrap::_sp 16]

    set prow [ttk::frame $p.prow -padding [ttkbootstrap::_sp2 16 4]]
    pack $prow -fill x

    set ::pb_widgets {}
    set ::pb_targets {}
    foreach {lbl val bs mode} {
        "Determinate 72%"    72 primary   determinate
        "Indeterminate"       0 success   indeterminate
        "Determinate 45%"    45 warning   determinate
    } {
        set row [ttk::frame $prow.r[incr ::pb_idx] -padding [ttkbootstrap::_sp2 0 2]]
        ttk::label $row.l -text $lbl -width 20 -anchor w \
            -foreground [ttkbootstrap::getColor secondary]
        set pb [ttk::progressbar $row.pb \
            -orient  horizontal \
            -value   0 \
            -maximum 100 \
            -mode    $mode \
            -style   "$bs.Horizontal.TProgressbar" \
            -length  [ttkbootstrap::_sp 260]]
        pack $row.l  -side left
        pack $row.pb -side left -padx [ttkbootstrap::_sp 8]
        pack $row    -fill x

        if {$mode eq "indeterminate"} {
            $row.pb start 15
        } else {
            lappend ::pb_widgets $row.pb
            lappend ::pb_targets $val
            after 100 [list ttkbootstrap::_showcase_pb_animate $row.pb $val]
        }
    }

    ttk::separator $p.sep_pbs -orient horizontal
    pack $p.sep_pbs -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    # SVG Progressbar header with Replay button
    set svgpb_hdr [ttk::frame $p.svgpbhdr -padding [ttkbootstrap::_sp2 16 4]]
    pack $svgpb_hdr -fill x
    ttk::label $svgpb_hdr.title -text "Progressbar (SVG \u2014 New)" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    ttk::label $svgpb_hdr.sub -text "Determinate and indeterminate modes." \
        -foreground [ttkbootstrap::getColor secondary]
    ttk::button $svgpb_hdr.replay -text "\u21ba Replay" \
        -style "primary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 8 2] \
        -command { _svgpb_replay }
    pack $svgpb_hdr.title  -side left
    pack $svgpb_hdr.sub    -side left -padx [ttkbootstrap::_sp 12]
    pack $svgpb_hdr.replay -side right -padx [ttkbootstrap::_sp 16]

    set svgpbrow [ttk::frame $p.svgpbrow -padding [ttkbootstrap::_sp2 16 4]]
    pack $svgpbrow -fill x

    set ::svgpb_widgets {}
    set ::svgpb_targets {}
    foreach {lbl val bs mode} {
        "Determinate 72%"    72 primary   determinate
        "Indeterminate"       0 success   indeterminate
        "Determinate 45%"    45 warning   determinate
    } {
        set row [ttk::frame $svgpbrow.r[incr ::svgpbd_idx] -padding [ttkbootstrap::_sp2 0 2]]
        ttk::label $row.l -text $lbl -width 20 -anchor w \
            -foreground [ttkbootstrap::getColor secondary]

        if {$mode eq "indeterminate"} {
            # Indeterminate: animate a bouncing fill
            set ::svgpb_ind_var_$::svgpbd_idx 0
            ttkbootstrap::SVGProgress $row.pb \
                -bootstyle $bs -value 0 \
                -maximum 100 -length [ttkbootstrap::_sp 260] -height [ttkbootstrap::_sp 16]
            lappend ::svgpb_widgets [list $row.pb indeterminate $::svgpbd_idx]
        } else {
            ttkbootstrap::SVGProgress $row.pb \
                -bootstyle $bs -value 0 \
                -maximum 100 -length [ttkbootstrap::_sp 260] -height [ttkbootstrap::_sp 16]
            lappend ::svgpb_widgets [list $row.pb determinate $::svgpbd_idx]
            lappend ::svgpb_targets $val
            after 100 [list _svgpb_animate $row.pb $val]
        }
        pack $row.l -side left
        pack $row.pb -side left -padx [ttkbootstrap::_sp 8]
        pack $row -fill x
    }

    # Animate determinate SVG progress bars
    proc _svgpb_animate {w target} {
        if {![winfo exists $w]} return
        set ns ::ttkbootstrap::svgpb::$w
        if {![info exists ${ns}::o]} return
        array set o [set ${ns}::o]
        set cur $o(-value)
        if {$cur < $target} {
            incr cur 2
            if {$cur > $target} { set cur $target }
            set o(-value) $cur
            set ${ns}::o [array get o]
            ttkbootstrap::_svgpb_redraw $w
            after 30 [list _svgpb_animate $w $target]
        }
    }

    # Indeterminate animation — sliding box that bounces back and forth
    proc _svgpb_ind_tick {} {
        foreach item $::svgpb_widgets {
            lassign $item w mode idx
            if {$mode ne "indeterminate"} continue
            if {![winfo exists $w]} return
            set ns ::ttkbootstrap::svgpb::$w
            if {![info exists ${ns}::o]} return
            array set o [set ${ns}::o]
            set posvar ::svgpb_ind_pos_$idx
            set dirvar ::svgpb_ind_dir_$idx
            if {![info exists $posvar]} { set $posvar 0 }
            if {![info exists $dirvar]} { set $dirvar 1 }
            set pos [set $posvar]
            set dir [set $dirvar]
            # Move position
            set pos [expr {$pos + $dir * 1}]
            if {$pos >= 90} { set dir -1; set pos 90 }
            if {$pos <= 0}  { set dir 1;  set pos 0 }
            set $posvar $pos
            set $dirvar $dir
            # 10% wide sliding box at current position
            set o(-value) 10
            set o(-offset) $pos
            set ${ns}::o [array get o]
            ttkbootstrap::_svgpb_redraw $w
        }
        after 60 _svgpb_ind_tick
    }
    after 100 _svgpb_ind_tick

    # Replay: reset and re-animate all SVG progress bars
    proc _svgpb_replay {} {
        set tidx 0
        foreach item $::svgpb_widgets {
            lassign $item w mode idx
            if {![winfo exists $w]} continue
            set ns ::ttkbootstrap::svgpb::$w
            if {![info exists ${ns}::o]} continue
            array set o [set ${ns}::o]
            set o(-value) 0
            set ${ns}::o [array get o]
            ttkbootstrap::_svgpb_redraw $w
            if {$mode eq "determinate"} {
                set target [lindex $::svgpb_targets $tidx]
                after 100 [list _svgpb_animate $w $target]
                incr tidx
            }
        }
    }

    # ══ BADGE & RATINGBAR & SPARKLINE ═════════════════════════════════════════
    ttk::separator $p.sep_brs -orient horizontal
    pack $p.sep_brs -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Badge  &  RatingBar  &  SparkLine (Original)"

    set brow [ttk::frame $p.brow -padding [ttkbootstrap::_sp 16]]
    pack $brow -fill x
    ttk::label $brow.bl -text "Badges:" -width 12 -anchor w
    foreach {text bs} {New primary  42 danger  Beta info  Draft secondary} {
        pack [ttkbootstrap::Badge $brow.b[incr ::bdg_idx] \
            -text $text -bootstyle $bs] -side left -padx [ttkbootstrap::_sp 4]
    }
    pack $brow.bl -side left -before $brow.b1

    set rbframe [ttk::frame $p.rbframe -padding [ttkbootstrap::_sp 16]]
    pack $rbframe -fill x

    set row1 [ttk::frame $rbframe.r1 -padding [ttkbootstrap::_sp2 0 4]]
    pack $row1 -fill x
    ttk::label $row1.l -text "RatingBar:" -width 12 -anchor w
    set ::disp_rv 4
    ttkbootstrap::RatingBar $row1.rb -variable ::disp_rv -maximum 5 -bootstyle warning \
        -command { ttkbootstrap::StatusBar::msg $::sbbar "Rating: $::disp_rv stars" -clear 2000 }
    ttk::label $row1.v -textvariable ::disp_rv -width 3 -anchor e \
        -foreground [ttkbootstrap::getColor warning] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    ttk::label $row1.mode -text "Interactive" \
        -foreground [ttkbootstrap::getColor secondary] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10]]
    pack $row1.l $row1.rb $row1.v $row1.mode -side left -padx [ttkbootstrap::_sp 6]

    set row2 [ttk::frame $rbframe.r2 -padding [ttkbootstrap::_sp2 0 4]]
    pack $row2 -fill x
    ttk::label $row2.l -text "" -width 12 -anchor w
    ttkbootstrap::RatingBar $row2.rb -value 3.5 -maximum 5 -bootstyle warning -readonly 1
    ttk::label $row2.v -text "3.5" -width 3 -anchor e \
        -foreground [ttkbootstrap::getColor warning] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    ttk::label $row2.mode -text "Read-only" \
        -foreground [ttkbootstrap::getColor secondary] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10]]
    pack $row2.l $row2.rb $row2.v $row2.mode -side left -padx [ttkbootstrap::_sp 6]

    set slframe [ttk::frame $p.slframe -padding [ttkbootstrap::_sp 16]]
    pack $slframe -fill x

    ttk::label $slframe.lbl -text "SparkLine:" -width 12 -anchor w
    pack $slframe.lbl -anchor w -pady [ttkbootstrap::_sp2 0 4]

    set ::disp_sl_widgets {}
    foreach {lbl bs type} {
        "Network"  primary  line
        "Storage"  success  bar
        "CPU Load" danger   line
    } {
        set row [ttk::frame $slframe.r[incr ::slr_idx] -padding [ttkbootstrap::_sp2 0 3]]
        pack $row -fill x
        ttk::label $row.l -text "${lbl}:" -width 12 -anchor w
        set sl [ttkbootstrap::SparkLine $row.sl \
            -data      [list {*}[lmap i [lrepeat 12 0] {expr {int(rand()*70+15)}}]] \
            -bootstyle $bs -type $type -width 140 -height 22]
        ttk::label $row.v \
            -text [lindex [ttkbootstrap::SparkLine::get $row.sl] end] \
            -width 4 -anchor e \
            -foreground [ttkbootstrap::getColor $bs] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 12] bold]
        pack $row.l $sl $row.v -side left -padx [ttkbootstrap::_sp 4]
        lappend ::disp_sl_widgets [list $sl $row.v]
    }

    proc _disp_sl_tick {} {
        foreach pair $::disp_sl_widgets {
            lassign $pair sl val_lbl
            if {![winfo exists $sl]} return
            ttkbootstrap::SparkLine::push $sl [expr {int(rand()*70+15)}] -maxpoints 12
            catch { $val_lbl configure \
                -text [lindex [ttkbootstrap::SparkLine::get $sl] end] }
        }
        after 700 _disp_sl_tick
    }
    after 700 _disp_sl_tick

    # ── SVG versions ──────────────────────────────────────────────────────────
    ttk::separator $p.sep_skel -orient horizontal
    pack $p.sep_skel -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Skeleton Loader (SVG \u2014 New)" \
        "Colourful animated shimmer placeholders for loading states."
    set skelrow [ttk::frame $p.skelrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $skelrow -fill x
    ttkbootstrap::SVGSkeleton $skelrow.sk1 -width [ttkbootstrap::_sp 220] -lines 3 -bootstyle primary
    ttkbootstrap::SVGSkeleton $skelrow.sk2 -width [ttkbootstrap::_sp 220] -shape card -bootstyle success
    ttkbootstrap::SVGSkeleton $skelrow.sk3 -width [ttkbootstrap::_sp 220] -lines 3 -bootstyle info
    pack $skelrow.sk1 -side left -padx [ttkbootstrap::_sp 6]
    pack $skelrow.sk2 -side left -padx [ttkbootstrap::_sp 6]
    pack $skelrow.sk3 -side left -padx [ttkbootstrap::_sp 6]
    ttkbootstrap::SVGSkeleton::start $skelrow.sk1
    ttkbootstrap::SVGSkeleton::start $skelrow.sk2
    ttkbootstrap::SVGSkeleton::start $skelrow.sk3

    ttk::separator $p.sep_avatar -orient horizontal
    pack $p.sep_avatar -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Avatar (SVG \u2014 New)" \
        "Circular avatar with initials."
    set avrow [ttk::frame $p.avrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $avrow -fill x
    foreach {initials bs sz} {JD primary 48 AB success 40 XY danger 56 MK warning 44 TS info 48} {
        ttkbootstrap::SVGAvatar $avrow.av[incr ::av_idx] \
            -text $initials -bootstyle $bs -size [ttkbootstrap::_sp $sz]
        pack $avrow.av$::av_idx -side left -padx [ttkbootstrap::_sp 6]
    }

    ttk::separator $p.sep_ring -orient horizontal
    pack $p.sep_ring -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Progress Ring (SVG \u2014 New)" \
        "Circular progress indicator and loading spinner."

    set ::ring_widgets {}
    set ringrow [ttk::frame $p.ringrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $ringrow -fill x
    foreach {bs val} {primary 25 success 50 warning 75 danger 100} {
        ttkbootstrap::SVGProgressRing $ringrow.pr[incr ::ring_idx] \
            -bootstyle $bs -value 0 -size [ttkbootstrap::_sp 44]
        pack $ringrow.pr$::ring_idx -side left -padx [ttkbootstrap::_sp 8]
        lappend ::ring_widgets [list $ringrow.pr$::ring_idx $val]
    }
    # Spinning ring
    set spinner [ttkbootstrap::SVGProgressRing $ringrow.spin \
        -bootstyle info -size [ttkbootstrap::_sp 44]]
    ttkbootstrap::SVGProgressRing_spin $spinner
    ttk::label $ringrow.spinlbl -text "Loading..."
    pack $spinner -side left -padx [ttkbootstrap::_sp 8]
    pack $ringrow.spinlbl -side left -padx [ttkbootstrap::_sp2 4 0]
    ttk::button $ringrow.replay -text "\u21bb Replay" \
        -style "primary.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 8 2] \
        -command {
            foreach item $::ring_widgets {
                lassign $item w target
                ttkbootstrap::SVGProgressRing_set $w 0
            }
            after 200 {ttkbootstrap::_ring_animate 0}
        }
    pack $ringrow.replay -side left -padx [ttkbootstrap::_sp 12]

    section_hdr $p "Badge (SVG \u2014 New)" \
        "SVG pill badges \u2014 crisp at any size."

    set sbrow [ttk::frame $p.sbrow -padding [ttkbootstrap::_sp 16]]
    pack $sbrow -fill x
    ttk::label $sbrow.bl -text "SVG Badges:" -width 14 -anchor w
    pack $sbrow.bl -side left
    foreach {text bs} {New primary  42 danger  Beta info  Draft secondary  Hot warning} {
        ttkbootstrap::SVGBadge $sbrow.sb[incr ::sbdg_idx] \
            -text $text -bootstyle $bs
        pack $sbrow.sb$::sbdg_idx -side left -padx [ttkbootstrap::_sp 4]
    }

    ttk::separator $p.sep_svgr -orient horizontal
    pack $p.sep_svgr -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "RatingBar (SVG \u2014 New)" \
        "SVG star ratings \u2014 interactive and read-only."

    set srrow [ttk::frame $p.srrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $srrow -fill x
    ttk::label $srrow.l -text "Interactive:" -width 14 -anchor w
    set ::svgrating 4
    ttkbootstrap::SVGRatingBar $srrow.rb \
        -variable ::svgrating -maximum 5 -bootstyle warning -size [ttkbootstrap::_sp 28] \
        -command { ttkbootstrap::StatusBar::msg $::sbbar \
            "SVG Rating: $::svgrating stars" -clear 2000 }
    ttk::label $srrow.v -textvariable ::svgrating -width 3 -anchor e \
        -foreground [ttkbootstrap::getColor warning] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    ttk::label $srrow.mode -text "Interactive" \
        -foreground [ttkbootstrap::getColor secondary]
    pack $srrow.l $srrow.rb $srrow.v $srrow.mode -side left -padx [ttkbootstrap::_sp 4]

    set srrow2 [ttk::frame $p.srrow2 -padding [ttkbootstrap::_sp2 16 4]]
    pack $srrow2 -fill x
    ttk::label $srrow2.l -text "Read-only:" -width 14 -anchor w
    ttkbootstrap::SVGRatingBar $srrow2.rb \
        -value 3 -maximum 5 -bootstyle warning -size [ttkbootstrap::_sp 28] -readonly 1
    ttk::label $srrow2.v -text "3" -width 3 -anchor e \
        -foreground [ttkbootstrap::getColor warning] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    ttk::label $srrow2.mode -text "Read-only" \
        -foreground [ttkbootstrap::getColor secondary]
    pack $srrow2.l $srrow2.rb $srrow2.v $srrow2.mode -side left -padx [ttkbootstrap::_sp 4]

    ttk::separator $p.sep_svgs -orient horizontal
    pack $p.sep_svgs -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "SparkLine (SVG \u2014 New)" \
        "SVG mini charts \u2014 line and bar types with live data."

    set sslf [ttk::frame $p.sslf -padding [ttkbootstrap::_sp2 16 6]]
    pack $sslf -fill x
    ttk::label $sslf.lbl -text "SVG SparkLine:" -width 14 -anchor w
    pack $sslf.lbl -anchor w -pady [ttkbootstrap::_sp2 0 4]

    set ::svgsl_widgets {}
    foreach {lbl bs type} {
        "Network"  primary  line
        "Storage"  success  bar
        "CPU Load" danger   line
    } {
        set row [ttk::frame $sslf.r[incr ::sslr_idx] -padding [ttkbootstrap::_sp2 0 3]]
        pack $row -fill x
        ttk::label $row.l -text "${lbl}:" -width 14 -anchor w
        set data [list]
        for {set i 0} {$i < 12} {incr i} { lappend data [expr {int(rand()*70+15)}] }
        ttkbootstrap::SVGSparkLine $row.sl \
            -data $data -bootstyle $bs -type $type \
            -width [ttkbootstrap::_sp 140] -height [ttkbootstrap::_sp 24]
        ttk::label $row.v -text [lindex $data end] -width 4 -anchor e \
            -foreground [ttkbootstrap::getColor $bs] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 12] bold]
        pack $row.l $row.sl $row.v -side left -padx [ttkbootstrap::_sp 4]
        lappend ::svgsl_widgets [list $row.sl $row.v]
    }

    proc _svgsl_tick {} {
        foreach pair $::svgsl_widgets {
            lassign $pair sl vlbl
            if {![winfo exists $sl]} return
            set v [expr {int(rand()*70+15)}]
            ttkbootstrap::SVGSparkLine_push $sl $v 12
            catch { $vlbl configure -text $v }
        }
        after 700 _svgsl_tick
    }
    after 700 _svgsl_tick
}

# ═══════════════════════════════════════════════════════════════════════════════
# DATA
# ═══════════════════════════════════════════════════════════════════════════════
proc build_data {f} {
    set p [page_sf $f]
    section_hdr $p "Tableview" \
        "Themed Treeview with search, sortable headers, and striped rows."

    set tv [ttkbootstrap::Tableview $p.tv \
        -coldata [list \
            [list text "Widget"      stretch 1] \
            [list text "Category"    stretch 0 width [ttkbootstrap::_sp 120]] \
            [list text "Version"     stretch 0 width [ttkbootstrap::_sp 80]] \
            [list text "Status"      stretch 0 width [ttkbootstrap::_sp 100]]] \
        -rowdata {
            {Meter       Display  1.5.0  Stable}
            {Floodgauge  Display  1.5.0  Stable}
            {DateEntry   Input    1.4.0  Stable}
            {TimePicker  Input    1.5.0  New}
            {Sidebar     Layout   1.5.0  New}
            {Card        Layout   1.5.0  New}
            {Badge       Display  1.5.0  New}
            {Timeline    Layout   1.5.0  New}
            {SparkLine   Display  1.5.0  New}
            {RatingBar   Display  1.5.0  New}
            {Breadcrumb  Nav      1.5.0  New}
            {StepProgress Nav     1.5.0  New}
        } \
        -bootstyle   primary \
        -searchable  1 \
        -stripecolor [expr {[ttkbootstrap::getColor type] eq "dark" \
            ? [ttkbootstrap::_lighten [ttkbootstrap::getColor bg] 8] \
            : [ttkbootstrap::getColor light]}]]
    pack $tv -fill both -expand 1 \
        -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    ttk::separator $p.sep -orient horizontal
    pack $p.sep -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]
    section_hdr $p "EditableTableview" \
        "Double-click any cell to edit it in-place."

    set etv [ttkbootstrap::EditableTableview $p.etv \
        -coldata [list \
            [list text "Name"       stretch 1] \
            [list text "Role"       stretch 0 width [ttkbootstrap::_sp 130]] \
            [list text "Department" stretch 0 width [ttkbootstrap::_sp 140]] \
            [list text "Status"     stretch 0 width [ttkbootstrap::_sp 100]]] \
        -rowdata {
            {Alice    Admin   Engineering Active}
            {Bob      Editor  Marketing   Active}
            {Carol    User    Engineering Inactive}
            {Dave     Manager Sales       Active}
        } \
        -bootstyle primary \
        -editcommand {
            ttkbootstrap::StatusBar::msg $::sbbar "Cell edited" -clear 2000
        }]
    pack $etv -fill both -expand 1 \
        -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]
}

# ═══════════════════════════════════════════════════════════════════════════════
# DATE & TIME
# ═══════════════════════════════════════════════════════════════════════════════
proc build_datetime {f} {
    set p [page_sf $f]
    section_hdr $p "DateEntry (Original)" \
        "Click the calendar button to open the date picker popup."

    set ::dt_date [clock format [clock seconds] -format %Y-%m-%d]
    set derow [ttk::frame $p.derow -padding [ttkbootstrap::_sp 16]]
    pack $derow -fill x
    ttk::label $derow.l -text "Date:" -width 10 -anchor w
    ttkbootstrap::DateEntry $derow.de \
        -bootstyle    primary \
        -textvariable ::dt_date \
        -command      { ttkbootstrap::StatusBar::msg $::sbbar \
                            "Date: $::dt_date" -clear 2000 }
    ttk::label $derow.v -textvariable ::dt_date \
        -foreground [ttkbootstrap::getColor primary] \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 12] bold]
    pack $derow.l $derow.de $derow.v -side left -padx [ttkbootstrap::_sp 6]

    ttk::separator $p.sep_svgde -orient horizontal
    pack $p.sep_svgde -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "DateEntry (SVG \u2014 New)" \
        "SVG calendar icon and popup with SVG day highlights."

    set svgderow [ttk::frame $p.svgderow -padding [ttkbootstrap::_sp2 16 6]]
    pack $svgderow -fill x
    set ::svgde_date ""
    ttk::label $svgderow.l -text "Select date:" -width 12 -anchor w
    ttkbootstrap::SVGDateEntry $svgderow.de \
        -bootstyle primary -textvariable ::svgde_date
    pack $svgderow.l -side left
    pack $svgderow.de -side left -padx [ttkbootstrap::_sp 8]


    ttk::separator $p.sep1 -orient horizontal
    pack $p.sep1 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "TimePicker (Original)" \
        "Three modes: 24-hour, 12-hour AM/PM, and with seconds."

    set ::dt_time24 {}; set ::dt_time12 {}; set ::dt_times {}
    set tprows [ttk::frame $p.tprows -padding [ttkbootstrap::_sp 16]]
    pack $tprows -fill x

    foreach {var fmt label bs secs ampm} {
        ::dt_time24  {%H:%M}    "24-hour"       primary  0 0
        ::dt_time12  {%I:%M %p} "12-hour AM/PM" success  0 1
        ::dt_times   {%H:%M:%S} "With seconds"  warning  1 0
    } {
        set row [ttk::frame $tprows.r$label -padding [ttkbootstrap::_sp2 0 6]]
        pack $row -fill x
        ttk::label $row.l -text $label -width 16 -anchor w \
            -foreground [ttkbootstrap::getColor secondary]
        ttkbootstrap::TimePicker $row.tp \
            -bootstyle $bs -textvariable $var \
            -timeformat $fmt -seconds $secs -ampm $ampm \
            -command [list apply {{var} {
                ttkbootstrap::StatusBar::msg $::sbbar [set $var] -clear 2000
            }} $var]
        ttk::label $row.v -textvariable $var -width 12 \
            -foreground [ttkbootstrap::getColor $bs] \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 12] bold]
        pack $row.l $row.tp $row.v -side left -padx [ttkbootstrap::_sp 6]
    }

    ttk::separator $p.sep_svgtp -orient horizontal
    pack $p.sep_svgtp -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "TimePicker (SVG \u2014 New)" \
        "SVG clock icon with hour/minute popup."

    set svgtprow [ttk::frame $p.svgtprow -padding [ttkbootstrap::_sp2 16 6]]
    pack $svgtprow -fill x
    set ::svgtp_time ""
    ttk::label $svgtprow.l -text "Select time:" -width 12 -anchor w
    ttkbootstrap::SVGTimePicker $svgtprow.tp \
        -bootstyle primary -textvariable ::svgtp_time
    pack $svgtprow.l -side left
    pack $svgtprow.tp -side left -padx [ttkbootstrap::_sp 8]


    ttk::separator $p.sep2 -orient horizontal
    pack $p.sep2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "DateRangePicker" \
        "Two linked calendars. Click a start date then an end date."

    set ::drp_start {}; set ::drp_end {}
    set drp [ttkbootstrap::DateRangePicker $p.drp \
        -bootstyle primary \
        -startvar  ::drp_start \
        -endvar    ::drp_end \
        -command   {
            ttkbootstrap::StatusBar::msg $::sbbar \
                "Range: $::drp_start → $::drp_end" -clear 4000
        }]
    set ::drp_widget $drp
    pack $drp -fill x -padx [ttkbootstrap::_sp 16]

    # Result display
    set rrow [ttk::frame $p.rrow -padding [ttkbootstrap::_sp 16]]
    pack $rrow -fill x
    ttk::label $rrow.sl -text "Start:" -width 6 -anchor w
    ttk::label $rrow.sv -textvariable ::drp_start -width 12 \
        -foreground [ttkbootstrap::getColor primary]
    ttk::label $rrow.arrow -text " → " -foreground [ttkbootstrap::getColor secondary]
    ttk::label $rrow.el -text "End:" -width 5 -anchor w
    ttk::label $rrow.ev -textvariable ::drp_end -width 12 \
        -foreground [ttkbootstrap::getColor primary]
    ttk::button $rrow.clr -text "Clear" -style "danger.Outline.TButton" \
        -padding [ttkbootstrap::_sp2 6 2] \
        -command { ttkbootstrap::DateRangePicker::clear $::drp_widget }
    pack $rrow.sl $rrow.sv $rrow.arrow $rrow.el $rrow.ev $rrow.clr \
        -side left -padx [ttkbootstrap::_sp 3]
}

# ═══════════════════════════════════════════════════════════════════════════════
# NAVIGATION
# ═══════════════════════════════════════════════════════════════════════════════
proc build_nav {f} {
    set p [page_sf $f]
    section_hdr $p "Notebook" "Tabbed container — standard ttk::notebook with bootstyle."

    set nb [ttk::notebook $p.nb -style "primary.TNotebook"]
    pack $nb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 12]
    foreach tab {Alpha Beta Gamma} {
        set t [ttk::frame $nb.t$tab -padding [ttkbootstrap::_sp 12]]
        ttk::label $t.l -text "Content of tab $tab." \
            -foreground [ttkbootstrap::getColor secondary]
        pack $t.l
        $nb add $t -text $tab
    }

    ttk::separator $p.sep1 -orient horizontal
    pack $p.sep1 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Breadcrumb (Original)" \
        "Clickable navigation path. Click a segment to navigate back."

    set ::nav_bc [ttkbootstrap::Breadcrumb $p.bc \
        -items     {Home Products Electronics Laptops} \
        -bootstyle primary \
        -command   {
            set items [ttkbootstrap::Breadcrumb::get $::nav_bc]
            ttkbootstrap::Breadcrumb::load $::nav_bc [lrange $items 0 $idx]
            ttkbootstrap::StatusBar::msg $::sbbar "Nav: $label" -clear 2000
        }]
    pack $p.bc -anchor w -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp2 0 8]

    set bcctrl [ttk::frame $p.bcctrl -padding [ttkbootstrap::_sp2 16 6]]
    pack $bcctrl -fill x
    ttk::button $bcctrl.push -text "Push" -style "primary.TButton" \
        -command { ttkbootstrap::Breadcrumb::push $::nav_bc "Item [expr {[llength [ttkbootstrap::Breadcrumb::get $::nav_bc]]+1}]" }
    ttk::button $bcctrl.pop  -text "Pop"  -style "secondary.Outline.TButton" \
        -command { ttkbootstrap::Breadcrumb::pop $::nav_bc }
    ttk::button $bcctrl.reset -text "Reset" -style "danger.Outline.TButton" \
        -command { ttkbootstrap::Breadcrumb::load $::nav_bc {Home} }
    pack $bcctrl.push $bcctrl.pop $bcctrl.reset -side left -padx [ttkbootstrap::_sp 4]

    ttk::separator $p.sep_svgbc -orient horizontal
    pack $p.sep_svgbc -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Breadcrumb (SVG \u2014 New)" \
        "SVG chevron separators between path items."

    set svgbcrow [ttk::frame $p.svgbcrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $svgbcrow -fill x
    ttkbootstrap::SVGBreadcrumb $svgbcrow.bc \
        -items {"Home" "Documents" "Reports" "Q4 Summary"} \
        -bootstyle primary \
        -command {
            ttkbootstrap::StatusBar::msg $::sbbar \
                "SVG Breadcrumb clicked: item $::idx" -clear 2000
        }
    pack $svgbcrow.bc -fill x

    set ::_svgbc_widget $p.svgbcrow.bc
    set svgbcbtns [ttk::frame $p.svgbcbtns -padding [ttkbootstrap::_sp2 16 4]]
    pack $svgbcbtns -fill x
    ttk::button $svgbcbtns.push -text "Push" \
        -style "primary.Outline.TButton" -padding [ttkbootstrap::_sp2 10 3] \
        -command {
            set items [ttkbootstrap::SVGBreadcrumb::get $::_svgbc_widget]
            lappend items "Sub[llength $items]"
            ttkbootstrap::SVGBreadcrumb::load $::_svgbc_widget $items
        }
    ttk::button $svgbcbtns.pop -text "Pop" \
        -style "warning.Outline.TButton" -padding [ttkbootstrap::_sp2 10 3] \
        -command {
            set items [ttkbootstrap::SVGBreadcrumb::get $::_svgbc_widget]
            if {[llength $items] > 1} {
                ttkbootstrap::SVGBreadcrumb::load $::_svgbc_widget \
                    [lrange $items 0 end-1]
            }
        }
    ttk::button $svgbcbtns.reset -text "Reset" \
        -style "danger.Outline.TButton" -padding [ttkbootstrap::_sp2 10 3] \
        -command {
            ttkbootstrap::SVGBreadcrumb::load $::_svgbc_widget {"Home"}
        }
    pack $svgbcbtns.push $svgbcbtns.pop $svgbcbtns.reset \
        -side left -padx [ttkbootstrap::_sp 4]


    ttk::separator $p.sep2 -orient horizontal
    pack $p.sep2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "StepProgress (Original)" \
        "Canvas-drawn wizard step indicator — click Next/Back to advance steps."

    set ::nav_step 0
    set sp [ttkbootstrap::StepProgress $p.sp \
        -steps {Account Profile Payment Confirm Done} \
        -current 0 -bootstyle primary \
        -command { update_nav_wizard }]
    set ::nav_sp $sp   ;# store path for Back/Next button commands
    pack $sp -fill x -padx [ttkbootstrap::_sp 24] -pady [ttkbootstrap::_sp2 0 8]

    set wiz [ttk::frame $p.wiz -padding [ttkbootstrap::_sp2 16 4]]
    pack $wiz -fill x
    set ::nav_wiz_frame $wiz

    proc update_nav_wizard {} {
        foreach w [winfo children $::nav_wiz_frame] { destroy $w }
        set msgs {"Enter account details." "Complete your profile." \
                  "Add payment method." "Review and confirm." "All done!"}
        set col [expr {$::nav_step < 4 ? "fg" : "success"}]
        ttk::label $::nav_wiz_frame.msg \
            -text [lindex $msgs $::nav_step] \
            -foreground [ttkbootstrap::getColor $col]
        pack $::nav_wiz_frame.msg -side left
        set nav [ttk::frame $::nav_wiz_frame.nav]
        pack $nav -side right
        if {$::nav_step > 0} {
            ttk::button $nav.b -text "← Back" -style "secondary.Outline.TButton" \
                -command {
                    incr ::nav_step -1
                    ttkbootstrap::StepProgress::prev $::nav_sp
                }
            pack $nav.b -side left
        }
        if {$::nav_step < 4} {
            ttk::button $nav.n -text "Next →" -style "primary.TButton" \
                -command {
                    incr ::nav_step 1
                    ttkbootstrap::StepProgress::next $::nav_sp
                }
            pack $nav.n -side left -padx [ttkbootstrap::_sp 4]
        }
    }
    update_nav_wizard

    ttk::separator $p.sep_svgsp -orient horizontal
    pack $p.sep_svgsp -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "StepProgress (SVG \u2014 New)" \
        "SVG-rendered step indicator — crisp circles and connector lines. Click any step."

    set ::svgnav_step 0
    set svgsp [ttkbootstrap::SVGStepProgress $p.svgsp \
        -steps {Account Profile Payment Confirm Done} \
        -current 0 -bootstyle primary \
        -command { update_svgnav_wizard }]
    set ::svgnav_sp $svgsp
    pack $svgsp -fill x -padx [ttkbootstrap::_sp 24] -pady [ttkbootstrap::_sp2 0 8]

    set svgwiz [ttk::frame $p.svgwiz -padding [ttkbootstrap::_sp2 16 4]]
    pack $svgwiz -fill x
    set ::svgnav_wiz_frame $svgwiz

    proc update_svgnav_wizard {{idx {}}} {
        if {$idx ne {}} { set ::svgnav_step $idx }
        foreach w [winfo children $::svgnav_wiz_frame] { destroy $w }
        set msgs {"Enter account details." "Complete your profile." \
                  "Add payment method." "Review and confirm." "All done!"}
        set col [expr {$::svgnav_step < 4 ? "fg" : "success"}]
        ttk::label $::svgnav_wiz_frame.msg \
            -text [lindex $msgs $::svgnav_step] \
            -foreground [ttkbootstrap::getColor $col]
        pack $::svgnav_wiz_frame.msg -side left
        set nav [ttk::frame $::svgnav_wiz_frame.nav]
        pack $nav -side right
        if {$::svgnav_step > 0} {
            ttk::button $nav.b -text "\u2190 Back" -style "secondary.Outline.TButton" \
                -command {
                    incr ::svgnav_step -1
                    ttkbootstrap::SVGStepProgress::goto $::svgnav_sp $::svgnav_step
                }
            pack $nav.b -side left
        }
        if {$::svgnav_step < 4} {
            ttk::button $nav.n -text "Next \u2192" -style "primary.TButton" \
                -command {
                    incr ::svgnav_step 1
                    ttkbootstrap::SVGStepProgress::goto $::svgnav_sp $::svgnav_step
                }
            pack $nav.n -side left -padx [ttkbootstrap::_sp 4]
        }
    }
    update_svgnav_wizard

    ttk::separator $p.sep3 -orient horizontal
    pack $p.sep3 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "CollapsingFrame" \
        "Accordion panel — click a header to show or hide its content."

    set cf [ttkbootstrap::CollapsingFrame $p.cf]
    pack $cf -fill x -padx [ttkbootstrap::_sp 16]

    foreach {title bs fields} {
        "Personal Details"   primary  {Name Email Phone}
        "Address"            success  {Street City Country}
        "Preferences"        info     {Language Timezone Notifications}
    } {
        set pane [ttk::frame $cf.p$bs -padding [ttkbootstrap::_sp 10]]
        foreach fld $fields {
            set row [ttk::frame $pane.r$fld]
            ttk::label $row.l -text "$fld:" -width 14 -anchor w
            ttk::entry $row.e -width 24
            pack $row.l $row.e -side left
            pack $row -fill x -pady [ttkbootstrap::_sp 2]
        }
        ttkbootstrap::CollapsingFrame::add $cf $pane $title $bs
    }
    ttkbootstrap::CollapsingFrame::close $cf $cf.pinfo
}

# ═══════════════════════════════════════════════════════════════════════════════
# OVERLAYS
# ═══════════════════════════════════════════════════════════════════════════════
proc build_overlays {f} {
    set p [page_sf $f]
    section_hdr $p "Toast" \
        "Timed floating notification. Appears in a corner and fades."

    set trow [ttk::frame $p.trow -padding [ttkbootstrap::_sp 16]]
    pack $trow -fill x
    foreach {bs msg} {
        primary  "Info: operation completed"
        success  "Success: file saved"
        warning  "Warning: low disk space"
        danger   "Error: connection failed"
    } {
        ttk::button $trow.t$bs \
            -text    [string totitle $bs] \
            -style   "$bs.TButton" \
            -padding [ttkbootstrap::_sp2 10 4] \
            -command [list ttkbootstrap::Toast $msg -bootstyle $bs]
        pack $trow.t$bs -side left -padx [ttkbootstrap::_sp 4]
    }

    ttk::separator $p.sep1 -orient horizontal
    pack $p.sep1 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "NotificationBanner" \
        "Persistent coloured strip. Stays until dismissed."

    set ::nb_active {}
    set nbframe [ttk::labelframe $p.nbframe -text "Preview" \
        -padding [ttkbootstrap::_sp 8]]
    pack $nbframe -fill x -padx [ttkbootstrap::_sp 16]

    set nbctrl [ttk::frame $p.nbctrl -padding [ttkbootstrap::_sp2 16 6]]
    pack $nbctrl -fill x
    foreach {bs label} {info Info success Success warning Warning danger Danger} {
        ttk::button $nbctrl.b$bs \
            -text $label -style "$bs.TButton" -padding [ttkbootstrap::_sp2 8 3] \
            -command [list apply {{bs nbf} {
                if {$::nb_active ne {} && [winfo exists $::nb_active]} {
                    ttkbootstrap::NotificationBanner::hide $::nb_active
                    destroy $::nb_active
                }
                set msg "[string totitle $bs] banner: click × to dismiss"
                set ::nb_active [ttkbootstrap::NotificationBanner $nbf \
                    -message $msg \
                    -bootstyle $bs]
            }} $bs $nbframe]
        pack $nbctrl.b$bs -side left -padx [ttkbootstrap::_sp 3]
    }

    ttk::separator $p.sep2 -orient horizontal
    pack $p.sep2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "ProgressDialog" \
        "Modal progress dialog with cancel support."

    set pdrow [ttk::frame $p.pdrow -padding [ttkbootstrap::_sp 16]]
    pack $pdrow -fill x

    ttk::button $pdrow.det -text "Determinate" -style "primary.TButton" \
        -padding [ttkbootstrap::_sp2 10 4] \
        -command {
            set pd [ttkbootstrap::ProgressDialog . \
                -title "Processing" -message "Working..." \
                -maximum 20 -bootstyle primary -parent .]
            for {set i 0} {$i <= 20} {incr i} {
                ttkbootstrap::ProgressDialog::update $pd $i "Step $i of 20"
                update; after 60
            }
            ttkbootstrap::ProgressDialog::close $pd
        }
    ttk::button $pdrow.indet -text "Indeterminate" -style "info.TButton" \
        -padding [ttkbootstrap::_sp2 10 4] \
        -command {
            set pd [ttkbootstrap::ProgressDialog . \
                -title "Connecting" -message "Please wait..." \
                -mode indeterminate -bootstyle info -parent .]
            ttkbootstrap::ProgressDialog::start $pd
            after 2500 [list ttkbootstrap::ProgressDialog::close $pd]
        }
    set ::ov_cancelled 0
    ttk::button $pdrow.cancel -text "With Cancel" -style "warning.TButton" \
        -padding [ttkbootstrap::_sp2 10 4] \
        -command {
            set ::ov_cancelled 0
            set pd [ttkbootstrap::ProgressDialog . \
                -title "Downloading" -message "Downloading..." \
                -maximum 30 -bootstyle success \
                -cancelvar ::ov_cancelled -parent .]
            for {set i 0} {$i <= 30 && !$::ov_cancelled} {incr i} {
                ttkbootstrap::ProgressDialog::update $pd $i "File $i of 30"
                update; after 50
            }
            catch { ttkbootstrap::ProgressDialog::close $pd }
            if {$::ov_cancelled} {
                ttkbootstrap::StatusBar::msg $::sbbar "Download cancelled" -clear 2000
            } else {
                ttkbootstrap::StatusBar::msg $::sbbar "Download complete" -clear 2000
            }
        }
    pack $pdrow.det $pdrow.indet $pdrow.cancel -side left -padx [ttkbootstrap::_sp 4]

    ttk::separator $p.sep3 -orient horizontal
    pack $p.sep3 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Tooltip (Original)" \
        "Hover over the buttons below to see tooltips."

    set ttrow [ttk::frame $p.ttrow -padding [ttkbootstrap::_sp 16]]
    pack $ttrow -fill x
    foreach {text tip bs} {
        "Hover me"          "This is a primary tooltip"        primary
        "And me"            "Tooltips can show any text"       success
        "Me too"            "They appear on hover, after 500ms" warning
    } {
        set b [ttk::button $ttrow.tt[incr ::tt_idx] -text $text \
            -style "$bs.Outline.TButton" -padding [ttkbootstrap::_sp2 10 4]]
        pack $b -side left -padx [ttkbootstrap::_sp 4]
        ttkbootstrap::Tooltip $b $tip -bootstyle $bs
    }

    ttk::separator $p.sep_dlg -orient horizontal
    pack $p.sep_dlg -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Dialog (SVG \u2014 New)" \
        "Modal dialog with coloured title bar and action buttons."
    set dlgrow [ttk::frame $p.dlgrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $dlgrow -fill x
    ttk::button $dlgrow.confirm -text "Confirm Dialog" \
        -style "primary.TButton" -padding [ttkbootstrap::_sp2 12 4] \
        -command {
            set result [ttkbootstrap::SVGDialog::show \
                -title "Confirm Action" \
                -message "Are you sure you want to proceed with this action? This cannot be undone." \
                -bootstyle primary -buttons {Cancel Confirm} -default Confirm]
            ttkbootstrap::StatusBar::msg $::sbbar "Dialog result: $result" -clear 2000
        }
    ttk::button $dlgrow.delete -text "Delete Dialog" \
        -style "danger.TButton" -padding [ttkbootstrap::_sp2 12 4] \
        -command {
            set result [ttkbootstrap::SVGDialog::show \
                -title "Delete Item" \
                -message "This will permanently delete the selected item." \
                -bootstyle danger -buttons {Cancel Delete} -default Cancel]
            ttkbootstrap::StatusBar::msg $::sbbar "Dialog result: $result" -clear 2000
        }
    pack $dlgrow.confirm $dlgrow.delete -side left -padx [ttkbootstrap::_sp 4]
    
    ttk::separator $p.sep_snb -orient horizontal
    pack $p.sep_snb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Notification Banner (SVG \u2014 New)" \
        "Slide-in SVG notification with shadow and accent bar."
    set snbrow [ttk::frame $p.snbrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $snbrow -fill x
    # -parent $::pf is what makes the banner appear to "slide in from the edge".
    # Passing a parent renders the banner as a place-managed CHILD of that frame
    # instead of as a standalone floating toplevel. Because the parent clips
    # anything outside its bounds, the banner can start fully off the right edge
    # (hidden) and animate inward into view — a floating toplevel can't be
    # clipped by another window, so it could only ever pop in fully formed.
    # We parent to $::pf (the page area, below the navbar) so the banner does
    # not cover the theme selector / light-dark toggle in the title bar.
    # Omit -parent entirely to get the classic floating-toplevel notification.
    foreach {lbl bs} {"Info" info "Success" success "Warning" warning "Error" danger} {
        ttk::button $snbrow.nb[incr ::snb_idx] -text $lbl -style "$bs.TButton" \
            -padding [ttkbootstrap::_sp2 12 4] \
            -command [list ttkbootstrap::SVGNotificationBanner::show \
                -title $lbl -message "This is a $lbl notification." \
                -bootstyle $bs -duration 2500 -parent $::pf]
        pack $snbrow.nb$::snb_idx -side left -padx [ttkbootstrap::_sp 4]
    }
    ttk::separator $p.sep_snb2 -orient horizontal
    pack $p.sep_snb2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]

    section_hdr $p "Tooltip (SVG \u2014 New)" \
        "SVG rounded tooltip with theme-aware colours."

    set svgttrow [ttk::frame $p.svgttrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $svgttrow -fill x
    foreach {bs lbl tip} {
        primary "Hover me" "This is a primary tooltip"
        success "And me"   "Success! Everything is working."
        danger  "Me too"   "Warning: this action cannot be undone."
    } {
        ttk::button $svgttrow.b[incr ::svgtt_idx] \
            -text $lbl -style "$bs.TButton" -padding [ttkbootstrap::_sp2 12 4]
        ttkbootstrap::SVGTooltip $svgttrow.b$::svgtt_idx $tip \
            -bootstyle $bs -delay 400
        pack $svgttrow.b$::svgtt_idx -side left -padx [ttkbootstrap::_sp 6]
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# LAYOUT
# ═══════════════════════════════════════════════════════════════════════════════
proc build_layout {f} {
    set p [page_sf $f]
    section_hdr $p "Card (Original)" \
        "Titled content panel with accent stripe, body, and optional footer."

    set cg [ttk::frame $p.cg -padding [ttkbootstrap::_sp 16]]
    pack $cg -fill x
    foreach {bs title sub} {
        primary "Primary Card"  "Subtitle text"
        success "Success Card"  "With footer"
        warning "Warning Card"  "No subtitle"
    } {
        set c [ttkbootstrap::Card $cg.c$bs \
            -title $title -subtitle $sub -bootstyle $bs -padding 10]
        set body [ttkbootstrap::Card::body $cg.c$bs]
        ttk::label $body.l -text "Card body content." \
            -foreground [ttkbootstrap::getColor secondary]
        pack $body.l
        if {$bs eq "success"} {
            set ft [ttkbootstrap::Card::footer $cg.c$bs]
            ttk::button $ft.ok -text "Action" -style "$bs.TButton" \
                -padding [ttkbootstrap::_sp2 8 2] \
                -command { ttkbootstrap::StatusBar::msg $::sbbar "Card action!" -clear 1500 }
            pack $ft.ok -anchor e
        }
        pack $cg.c$bs -side left -fill x -expand 1 -padx [ttkbootstrap::_sp 4]
    }

    ttk::separator $p.sep_svgcd -orient horizontal
    pack $p.sep_svgcd -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Card (SVG \u2014 New)" \
        "SVG rounded card container with coloured title bar."

    set svgcdrow [ttk::frame $p.svgcdrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $svgcdrow -fill x
    foreach {bs title} {primary "Project Status" success "Revenue" warning "Alerts"} {
        set c [ttkbootstrap::SVGCard $svgcdrow.c[incr ::svgcd_idx] \
            -title $title -bootstyle $bs -padding [ttkbootstrap::_sp 8] \
            -width [ttkbootstrap::_sp 180] -height [ttkbootstrap::_sp 140]]
        set body [ttkbootstrap::SVGCard::body $c]
        ttk::label $body.l -text "Content for $title card." \
            -wraplength [ttkbootstrap::_sp 120]
        pack $body.l -pady [ttkbootstrap::_sp 4]
        pack $c -side left -padx [ttkbootstrap::_sp 6] -fill both -expand 1
    }


    ttk::separator $p.sep_shcard -orient horizontal
    pack $p.sep_shcard -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Card with Shadow (SVG \u2014 New)" \
        "SVG card with layered drop shadow for a raised effect."

    set shcdrow [ttk::frame $p.shcdrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $shcdrow -fill x
    foreach {bs title content} {
        primary "Dashboard" "Active users: 1,247"
        success "Revenue"   "Q4: +18% growth"
        danger  "Alerts"    "3 critical issues"
    } {
        set sc [ttkbootstrap::SVGShadowCard $shcdrow.sc[incr ::shcd_idx] \
            -title $title -bootstyle $bs \
            -padding [ttkbootstrap::_sp 8] \
            -width [ttkbootstrap::_sp 220] \
            -height [ttkbootstrap::_sp 200] \
            -shadow 10]
        set body [ttkbootstrap::SVGShadowCard::body $sc]
        ttk::label $body.l -text $content -wraplength [ttkbootstrap::_sp 120]
        pack $body.l -pady [ttkbootstrap::_sp 4]
        pack $sc -side left -padx [ttkbootstrap::_sp 8] -fill both -expand 1
    }

    ttk::separator $p.sep_icons -orient horizontal
    pack $p.sep_icons -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "SVG Icon Library (SVG \u2014 New)" \
        "Built-in scalable SVG icons. [llength [ttkbootstrap::SVGIconNames]] icons available."
    set iconrow [ttk::frame $p.iconrow -padding [ttkbootstrap::_sp2 16 6]]
    pack $iconrow -fill x
    ttkbootstrap::SVGIconFlush
    set _icon_colours [list \
        [ttkbootstrap::getColor primary] \
        [ttkbootstrap::getColor success] \
        [ttkbootstrap::getColor danger] \
        [ttkbootstrap::getColor warning] \
        [ttkbootstrap::getColor info] \
        [ttkbootstrap::getColor secondary]]
    set _ci 0
    set _all_icons [ttkbootstrap::SVGIconNames]
    set _per_row 8
    set _nrows [expr {([llength $_all_icons] + $_per_row - 1) / $_per_row}]
    for {set _r 0} {$_r < $_nrows} {incr _r} {
        set _start [expr {$_r * $_per_row}]
        set _end [expr {min($_start + $_per_row - 1, [llength $_all_icons] - 1)}]
        set _rowicons [lrange $_all_icons $_start $_end]
        set rf [ttk::frame $iconrow.irow$_r]
        pack $rf -fill x -pady [ttkbootstrap::_sp 3]
        foreach name $_rowicons {
            set clr [lindex $_icon_colours [expr {$_ci % [llength $_icon_colours]}]]
            set img [ttkbootstrap::SVGIcon $name -size [ttkbootstrap::_sp 44] -colour $clr]
            set f [ttk::frame $rf.if[incr ::icon_idx]]
            ttk::label $f.i -image $img
            ttk::label $f.n -text $name \
                -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                            [ttkbootstrap::_sf 10]] \
                -foreground [ttkbootstrap::getColor secondary]
            pack $f.i -pady [ttkbootstrap::_sp2 2 0]
            pack $f.n
            pack $f -side left -padx [ttkbootstrap::_sp 6] -pady [ttkbootstrap::_sp 3]
            incr _ci
        }
    }
    ttk::separator $p.sep_cp -orient horizontal
    pack $p.sep_cp -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Colour Picker (SVG \u2014 New)" \
        "SVG colour palette with clickable swatches."
    set ::picked_colour "#2196F3"
    ttkbootstrap::SVGColourPicker $p.cp -variable ::picked_colour -bootstyle primary
    pack $p.cp -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 4]
    ttk::separator $p.sep_tree -orient horizontal
    pack $p.sep_tree -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Treeview (SVG \u2014 New)" \
        "Tree with SVG chevrons, hover highlight, and selection."
    set tv [ttkbootstrap::SVGTreeview $p.tree -bootstyle primary \
        -height [ttkbootstrap::_sp 200]]
    set _docs [ttkbootstrap::SVGTreeview::insert $tv "" "Documents" -open 1]
    ttkbootstrap::SVGTreeview::insert $tv $_docs "report.pdf"
    ttkbootstrap::SVGTreeview::insert $tv $_docs "budget.xlsx"
    set _img [ttkbootstrap::SVGTreeview::insert $tv $_docs "Images" -open 1]
    ttkbootstrap::SVGTreeview::insert $tv $_img "photo1.png"
    ttkbootstrap::SVGTreeview::insert $tv $_img "photo2.png"
    set _code [ttkbootstrap::SVGTreeview::insert $tv "" "Code" -open 0]
    ttkbootstrap::SVGTreeview::insert $tv $_code "main.tcl"
    ttkbootstrap::SVGTreeview::insert $tv $_code "test.tcl"
    pack $tv -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 4]

    ttk::separator $p.sep_tabs -orient horizontal
    pack $p.sep_tabs -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Tab Notebook (SVG \u2014 New)" \
        "Tabbed notebook with SVG rounded tab headers."
    set nb [ttkbootstrap::SVGTabNotebook $p.nb -bootstyle primary]
    ttkbootstrap::SVGTabNotebook::add $nb "Overview" \
        -create {ttk::label %f.l -text "Overview content goes here." -padding 16; pack %f.l}
    ttkbootstrap::SVGTabNotebook::add $nb "Details" \
        -create {ttk::label %f.l -text "Detail information here." -padding 16; pack %f.l}
    ttkbootstrap::SVGTabNotebook::add $nb "Settings" \
        -create {ttk::label %f.l -text "Settings panel here." -padding 16; pack %f.l}
    pack $nb -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 4]

    ttk::separator $p.sep_stext -orient horizontal
    pack $p.sep_stext -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "ScrolledText" \
        "Text widget with built-in scrollbars."

    set st [ttkbootstrap::ScrolledText $p.st \
        -height [ttkbootstrap::_sp 6] \
        -bootstyle primary]
    pack $st -fill x -padx [ttkbootstrap::_sp 16]
    $p.st.txt insert end "The ScrolledText widget wraps a standard Tk Text widget\n"
    $p.st.txt insert end "with themed scrollbars added automatically.\n\n"
    $p.st.txt insert end "You can type in this widget — it is fully editable.\n"
    $p.st.txt insert end "Vertical and horizontal scrollbars appear when needed."

    ttk::separator $p.sep2 -orient horizontal
    pack $p.sep2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Timeline (Original)" \
        "Vertical event history. Click Add to append a new event."

    set tl [ttkbootstrap::Timeline $p.tl]
    set ::tl_widget $p.tl   ;# store path for Add button
    pack $tl -fill both -expand 1 -padx [ttkbootstrap::_sp 16]

    foreach {bs icon title ts body} {
        success  ✓  "Widget v1.5.0 released"  "2024-06-01 09:00"
                     "64 widgets, 18 themes, DPI scaling."
        primary  ★  "TimePicker added"          "2024-06-01 08:30"
                     "Clock popup with 24h, 12h AM/PM, and seconds modes."
        info     •  "Tier 3 widgets completed"  "2024-05-28 14:00"
                     "DateRangePicker and EditableTableview now fully tested."
        warning  ⚠  "Emoji removed"             "2024-05-25 11:00"
                     "All icons now use self-contained SVG images."
    } {
        ttkbootstrap::Timeline::add $p.tl \
            -title $title -timestamp $ts -body $body \
            -bootstyle $bs -icon $icon
    }
    set tlctrl [ttk::frame $p.tlctrl -padding [ttkbootstrap::_sp 16]]
    pack $tlctrl -fill x
    set ::tl_msg {}
    ttk::entry $tlctrl.e -textvariable ::tl_msg -width 30
    ttk::button $tlctrl.add -text "Add Event" -style "primary.TButton" \
        -command {
            if {$::tl_msg ne {}} {
                ttkbootstrap::Timeline::add $::tl_widget \
                    -title $::tl_msg \
                    -timestamp [clock format [clock seconds] -format "%Y-%m-%d %H:%M"] \
                    -bootstyle primary
                set ::tl_msg {}
            }
        }
    pack $tlctrl.e $tlctrl.add -side left -padx [ttkbootstrap::_sp 4]
    # ::tl_widget already set to $p.tl (the Timeline namespace key) above
    ttk::separator $p.sep_svgtl -orient horizontal
    pack $p.sep_svgtl -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 12]
    section_hdr $p "Timeline (SVG \u2014 New)" \
        "SVG circles and connector lines for event timeline."

    set svgtl [ttkbootstrap::SVGTimeline $p.svgtl]
    pack $svgtl -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 4]

    set ::svgtl_widget $svgtl
    ttkbootstrap::SVGTimeline::add $svgtl \
        -title "Deployed v2.1" -timestamp "Today 14:32" \
        -body "All services updated." -bootstyle success \
        -icon "\u2713" -shape circle
    ttkbootstrap::SVGTimeline::add $svgtl \
        -title "Code review" -timestamp "Yesterday 10:15" \
        -body "PR #142 approved." -bootstyle primary \
        -icon "\u2714" -shape square
    ttkbootstrap::SVGTimeline::add $svgtl \
        -title "Bug reported" -timestamp "May 15 09:00" \
        -body "Login page crash on Safari." -bootstyle danger \
        -icon "!" -shape circle
    ttkbootstrap::SVGTimeline::add $svgtl \
        -title "Sprint started" -timestamp "May 14 08:00" \
        -bootstyle info -icon "\u25b6" -shape square

    set svgtlctrl [ttk::frame $p.svgtlctrl -padding [ttkbootstrap::_sp 16]]
    pack $svgtlctrl -fill x
    set ::svgtl_msg {}
    ttk::entry $svgtlctrl.e -textvariable ::svgtl_msg -width 30
    ttk::button $svgtlctrl.add -text "Add Event" -style "primary.TButton" \
        -command {
            if {$::svgtl_msg ne {}} {
                ttkbootstrap::SVGTimeline::add $::svgtl_widget \
                    -title $::svgtl_msg \
                    -timestamp [clock format [clock seconds] -format "%H:%M"] \
                    -bootstyle primary -shape circle
                set ::svgtl_msg {}
            }
        }
    pack $svgtlctrl.e $svgtlctrl.add -side left -padx [ttkbootstrap::_sp 4]


}

# ═══════════════════════════════════════════════════════════════════════════════
# GALLERY APPS
# ═══════════════════════════════════════════════════════════════════════════════
proc build_gallery {f} {
    set p [page_sf $f]
    section_hdr $p "Gallery Applications" \
        "Full working application demos — each opens in a new window."

    set grid [ttk::frame $p.grid -padding [ttkbootstrap::_sp 16]]
    pack $grid -fill x

    set gallery_dir [file join [file dirname [info script]]]

    set apps {
        mdi             "MDI Desktop"            primary   "Multiple Document Interface — run all gallery apps as floating windows"
        calculator      "Calculator"             primary   "Scientific calculator with all operations"
        stopwatch       "Stopwatch"              success   "Lap-timer style stopwatch"
        data_entry      "Data Entry Form"        info      "Form validation and submission"
        magic_mouse     "Magic Mouse Settings"   secondary "System settings-style panel"
        media_player    "Media Player UI"        primary   "Player controls and equalizer stub"
        pc_cleaner      "PC Cleaner"             warning   "Multi-tab cleanup utility"
        file_search_engine "File Search"         info      "Recursive filesystem search"
        back_me_up      "Back Me Up"             success   "Backup manager with CollapsingFrame"
        text_reader     "Text Reader"            secondary "Browse and display text files"
        equalizer       "Equalizer"              primary   "Canvas-drawn drag-and-drop EQ bands"
    }

    set col 0; set row 0; set ci 0
    foreach {key title bs desc} $apps {
        set c [ttkbootstrap::Card $grid.c[incr ci] \
            -title $title -bootstyle $bs -padding 10]
        set body [ttkbootstrap::Card::body $grid.c$ci]
        ttk::label $body.d -text $desc -wraplength [ttkbootstrap::_sp 150] \
            -justify left -foreground [ttkbootstrap::getColor secondary]
        pack $body.d -fill x
        set ft [ttkbootstrap::Card::footer $grid.c$ci]
        ttk::button $ft.open -text "Launch →" \
            -style "$bs.Outline.TButton" -padding [ttkbootstrap::_sp2 6 2] \
            -command [list launch_gallery $key $gallery_dir]
        pack $ft.open -anchor e
        grid $grid.c$ci -row $row -column $col \
            -padx [ttkbootstrap::_sp 5] -pady [ttkbootstrap::_sp 5] -sticky nsew
        incr col
        if {$col >= 3} { set col 0; incr row }
    }
    for {set c 0} {$c < 3} {incr c} { grid columnconfigure $grid $c -weight 1 }
}


# ═══════════════════════════════════════════════════════════════════════════════
# SETTINGS
# ═══════════════════════════════════════════════════════════════════════════════
proc build_settings {f} {
    set p [page_sf $f]
    section_hdr $p "Settings"

    # Theme
    set c1 [ttkbootstrap::Card $p.c1 -title "Theme" -bootstyle secondary -padding 12]
    set b1 [ttkbootstrap::Card::body $p.c1]
    set ::set_theme [ttkbootstrap::currentTheme]
    ttk::combobox $b1.cb \
        -textvariable ::set_theme \
        -values       [ttkbootstrap::themeNames] \
        -state        readonly -width 20
    bind $b1.cb <<ComboboxSelected>> {
        ttkbootstrap::setTheme $::set_theme
        ttkbootstrap::StatusBar::msg $::sbbar "Theme: $::set_theme" -clear 2000
        ttkbootstrap::StatusBar::right $::sbbar $::set_theme 0
    }
    pack $b1.cb -anchor w

    # Theme preview thumbnails — click to apply
    ttk::label $b1.previewlbl -text "Click a theme to preview:" \
        -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                    [ttkbootstrap::_sf 10]] \
        -foreground [ttkbootstrap::getColor secondary]
    pack $b1.previewlbl -anchor w -pady [ttkbootstrap::_sp2 8 2]

    # Theme preview swatches. Each swatch is an SVG rendered to a Tk photo by
    # ttkbootstrap::themeSwatch, showing a theme's bg + accent colours. Two
    # subtleties worth copying into your own code:
    #   1) Rounded SVG corners. themeSwatch draws a page-bg rect BEHIND the
    #      rounded rect so the antialiased corners blend into the surface instead
    #      of leaving transparent/black/white "tips". The host label therefore
    #      uses -bd 0 (no square border that would re-expose those corners).
    #   2) A photo image caches the colours at render time, so it does NOT follow
    #      a live theme change on its own. We rebind <<ThemeChanged>> to
    #      regenerate the swatch with the new page bg; without this, a light
    #      theme's swatch shows white corner tips once you switch to a dark theme.
    set swatchwrap [ttk::frame $b1.swatches]
    pack $swatchwrap -anchor w -fill x
    set _col 0
    set _row 0
    foreach _th [ttkbootstrap::themeNames] {
        set _img [ttkbootstrap::themeSwatch $_th \
            -width [ttkbootstrap::_sp 110] -height [ttkbootstrap::_sp 40]]
        set _sf [ttk::frame $swatchwrap.f$_th]
        label $_sf.img -image $_img -bd 0 -highlightthickness 0 \
            -bg [ttkbootstrap::getColor bg] -cursor hand2
        # When the theme changes, regenerate this swatch (so its corner fill
        # matches the new page bg) and update the label bg, otherwise stale
        # light-bg corners show as white tips on a dark theme (and vice versa).
        bind $_sf.img <<ThemeChanged>> [list apply {{lbl th} {
            if {![winfo exists $lbl]} return
            set img [ttkbootstrap::themeSwatch $th \
                -width [ttkbootstrap::_sp 110] -height [ttkbootstrap::_sp 40]]
            $lbl configure -image $img -bg [ttkbootstrap::getColor bg]
        }} $_sf.img $_th]
        ttk::label $_sf.name -text $_th \
            -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                        [ttkbootstrap::_sf 9]]
        pack $_sf.img
        pack $_sf.name
        grid $_sf -row $_row -column $_col \
            -padx [ttkbootstrap::_sp 4] -pady [ttkbootstrap::_sp 4]
        bind $_sf.img <Button-1> [list apply {{th} {
            ttkbootstrap::setTheme $th
            set ::set_theme $th
            ttkbootstrap::StatusBar::msg $::sbbar "Theme: $th" -clear 2000
        }} $_th]
        incr _col
        if {$_col >= 5} { set _col 0; incr _row }
    }

    pack $p.c1 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # Sidebar
    set c2 [ttkbootstrap::Card $p.c2 -title "Sidebar" -bootstyle secondary -padding 12]
    set b2 [ttkbootstrap::Card::body $p.c2]
    set ::set_sidebar 1
    ttkbootstrap::ToggleSwitch $b2.ts1 \
        -text "Show sidebar" -variable ::set_sidebar -bootstyle primary \
        -command {
            if {$::set_sidebar} {
                pack $::sb -before $::root.main -side left -fill y
            } else { pack forget $::sb }
        }
    set ::set_statusbar 1
    ttkbootstrap::ToggleSwitch $b2.ts2 \
        -text "Show status bar" -variable ::set_statusbar -bootstyle primary \
        -command {
            if {$::set_statusbar} {
                pack $::sbbar -side bottom -fill x
                pack $::main.sep1 -fill x
            } else {
                pack forget $::sbbar
                pack forget $::main.sep1
            }
        }
    pack $b2.ts1 $b2.ts2 -fill x -pady [ttkbootstrap::_sp 4]
    pack $p.c2 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]

    # About
    set c3 [ttkbootstrap::Card $p.c3 -title "About" -bootstyle secondary -padding 12]
    set b3 [ttkbootstrap::Card::body $p.c3]
    foreach {lbl val} {
        "Package:"   "ttkbootstrap for Tcl/Tk"
        "Version:"   "1.5.0"
        "Widgets:"   "64 custom widgets (27 original + 37 SVG)"
        "Themes:"    "18 themes (13 light, 5 dark)"
        "Requires:"  "Tcl/Tk 9.0+"
    } {
        set row [ttk::frame $b3.r[incr ::si]]
        ttk::label $row.l -text $lbl -width 14 -anchor w \
            -foreground [ttkbootstrap::getColor secondary]
        ttk::label $row.v -text $val -anchor w
        pack $row.l $row.v -side left
        pack $row -fill x -pady [ttkbootstrap::_sp 2]
    }
    pack $p.c3 -fill x -padx [ttkbootstrap::_sp 16] -pady [ttkbootstrap::_sp 8]
}

# ── Counter resets (called in build_ procs to keep widget paths stable) ────────
set ::hdr_idx 0; set ::card_idx 0; set ::rr 0; set ::cb_idx 0
set ::ts_idx 0;  set ::fg_idx 0;   set ::pb_idx 0; set ::bdg_idx 0
set ::slr_idx 0; set ::tt_idx 0;   set ::si 0

# Override show_page to reset counters on each navigation


# ── Start ─────────────────────────────────────────────────────────────────────
show_page overview
update
show_splash_startup

vwait forever
