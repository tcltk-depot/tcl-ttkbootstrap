# =============================================================================
# ttkbootstrap.tcl — Native Tcl/Tk port of ttkbootstrap
# Version 1.5.0
#
# A Bootstrap-inspired theming library for Tk/Ttk, faithfully ported from
# israel-dryer/ttkbootstrap (Python). Provides 18 themes (light + dark),
# a keyword "bootstyle" API, styled ttk widgets, and custom widgets:
#   Meter, Floodgauge, DateEntry, DatePickerDialog,
#   ScrolledFrame, ScrolledText, Toast, Tooltip, Tableview
#
# Usage:
#   package require ttkbootstrap
#   ttkbootstrap::setTheme flatly        ;# or superhero, darkly, cosmo, etc.
#   set btn [ttk::button .b -text "Click" -style "success.TButton"]
#

# Ensure Tk is loaded — safe to call if already loaded (tclkit, wish, tclsh+Tk)
# In headless tclsh environments (e.g. test runners) this is a no-op if Tk
# isn't available; widget procs that need Tk are wrapped in catch.
if {[catch {package present Tk}]} {
    catch { package require Tk }
}
# Bootstyle helper (creates a style string):
#   set style [ttkbootstrap::bootstyle success outline]   ;# → "success.Outline.TButton"
#
# Available themes:
#   Light: cosmo flatly litera minty lumen sandstone yeti pulse united
#          morph journal simplex cerculean
#   Dark:  darkly superhero solar cyborg vapor
# =============================================================================

package provide ttkbootstrap 1.5.0

namespace eval ttkbootstrap {

    # -------------------------------------------------------------------------
    # Theme color databases — exact hex values from ttkbootstrap Python source
    # -------------------------------------------------------------------------
    variable themes
    array set themes {
        cosmo {
            type light  primary #2780e3  secondary #7E8081  success #3fb618
            info #9954bb  warning #ff7518  danger #ff0039
            light #F8F9FA  dark #373A3C  bg #ffffff  fg #373a3c
            selectbg #7e8081  selectfg #ffffff  border #ced4da  active #1d6bcc
            inputfg #373a3c  inputbg #fdfdfe  font TkDefaultFont
        }
        flatly {
            type light  primary #2c3e50  secondary #95a5a6  success #18bc9c
            info #3498db  warning #f39c12  danger #e74c3c
            light #ECF0F1  dark #7B8A8B  bg #ffffff  fg #212529
            selectbg #95a5a6  selectfg #ffffff  border #ced4da  active #1a252f
            inputfg #212529  inputbg #ffffff  font TkDefaultFont
        }
        litera {
            type light  primary #4582ec  secondary #adb5bd  success #02b875
            info #17a2b8  warning #f0ad4e  danger #d9534f
            light #F8F9FA  dark #343A40  bg #ffffff  fg #343a40
            selectbg #adb5bd  selectfg #ffffff  border #bfbfbf  active #1b6ec2
            inputfg #343a40  inputbg #ffffff  font TkDefaultFont
        }
        minty {
            type light  primary #78c2ad  secondary #f3969a  success #56cc9d
            info #6cc3d5  warning #ffce67  danger #ff7851
            light #F8F9FA  dark #343A40  bg #ffffff  fg #5a5a5a
            selectbg #f3969a  selectfg #ffffff  border #ced4da  active #5aab98
            inputfg #696969  inputbg #ffffff  font TkDefaultFont
        }
        lumen {
            type light  primary #158cba  secondary #919191  success #28b62c
            info #75caeb  warning #ff851b  danger #ff4136
            light #F6F6F6  dark #555555  bg #ffffff  fg #555555
            selectbg #919191  selectfg #ffffff  border #ced4da  active #0f6b8e
            inputfg #555555  inputbg #ffffff  font TkDefaultFont
        }
        sandstone {
            type light  primary #325D88  secondary #8e8c84  success #93c54b
            info #29abe0  warning #f47c3c  danger #d9534f
            light #F8F5F0  dark #3E3F3A  bg #ffffff  fg #3e3f3a
            selectbg #8e8c84  selectfg #ffffff  border #ced4da  active #264669
            inputfg #6E6D69  inputbg #ffffff  font TkDefaultFont
        }
        yeti {
            type light  primary #008cba  secondary #707070  success #43ac6a
            info #5bc0de  warning #e99002  danger #f04124
            light #EEEEEE  dark #222222  bg #ffffff  fg #222222
            selectbg #707070  selectfg #ffffff  border #cccccc  active #006b8f
            inputfg #222222  inputbg #ffffff  font TkDefaultFont
        }
        pulse {
            type light  primary #593196  secondary #69676E  success #13b955
            info #009cdc  warning #efa31d  danger #fc3939
            light #F9F8FC  dark #17141F  bg #ffffff  fg #444444
            selectbg #69676e  selectfg #ffffff  border #cbc8d0  active #45267a
            inputfg #444444  inputbg #fdfdfe  font TkDefaultFont
        }
        united {
            type light  primary #e95420  secondary #aea79f  success #38b44a
            info #17a2b8  warning #efb73e  danger #df382c
            light #E9ECEF  dark #772953  bg #ffffff  fg #333333
            selectbg #aea79f  selectfg #ffffff  border #ced4da  active #c44218
            inputfg #333333  inputbg #ffffff  font TkDefaultFont
        }
        morph {
            type light  primary #378DFC  secondary #aaaaaa  success #43cc29
            info #5B62F4  warning #FFC107  danger #E52527
            light #F0F5FA  dark #212529  bg #D9E3F1  fg #7B8AB8
            selectbg #aaaaaa  selectfg #FBFDFF  border #B9C7DA  active #0a6ef3
            inputfg #7F8EBA  inputbg #F0F5FA  font TkDefaultFont
        }
        journal {
            type light  primary #eb6864  secondary #aaaaaa  success #22b24c
            info #336699  warning #f5e625  danger #f57a00
            light #F8F9FA  dark #222222  bg #ffffff  fg #222222
            selectbg #aaaaaa  selectfg #ffffff  border #ced4da  active #d94d49
            inputfg #565656  inputbg #ffffff  font TkDefaultFont
        }
        simplex {
            type light  primary #d8220e  secondary #858e96  success #469307
            info #0099ce  warning #d88220  danger #9a479e
            light #f2f2f2  dark #3b3d3f  bg #fcfcfc  fg #3b3d3f
            selectbg #a9afb6  selectfg #ffffff  border #858e96  active #b31c0b
            inputfg #3b3d3f  inputbg #fcfcfc  font TkDefaultFont
        }
        cerculean {
            type light  primary #4bb1ea  secondary #a9b4be  success #84b251
            info #225384  warning #e16e25  danger #cf3c40
            light #eceef1  dark #33383e  bg #ffffff  fg #2ea4e7
            selectbg #adb5bd  selectfg #ffffff  border #a9b4be  active #24a0e0
            inputfg #495057  inputbg #ffffff  font TkDefaultFont
        }
        darkly {
            type dark  primary #375a7f  secondary #444444  success #00bc8c
            info #3498db  warning #f39c12  danger #e74c3c
            light #ADB5BD  dark #303030  bg #222222  fg #ffffff
            selectbg #555555  selectfg #ffffff  border #222222  active #2b476a
            inputfg #ffffff  inputbg #2f2f2f  font TkDefaultFont
        }
        superhero {
            type dark  primary #4c9be8  secondary #4e5d6c  success #5cb85c
            info #5bc0de  warning #f0ad4e  danger #d9534f
            light #ABB6C2  dark #20374C  bg #2b3e50  fg #ffffff
            selectbg #526170  selectfg #ffffff  border #222222  active #2f82d6
            inputfg #ebebeb  inputbg #32465a  font TkDefaultFont
        }
        solar {
            type dark  primary #bc951a  secondary #94a2a4  success #44aca4
            info #3f98d7  warning #d05e2f  danger #d95092
            light #A9BDBD  dark #073642  bg #002B36  fg #ffffff
            selectbg #0b5162  selectfg #ffffff  border #00252e  active #9d7c15
            inputfg #A9BDBD  inputbg #073642  font TkDefaultFont
        }
        cyborg {
            type dark  primary #2a9fd6  secondary #555555  success #77b300
            info #9933cc  warning #ff8800  danger #cc0000
            light #ADAFAE  dark #222222  bg #060606  fg #ffffff
            selectbg #454545  selectfg #ffffff  border #060606  active #2080b1
            inputfg #ffffff  inputbg #191919  font TkDefaultFont
        }
        vapor {
            type dark  primary #6e40c0  secondary #ea38b8  success #3af180
            info #1da2f2  warning #ffbd05  danger #e34b54
            light #44d7e8  dark #170229  bg #190831  fg #32fbe2
            selectbg #461a8a  selectfg #ffffff  border #060606  active #5832a6
            inputfg #bfb6cd  inputbg #30115e  font TkDefaultFont
        }
    }

    # Currently active theme name
    variable currentTheme ""

    # -------------------------------------------------------------------------
    # Public: setTheme name
    #   Apply a ttkbootstrap theme. Must be called after [ttk::style] is ready
    #   (i.e., after a Tk window exists).
    # -------------------------------------------------------------------------
    proc setTheme {name} {
        variable themes
        variable currentTheme

        if {![info exists themes($name)]} {
            set valid [lsort [array names themes]]
            error "Unknown theme \"$name\". Valid themes: $valid"
        }

        set currentTheme $name
        array set c $themes($name)
        set isDark [expr {$c(type) eq "dark"}]

        # Build on clam — same base as Python ttkbootstrap
        ttk::style theme use clam

        # ------------------------------------------------------------------
        # Global defaults
        # ------------------------------------------------------------------
        ttk::style configure . \
            -background      $c(bg) \
            -foreground      $c(fg) \
            -troughcolor     $c(light) \
            -selectbackground $c(selectbg) \
            -selectforeground $c(selectfg) \
            -fieldbackground $c(inputbg) \
            -bordercolor     $c(border) \
            -darkcolor       $c(border) \
            -lightcolor      $c(bg) \
            -insertcolor     $c(fg) \
            -relief          flat \
            -borderwidth     [_sp 1] \
            -focuscolor      $c(primary)

        # Refresh DPI scale factor (reads tk scaling each time theme is set)
        _updateScale

        # Global font fallback — sized to current DPI
        set font [_safeFont $c(font)]
        set fontNormal [list $font [_sf 12]]
        ttk::style configure . -font $fontNormal
        # Lock focus ring thickness to prevent text shift on state changes
        catch { ttk::style configure . -focusthickness 0 }

        # ------------------------------------------------------------------
        # TFrame / TLabelframe
        # ------------------------------------------------------------------
        ttk::style configure TFrame \
            -background $c(bg) -relief flat -borderwidth 0

        ttk::style configure TLabelframe \
            -background $c(bg) -foreground $c(fg) \
            -bordercolor $c(border) -relief groove -borderwidth [_sp 1]
        ttk::style configure TLabelframe.Label \
            -background $c(bg) -foreground $c(fg) -font $fontNormal

        # ------------------------------------------------------------------
        # TLabel
        # ------------------------------------------------------------------
        ttk::style configure TLabel \
            -background $c(bg) -foreground $c(fg) -padding [_sp2 2 2]

        # Colored label variants + Inverse (text on colored background)
        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger) \
            light $c(light) dark $c(dark)] {
            ttk::style configure ${color}.TLabel \
                -background $c(bg) -foreground $hex
            # Inverse: white/contrasting text on the color background
            ttk::style configure ${color}.Inverse.TLabel \
                -background $hex -foreground [_contrastFg $hex]
            # Colored frames
            ttk::style configure ${color}.TFrame \
                -background $hex
        }

        # ------------------------------------------------------------------
        # TButton — solid
        # Keep clam's Button.border layout (it provides the background).
        # Kill the 3D bevel by setting lightcolor=darkcolor=background.
        # ------------------------------------------------------------------
        _configButton $c(primary) primary $c(bg) $c(fg)
        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger) \
            light $c(light) dark $c(dark)] {
            _configButton $hex $color $c(bg) $c(fg)
        }
        # Bare TButton defaults to primary color
        ttk::style configure TButton \
            -background  $c(primary) \
            -foreground  [_contrastFg $c(primary)] \
            -bordercolor $c(primary) \
            -darkcolor   $c(primary) \
            -lightcolor  $c(primary) \
            -relief      flat \
            -padding     [_fontPad 10] \
            -anchor      center \
            -borderwidth 0 \
            -focusthickness 0
        ttk::style map TButton \
            -background  [list active [_darken $c(primary) 12] \
                               pressed [_darken $c(primary) 20] \
                               disabled $c(bg)] \
            -foreground  [list disabled $c(secondary)] \
            -darkcolor   [list active [_darken $c(primary) 12] \
                               pressed [_darken $c(primary) 20]] \
            -lightcolor  [list active [_darken $c(primary) 12] \
                               pressed [_darken $c(primary) 20]]

        # ------------------------------------------------------------------
        # TButton — outline variant
        # ------------------------------------------------------------------
        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger) \
            light $c(light) dark $c(dark)] {
            _configOutlineButton $hex $color $c(bg)
        }

        # ------------------------------------------------------------------
        # TEntry
        # ------------------------------------------------------------------
        ttk::style configure TEntry \
            -fieldbackground $c(inputbg) \
            -foreground      $c(inputfg) \
            -bordercolor     $c(border) \
            -insertcolor     $c(inputfg) \
            -padding         [_fontPad 6] \
            -relief          flat \
            -lightcolor      $c(border) \
            -darkcolor       $c(border)
        ttk::style map TEntry \
            -fieldbackground [list focus $c(inputbg) disabled $c(light)] \
            -bordercolor     [list focus $c(primary) disabled $c(border)] \
            -lightcolor      [list focus $c(primary)] \
            -darkcolor       [list focus $c(primary)] \
            -foreground      [list disabled $c(secondary)]

        # ------------------------------------------------------------------
        # TCombobox
        # ------------------------------------------------------------------
        ttk::style configure TCombobox \
            -fieldbackground $c(inputbg) \
            -foreground      $c(fg) \
            -selectforeground $c(selectfg) \
            -selectbackground $c(selectbg) \
            -bordercolor     $c(border) \
            -arrowcolor      $c(secondary) \
            -padding         [_fontPad 6] \
            -relief          flat \
            -lightcolor      $c(border) \
            -darkcolor       $c(border)
        ttk::style map TCombobox \
            -fieldbackground [list focus $c(inputbg) disabled $c(light)] \
            -foreground      [list disabled $c(secondary)] \
            -bordercolor     [list focus $c(primary) disabled $c(border)] \
            -lightcolor      [list focus $c(primary)] \
            -darkcolor       [list focus $c(primary)] \
            -arrowcolor      [list focus $c(primary)]

        # ------------------------------------------------------------------
        # TSpinbox
        # ------------------------------------------------------------------
        ttk::style configure TSpinbox \
            -fieldbackground $c(inputbg) \
            -foreground      $c(inputfg) \
            -bordercolor     $c(border) \
            -arrowcolor      $c(secondary) \
            -padding         [_fontPad 6] \
            -relief          flat \
            -lightcolor      $c(border) \
            -darkcolor       $c(border)
        ttk::style map TSpinbox \
            -fieldbackground [list focus $c(inputbg) disabled $c(light)] \
            -bordercolor     [list focus $c(primary)] \
            -lightcolor      [list focus $c(primary)] \
            -darkcolor       [list focus $c(primary)]

        # ------------------------------------------------------------------
        # TCheckbutton — image-based indicator in imgstyles.tcl
        # ------------------------------------------------------------------
        ttk::style configure TCheckbutton \
            -background $c(bg) \
            -foreground $c(fg) \
            -compound   text
        ttk::style map TCheckbutton \
            -background [list active $c(bg)] \
            -foreground [list disabled $c(secondary)]

        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger)] {
            ttk::style configure ${color}.TCheckbutton \
                -background $c(bg) -foreground $c(fg) -compound text -compound text
            ttk::style map ${color}.TCheckbutton \
                -background [list active $c(bg)]
        }

        # ------------------------------------------------------------------
        # TRadiobutton — image-based indicator in imgstyles.tcl
        # ------------------------------------------------------------------
        ttk::style configure TRadiobutton \
            -background $c(bg) \
            -foreground $c(fg) \
            -compound   text
        ttk::style map TRadiobutton \
            -background [list active $c(bg)] \
            -foreground [list disabled $c(secondary)]

        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger)] {
            ttk::style configure ${color}.TRadiobutton \
                -background $c(bg) -foreground $c(fg) -compound text -compound text
            ttk::style map ${color}.TRadiobutton \
                -background [list active $c(bg)]
        }

        # ------------------------------------------------------------------
        # TProgressbar — horizontal & vertical
        # ------------------------------------------------------------------
        ttk::style configure TProgressbar \
            -background  $c(primary) \
            -troughcolor $c(light) \
            -bordercolor $c(light) \
            -lightcolor  $c(primary) \
            -darkcolor   $c(primary) \
            -borderwidth 0 \
            -thickness   [_sp 20]

        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger)] {
            set trough [Colors::update_hsv $hex -sd -0.3 -vd \
                [expr {$isDark ? -0.3 : 0.3}]]
            foreach orient {Horizontal Vertical} {
                ttk::style configure ${color}.${orient}.TProgressbar \
                    -background  $hex \
                    -troughcolor $trough \
                    -lightcolor  $hex \
                    -darkcolor   $hex \
                    -borderwidth 0
            }
        }

        # ------------------------------------------------------------------
        # TScale — image-based slider/track applied in imgstyles.tcl
        # ------------------------------------------------------------------
        ttk::style configure TScale \
            -background  $c(primary) \
            -troughcolor $c(light) \
            -bordercolor $c(border) \
            -darkcolor   $c(light) \
            -lightcolor  $c(light) \
            -groovewidth [_sp 4] \
            -sliderrelief flat \
            -sliderlength [_sp 16] \
            -sliderthickness [_sp 16]
        ttk::style map TScale \
            -background  [list active [_darken $c(primary) 10]] \
            -troughcolor [list disabled $c(light)]

        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger)] {
            set trough [Colors::update_hsv $hex -sd -0.3 -vd \
                [expr {$isDark ? -0.3 : 0.3}]]
            foreach orient {Horizontal Vertical} {
                ttk::style configure ${color}.${orient}.TScale \
                    -background  $hex \
                    -troughcolor $trough \
                    -darkcolor   $trough \
                    -lightcolor  $trough \
                    -sliderrelief flat
                ttk::style map ${color}.${orient}.TScale \
                    -background [list active [_darken $hex 10]]
            }
        }

        # TScrollbar — image-based thumb applied in imgstyles.tcl
        set _sb_thumb [expr {$isDark ? $c(secondary) : $c(border)}]
        set _sb_trough [expr {$isDark ? \
            [_darken $c(bg) 8] : [_darken $c(light) 5]}]
        ttk::style configure TScrollbar \
            -background  $_sb_thumb \
            -troughcolor $_sb_trough \
            -arrowcolor  $c(secondary) \
            -bordercolor $_sb_trough \
            -darkcolor   $_sb_trough \
            -lightcolor  $_sb_trough \
            -relief      flat \
            -arrowsize   [_sp 12]
        ttk::style map TScrollbar \
            -background [list active $c(primary) disabled $c(light)] \
            -arrowcolor [list active $c(primary)]

        # ------------------------------------------------------------------
        # TMenubutton — colored like a button, bevel killed via lightcolor
        # ------------------------------------------------------------------
        ttk::style configure TMenubutton \
            -background  $c(primary) \
            -foreground  [_contrastFg $c(primary)] \
            -darkcolor   $c(primary) \
            -lightcolor  $c(primary) \
            -bordercolor $c(primary) \
            -relief      flat \
            -padding     [_sp2 10 5] \
            -arrowcolor  [_contrastFg $c(primary)] \
            -borderwidth [_sp 1]

        foreach {color hex} [list \
            primary $c(primary) secondary $c(secondary) \
            success $c(success) info $c(info) \
            warning $c(warning) danger $c(danger)] {
            set mfg [_contrastFg $hex]
            set activeHex [_darken $hex 12]
            ttk::style configure ${color}.TMenubutton \
                -background $hex -foreground $mfg \
                -darkcolor $hex -lightcolor $hex -bordercolor $hex \
                -relief flat -borderwidth [_sp 1] -arrowcolor $mfg -padding [_sp2 10 5]
            ttk::style map ${color}.TMenubutton \
                -background  [list active $activeHex] \
                -darkcolor   [list active $activeHex] \
                -lightcolor  [list active $activeHex] \
                -bordercolor [list active $activeHex]
            ttk::style configure ${color}.Outline.TMenubutton \
                -background $c(bg) -foreground $hex \
                -darkcolor $hex -lightcolor $hex -bordercolor $hex \
                -relief groove -borderwidth [_sp 1] -arrowcolor $hex -padding [_sp2 10 5]
            ttk::style map ${color}.Outline.TMenubutton \
                -background  [list active $hex] \
                -foreground  [list active $mfg] \
                -darkcolor   [list active $hex] \
                -lightcolor  [list active $hex] \
                -arrowcolor  [list active $mfg]
        }

        # ------------------------------------------------------------------
        # TNotebook
        # ------------------------------------------------------------------
        ttk::style configure TNotebook \
            -background $c(light) \
            -bordercolor $c(border) \
            -tabmargins {0 0 0 0}
        ttk::style configure TNotebook.Tab \
            -background $c(light) \
            -foreground $c(secondary) \
            -padding    [_sp2 12 6] \
            -bordercolor $c(border)
        ttk::style map TNotebook.Tab \
            -background [list selected $c(bg) active $c(bg)] \
            -foreground [list selected $c(fg) active $c(fg)]

        # ------------------------------------------------------------------
        # Treeview
        # ------------------------------------------------------------------
        ttk::style configure Treeview \
            -background  $c(bg) \
            -foreground  $c(fg) \
            -fieldbackground $c(bg) \
            -bordercolor $c(border) \
            -rowheight   [_sp 24]
        ttk::style map Treeview \
            -background [list selected $c(selectbg) disabled $c(light)] \
            -foreground [list selected $c(selectfg) disabled $c(secondary)]
        ttk::style configure Treeview.Heading \
            -background  $c(secondary) \
            -foreground  $c(selectfg) \
            -relief      flat \
            -borderwidth 0 \
            -padding     [_sp2 8 4]
        ttk::style map Treeview.Heading \
            -background [list active $c(primary)] \
            -foreground [list active $c(selectfg)]

        # ------------------------------------------------------------------
        # TSeparator
        # ------------------------------------------------------------------
        ttk::style configure TSeparator -background $c(border)

        # ------------------------------------------------------------------
        # TPanedwindow
        # ------------------------------------------------------------------
        ttk::style configure TPanedwindow \
            -background $c(bg)
        ttk::style configure Sash \
            -sashthickness [_sp 6] -gripcount 10


        # ------------------------------------------------------------------
        # TSizegrip
        # ------------------------------------------------------------------
        ttk::style configure TSizegrip -background $c(bg)

        # ------------------------------------------------------------------
        # Apply to root window background (if exists)
        # ------------------------------------------------------------------
        catch {. configure -background $c(bg)}

        return $name
    }

    # -------------------------------------------------------------------------
    # Public: currentTheme
    #   Returns the name of the currently active theme.
    # -------------------------------------------------------------------------
    proc currentTheme {} {
        variable currentTheme
        return $currentTheme
    }

    # -------------------------------------------------------------------------
    # Public: getColors ?themeName?
    #   Returns a dict of color keys for the given (or current) theme.
    # -------------------------------------------------------------------------
    proc getColors {{name ""}} {
        variable themes
        variable currentTheme
        if {$name eq ""} { set name $currentTheme }
        if {![info exists themes($name)]} {
            error "Unknown theme: $name"
        }
        return $themes($name)
    }

    # -------------------------------------------------------------------------
    # Public: getColor colorKey ?themeName?
    #   Returns a single hex color for the given key in the active theme.
    # -------------------------------------------------------------------------
    proc getColor {key {name ""}} {
        array set c [getColors $name]
        if {![info exists c($key)]} {
            error "Unknown color key \"$key\""
        }
        return $c($key)
    }


    # -------------------------------------------------------------------------
    # Public: themeNames
    #   Returns a sorted list of all available theme names.
    # -------------------------------------------------------------------------
    proc themeNames {} {
        variable themes
        return [lsort [array names themes]]
    }

    # -------------------------------------------------------------------------
    # Public: lightThemes / darkThemes
    # -------------------------------------------------------------------------
    proc lightThemes {} {
        variable themes
        set result {}
        foreach name [lsort [array names themes]] {
            array set c $themes($name)
            if {$c(type) eq "light"} { lappend result $name }
        }
        return $result
    }
    proc darkThemes {} {
        variable themes
        set result {}
        foreach name [lsort [array names themes]] {
            array set c $themes($name)
            if {$c(type) eq "dark"} { lappend result $name }
        }
        return $result
    }

    # -------------------------------------------------------------------------
    # Public: bootstyle color ?variant? ?widgetClass?
    #   Produces a ttk style string from keyword args, similar to Python's
    #   bootstyle= parameter.
    #
    #   Examples:
    #     bootstyle success             → "success.TButton"
    #     bootstyle success outline     → "success.Outline.TButton"
    #     bootstyle info TLabel         → "info.TLabel"
    #     bootstyle warning striped TProgressbar → "warning.Striped.Horizontal.TProgressbar"
    # -------------------------------------------------------------------------
    proc bootstyle {args} {
        set color ""
        set variants {}
        set widgetClass "TButton"

        set knownColors {primary secondary success info warning danger light dark}
        set knownVariants {outline link striped round roundtoggle squaretoggle toolbutton square}
        set knownClasses {TButton TLabel TEntry TFrame
                          TProgressbar Horizontal.TProgressbar Vertical.TProgressbar
                          TCheckbutton TRadiobutton TScale
                          TScrollbar Horizontal.TScrollbar Vertical.TScrollbar
                          TNotebook TMenubutton Treeview TSpinbox TCombobox
                          Toolbutton.TButton Outline.Toolbutton.TButton}

        foreach arg $args {
            set arg_lc [string tolower $arg]
            if {[lsearch -exact $knownColors $arg_lc] >= 0} {
                set color $arg_lc
            } elseif {[lsearch -exact $knownVariants $arg_lc] >= 0} {
                lappend variants [string totitle $arg_lc]
            } elseif {[lsearch $knownClasses $arg] >= 0} {
                set widgetClass $arg
            }
        }

        # Build style name:  color.Variant1.Variant2.WidgetClass
        set parts {}
        if {$color ne ""} { lappend parts $color }
        foreach v $variants { lappend parts $v }

        # Special case: TProgressbar and TScrollbar need the orientation
        if {$widgetClass eq "TProgressbar"} {
            lappend parts "Horizontal.TProgressbar"
        } elseif {$widgetClass eq "TScrollbar"} {
            lappend parts "Horizontal.TScrollbar"
        } elseif {$widgetClass eq "TCheckbutton"} {
            # Round/Square toggles map to registered image-based styles.
            # "success round TCheckbutton" → "success.Round.TCheckbutton"
            # "square TCheckbutton" (no color) → "primary.Square.TCheckbutton"
            set hasToggle [expr {
                [lsearch $variants Round] >= 0 || [lsearch $variants Square] >= 0
            }]
            if {$hasToggle} {
                set parts {}
                if {$color ne ""} { lappend parts $color } else { lappend parts primary }
                foreach v $variants { lappend parts $v }
            }
            lappend parts $widgetClass
        } else {
            lappend parts $widgetClass
        }

        return [join $parts "."]
    }

    # =========================================================================
    # Private helpers
    # =========================================================================

    # _configButton hex colorName bg fg
    # _fontPad hPx — compute vertical padding that centres text in a target
    # widget height. Returns a list {hPx vPx} where vPx is computed from
    # the current theme font's linespace.
    proc _fontPad {hPx} {
        variable themes; variable currentTheme
        if {[info exists currentTheme] && [info exists themes($currentTheme)]} {
            array set c $themes($currentTheme)
        } else {
            return [_sp2 $hPx 5]
        }
        set fn [_safeFont $c(font)]
        set fs [_sf 12]
        set ls [font metrics [list $fn $fs] -linespace]
        # Target widget inner height: linespace + comfortable padding
        # Vertical pad = enough to vertically centre the text with room
        set vPx [expr {max(2, int($ls * 0.35))}]
        return [list [_sp $hPx] $vPx]
    }

    proc _configButton {hex colorName bg fg} {
        set btnFg [_contrastFg $hex]
        set activeHex [_darken $hex 12]
        set pressHex  [_darken $hex 20]

        ttk::style configure ${colorName}.TButton \
            -background  $hex \
            -foreground  $btnFg \
            -bordercolor $hex \
            -darkcolor   $hex \
            -lightcolor  $hex \
            -relief      flat \
            -padding     [_fontPad 10] \
            -anchor      center \
            -borderwidth 0 \
            -focusthickness 0

        ttk::style map ${colorName}.TButton \
            -background  [list active $activeHex pressed $pressHex \
                               disabled $bg] \
            -foreground  [list disabled [_darken $fg 30]] \
            -bordercolor [list active $activeHex pressed $pressHex] \
            -darkcolor   [list active $activeHex pressed $pressHex] \
            -lightcolor  [list active $activeHex pressed $pressHex]
    }

    # _configOutlineButton hex colorName bg
    proc _configOutlineButton {hex colorName bg} {
        set fg $hex
        ttk::style configure ${colorName}.Outline.TButton \
            -background  $bg \
            -foreground  $fg \
            -bordercolor $hex \
            -darkcolor   $bg \
            -lightcolor  $bg \
            -relief      solid \
            -padding     [_fontPad 10] \
            -anchor      center \
            -borderwidth [_sp 1] \
            -focusthickness 0

        ttk::style map ${colorName}.Outline.TButton \
            -background  [list active $hex pressed [_darken $hex 10] \
                               disabled $bg] \
            -foreground  [list active [_contrastFg $hex] \
                               pressed [_contrastFg $hex] \
                               disabled [_darken $hex 30]] \
            -bordercolor [list active $hex disabled [_darken $hex 30]] \
            -darkcolor   [list active $bg pressed $bg] \
            -lightcolor  [list active $bg pressed $bg]
    }

    # _darken hex pct — darken a hex color by pct (0-100)
    proc _darken {hex pct} {
        set hex [string trimleft $hex "#"]
        if {[string length $hex] != 6} { return "#$hex" }
        set r [expr {[scan [string range $hex 0 1] %x r; set r] * (100-$pct) / 100}]
        set g [expr {[scan [string range $hex 2 3] %x g; set g] * (100-$pct) / 100}]
        set b [expr {[scan [string range $hex 4 5] %x b; set b] * (100-$pct) / 100}]
        set r [expr {$r < 0 ? 0 : ($r > 255 ? 255 : $r)}]
        set g [expr {$g < 0 ? 0 : ($g > 255 ? 255 : $g)}]
        set b [expr {$b < 0 ? 0 : ($b > 255 ? 255 : $b)}]
        return [format "#%02x%02x%02x" $r $g $b]
    }

    # _lighten hex pct
    proc _lighten {hex pct} {
        set hex [string trimleft $hex "#"]
        if {[string length $hex] != 6} { return "#$hex" }
        scan [string range $hex 0 1] %x r
        scan [string range $hex 2 3] %x g
        scan [string range $hex 4 5] %x b
        set r [expr {int($r + (255-$r)*$pct/100)}]
        set g [expr {int($g + (255-$g)*$pct/100)}]
        set b [expr {int($b + (255-$b)*$pct/100)}]
        set r [expr {$r > 255 ? 255 : $r}]
        set g [expr {$g > 255 ? 255 : $g}]
        set b [expr {$b > 255 ? 255 : $b}]
        return [format "#%02x%02x%02x" $r $g $b]
    }

    # _luminance hex → 0.0–1.0
    proc _luminance {hex} {
        set hex [string trimleft $hex "#"]
        scan [string range $hex 0 1] %x r
        scan [string range $hex 2 3] %x g
        scan [string range $hex 4 5] %x b
        set r [expr {$r/255.0}]; set g [expr {$g/255.0}]; set b [expr {$b/255.0}]
        set r [expr {$r <= 0.03928 ? $r/12.92 : pow(($r+0.055)/1.055, 2.4)}]
        set g [expr {$g <= 0.03928 ? $g/12.92 : pow(($g+0.055)/1.055, 2.4)}]
        set b [expr {$b <= 0.03928 ? $b/12.92 : pow(($b+0.055)/1.055, 2.4)}]
        return [expr {0.2126*$r + 0.7152*$g + 0.0722*$b}]
    }

    # _contrastFg hex → #ffffff or #212529 depending on contrast
    proc _contrastFg {hex} {
        set lum [_luminance $hex]
        if {$lum > 0.35} { return "#212529" } else { return "#ffffff" }
    }

    # _safeFont fontName — return the requested font if available,
    # otherwise TkDefaultFont. Always available on every platform.
    proc _safeFont {{fontName {}}} {
        if {$fontName eq {} || $fontName eq "TkDefaultFont"} {
            return TkDefaultFont
        }
        if {[catch {font actual $fontName}]} {
            return TkDefaultFont
        }
        return $fontName
    }

    # -------------------------------------------------------------------------
    # Input validation helpers for widget constructors.
    #   These fail fast with clear messages instead of cryptic errors from
    #   deep inside SVG generation.
    # -------------------------------------------------------------------------

    # Valid bootstyle colour keys (the semantic palette names).
    variable _valid_bootstyles {primary secondary success info warning danger light dark}

    # _validateBootstyle widget option value
    #   Errors if $value is not a known bootstyle. Empty string is allowed
    #   (widgets fall back to a default).
    proc _validateBootstyle {widget option value} {
        variable _valid_bootstyles
        if {$value eq ""} { return }
        if {$value ni $_valid_bootstyles} {
            error "$widget: invalid $option \"$value\" — must be one of: [join $_valid_bootstyles {, }]"
        }
    }

    # _validatePositive widget option value
    #   Errors if $value is not a positive number. Zero is allowed for
    #   "auto" sentinels by widgets that use it; pass -allowzero to permit 0.
    # _warn message
    #   Emit a non-fatal warning to stderr. Used for auto-corrected bad input
    #   (e.g. a reversed range) so problems are visible without crashing.
    proc _warn {message} {
        catch { puts stderr "ttkbootstrap warning: $message" }
    }

    proc _validatePositive {widget option value args} {
        set allowzero [expr {"-allowzero" in $args}]
        if {![string is double -strict $value]} {
            error "$widget: $option must be a number, got \"$value\""
        }
        if {$allowzero} {
            if {$value < 0} {
                error "$widget: $option must be >= 0, got $value"
            }
        } else {
            if {$value <= 0} {
                error "$widget: $option must be > 0, got $value"
            }
        }
    }

    # _validateRange widget option value min max
    proc _validateRange {widget option value min max} {
        if {![string is double -strict $value]} {
            error "$widget: $option must be a number, got \"$value\""
        }
        if {$value < $min || $value > $max} {
            error "$widget: $option must be between $min and $max, got $value"
        }
    }

    # _validateEnum widget option value validlist
    proc _validateEnum {widget option value validlist} {
        if {$value ni $validlist} {
            error "$widget: invalid $option \"$value\" — must be one of: [join $validlist {, }]"
        }
    }

    # _validateChoice widget option value validlist
    #   Alias used by some widgets.
    proc _validateChoice {widget option value validlist} {
        _validateEnum $widget $option $value $validlist
    }

    # -------------------------------------------------------------------------
    # _setup_mousewheel
    #   Registers cross-platform <MouseWheel> / Button-4/5 bindings on a widget
    #   class tag so any scrollable widget gets the right behaviour on all OSes.
    #   Called once at package load time (after Tk is available).
    # -------------------------------------------------------------------------
    proc _setup_mousewheel {} {
        set ws [tk windowingsystem]

        # Scroll amount calculator — returns integer lines to scroll
        if {$ws eq "win32"} {
            # Windows: %D comes in multiples of 120; 1 notch = 120 units
            proc _mw_delta {D} { return [expr {-$D / 120}] }
        } elseif {$ws eq "aqua"} {
            # macOS: %D is a small float, typically ±1-3 per notch
            proc _mw_delta {D} { return [expr {int(-$D)}] }
        } else {
            # X11: MouseWheel rarely fires; Button-4/5 are used instead
            proc _mw_delta {D} { return [expr {-$D / 30}] }
        }

        # Bind to the standard scrollable widget classes
        foreach class {Text Listbox Canvas Treeview} {
            if {$ws eq "x11"} {
                bind $class <Button-4> [list %W yview scroll -3 units]
                bind $class <Button-5> [list %W yview scroll  3 units]
                bind $class <Shift-Button-4> [list %W xview scroll -3 units]
                bind $class <Shift-Button-5> [list %W xview scroll  3 units]
            } else {
                bind $class <MouseWheel> \
                    {%W yview scroll [ttkbootstrap::_mw_delta %D] units}
                bind $class <Shift-MouseWheel> \
                    {%W xview scroll [ttkbootstrap::_mw_delta %D] units}
            }
        }
    }
}

# =============================================================================
# Load custom widgets
# =============================================================================
set _ttksb_dir [file dirname [info script]]
foreach _ttksb_widget {
    scaling
    colorutils
    utility
    images
    meter
    floodgauge
    dateentry
    scrolled
    toast
    tooltip
    tableview
    imgstyles
    dialogs
    icons
    validation
    window
    collapsingframe
    toggleswitch
    statusbar
    autocomplete
    progressdialog
    tagentry
    notificationbanner
    sidebar
    card
    badge
    stepprogress
    ratingbar
    splashscreen
    breadcrumb
    timeline
    sparkline
    timepicker
    daterangepicker
    editabletableview
    filechooser
    svgwidgets
} {
    source [file join $_ttksb_dir widgets ${_ttksb_widget}.tcl]
}
unset _ttksb_dir _ttksb_widget

# Install cross-platform mousewheel bindings (requires Tk display)
catch { ttkbootstrap::_setup_mousewheel }

# Fallback _close_gallery for standalone use.
# When gallery apps run outside showcase/MDI, _close_gallery is not defined.
# This provides a simple "destroy and exit" fallback that only activates
# when nothing else has already defined the proc.
if {[info commands _close_gallery] eq {}} {
    proc _close_gallery {args} {
        foreach id [after info] { catch { after cancel $id } }
        destroy .
        exit 0
    }
}




# ── PillButton (convenience wrapper) ─────────────────────────────────────────
# Pill-shaped button = SVGButton with radius = height/2
namespace eval ttkbootstrap {
proc PillButton {w args} {
    # Extract height to compute pill radius
    array set o {-height 0}
    array set o $args
    if {$o(-height) == 0} {
        set _fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
        set _fs [ttkbootstrap::_sf 12]
        set _ls [font metrics [list $_fn $_fs] -linespace]
        set o(-height) [expr {$_ls + [ttkbootstrap::_sp 14]}]
    }
    set r [expr {$o(-height) / 2}]
    return [SVGButton $w {*}$args -height $o(-height) -radius $r]
}
} ;# end namespace ttkbootstrap


# ── Per-instance image cleanup ────────────────────────────────────────────────
# Deletes all images named "<widget>::*" and the widget's instance namespace
# when the widget is destroyed. Prevents image-handle leaks across the
# create/destroy cycles that animated and stateful SVG widgets are prone to.
namespace eval ttkbootstrap {
    proc _cleanupImages {w {nsroot ""}} {
        foreach img [image names] {
            if {[string match "${w}::*" $img]} {
                catch { image delete $img }
            }
        }
        if {$nsroot ne ""} {
            catch { namespace delete ${nsroot}::$w }
        }
    }
    # Bind cleanup to a widget's <Destroy> without clobbering existing binds.
    proc _bindCleanup {w {nsroot ""}} {
        bind $w <Destroy> +[list ttkbootstrap::_cleanupImages %W $nsroot]
    }
}


# ── SVGButton ─────────────────────────────────────────────────────────────────
# Rounded-rectangle button using SVG. Like PillButton but with smaller corner
# radius for a standard button look.
#
# USAGE
#   ttkbootstrap::SVGButton .b \
#       -text "Click" -bootstyle primary -command { puts "hi" }
#
# OPTIONS  -text -bootstyle -command -outline -state -width -height -radius
#
namespace eval ttkbootstrap {

proc SVGButton {w args} {
    array set o {
        -text      "Button"
        -bootstyle primary
        -command   {}
        -outline   0
        -state     normal
        -width     0
        -height    0
        -radius    0
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGButton -bootstyle $o(-bootstyle)
    # Apply DPI scaling to defaults
    if {$o(-height) == 0} {
        # Compute height from font metrics to match original TButton
        set _fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
        set _fs [ttkbootstrap::_sf 12]
        set _ls [font metrics [list $_fn $_fs] -linespace]
        set o(-height) [expr {$_ls + [ttkbootstrap::_sp 14]}]
    }
    if {$o(-radius) < 0} { set o(-radius) [ttkbootstrap::_sp 6] }

    set ns ::ttkbootstrap::svgb::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::hover 0
    set ${ns}::press 0

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]
    set font [list $fn $fs]
    set ${ns}::font $font

    set tw [font measure $font $o(-text)]
    set W [expr {$o(-width) > 0 ? $o(-width) : $tw + 32}]
    set H $o(-height)
    set ${ns}::W $W
    set ${ns}::H $H

    _svgb_gen $w
    set fg [_svgb_fg $w]

    ttk::label $w \
        -image ${w}::img_n \
        -text $o(-text) \
        -compound center \
        -foreground $fg \
        -font $font \
        -cursor [expr {$o(-state) eq "disabled" ? "" : "hand2"}]

    bind $w <Enter>           [list ttkbootstrap::_svgb_enter $w]
    bind $w <Leave>           [list ttkbootstrap::_svgb_leave $w]
    bind $w <ButtonPress-1>   [list ttkbootstrap::_svgb_press $w]
    bind $w <ButtonRelease-1> [list ttkbootstrap::_svgb_release $w]
    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgb_retheme $w]

    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgb
    return $w
}

proc _svgb_mk {W H r color {mode normal} {outline 0} {bg ""}} {
    set _bgrect ""
    if {$bg ne ""} { set _bgrect "<rect x='0' y='0' width='$W' height='$H' fill='$bg'/>" }
    if {$outline} {
        set fill "none"
        set stroke "stroke='$color' stroke-width='2'"
        set x 1; set y 1; set w [expr {$W-2}]; set h [expr {$H-2}]
        set rr [expr {$r > 1 ? $r-1 : $r}]
        switch $mode {
            hover   { set fill "fill='$color' fill-opacity='0.12'" ; set stroke "stroke='$color' stroke-width='2'" }
            pressed { set fill "fill='$color' fill-opacity='0.22'" ; set stroke "stroke='$color' stroke-width='2'" }
            default { set fill "fill='none'" }
        }
        return "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>${_bgrect}\
<rect x='$x' y='$y' width='$w' height='$h' rx='$rr' ry='$rr' $fill $stroke/></svg>"
    } else {
        set c $color
        switch $mode {
            hover   { set c [ttkbootstrap::_darken $color 10] }
            pressed { set c [ttkbootstrap::_darken $color 20] }
        }
        return "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>${_bgrect}\
<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$c'/></svg>"
    }
}

proc _svgb_gen {w} {
    set ns ::ttkbootstrap::svgb::$w
    array set o [set ${ns}::o]
    set W [set ${ns}::W]; set H [set ${ns}::H]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set r $o(-radius); set ol $o(-outline)
    set bg [ttkbootstrap::getColor bg]
    foreach s {img_n img_h img_p} { catch { image delete ${w}::$s } }
    image create photo ${w}::img_n -data [_svgb_mk $W $H $r $hex normal  $ol $bg] -format svg
    image create photo ${w}::img_h -data [_svgb_mk $W $H $r $hex hover   $ol $bg] -format svg
    image create photo ${w}::img_p -data [_svgb_mk $W $H $r $hex pressed $ol $bg] -format svg
}

proc _svgb_fg {w} {
    set ns ::ttkbootstrap::svgb::$w
    array set o [set ${ns}::o]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    return [expr {$o(-outline) ? $hex : [ttkbootstrap::_contrastFg $hex]}]
}

proc _svgb_enter {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgb::$w
    array set o [set ${ns}::o]
    if {$o(-state) eq "disabled"} return
    set ${ns}::hover 1
    $w configure -image ${w}::img_h
}

proc _svgb_leave {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgb::$w
    set ${ns}::hover 0; set ${ns}::press 0
    $w configure -image ${w}::img_n
}

proc _svgb_press {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgb::$w
    array set o [set ${ns}::o]
    if {$o(-state) eq "disabled"} return
    set ${ns}::press 1
    $w configure -image ${w}::img_p
}

proc _svgb_release {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgb::$w
    array set o [set ${ns}::o]
    if {$o(-state) eq "disabled"} return
    set ${ns}::press 0
    $w configure -image [expr {[set ${ns}::hover] ? "${w}::img_h" : "${w}::img_n"}]
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _svgb_retheme {w} {
    if {![winfo exists $w]} return
    _svgb_gen $w
    $w configure -image ${w}::img_n -foreground [_svgb_fg $w]
}

} ;# end namespace ttkbootstrap

# ── SVGCheck ──────────────────────────────────────────────────────────────────
# SVG checkbox with animated check mark.
#
# USAGE
#   ttkbootstrap::SVGCheck .cb \
#       -text "Accept terms" -bootstyle success -variable ::accepted
#
namespace eval ttkbootstrap {

proc SVGCheck {w args} {
    array set o {
        -text      ""
        -bootstyle primary
        -variable  {}
        -command   {}
        -state     normal
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGCheck -bootstyle $o(-bootstyle)

    set ns ::ttkbootstrap::svgck::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::hover 0

    set sz [ttkbootstrap::_sf 20]
    set ${ns}::sz $sz

    _svgck_gen $w

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]

    ttk::frame $w
    ttk::label $w.box -image ${w}::img_off -cursor hand2
    ttk::label $w.lbl -text $o(-text) -font [list $fn $fs] \
        -cursor hand2 -foreground [ttkbootstrap::getColor fg]
    pack $w.box -side left -padx [ttkbootstrap::_sp2 0 6]
    pack $w.lbl -side left

    if {$o(-variable) ne {}} {
        if {![info exists $o(-variable)]} { set $o(-variable) 0 }
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgck_update $w }} $w]
    }

    foreach ww [list $w.box $w.lbl] {
        bind $ww <Button-1>      [list ttkbootstrap::_svgck_toggle $w]
        bind $ww <Enter>         [list ttkbootstrap::_svgck_hover $w 1]
        bind $ww <Leave>         [list ttkbootstrap::_svgck_hover $w 0]
    }
    bind $w <<ThemeChanged>>     [list ttkbootstrap::_svgck_retheme $w]

    _svgck_update $w
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgck
    return $w
}

proc _svgck_gen {w} {
    set ns ::ttkbootstrap::svgck::$w
    array set o [set ${ns}::o]
    set sz [set ${ns}::sz]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set r [expr {$sz / 5}]

    # Unchecked: rounded rect border
    set svg_off "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<rect x='1' y='1' width='[expr {$sz-2}]' height='[expr {$sz-2}]' rx='$r' ry='$r'\
 fill='$bg' stroke='$bdr' stroke-width='2'/></svg>"

    # Checked: filled rect with check mark
    set p1x [expr {$sz * 0.20}]; set p1y [expr {$sz * 0.50}]
    set p2x [expr {$sz * 0.42}]; set p2y [expr {$sz * 0.72}]
    set p3x [expr {$sz * 0.80}]; set p3y [expr {$sz * 0.28}]
    set svg_on "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<rect x='1' y='1' width='[expr {$sz-2}]' height='[expr {$sz-2}]' rx='$r' ry='$r'\
 fill='$hex' stroke='$hex' stroke-width='2'/>\
<polyline points='$p1x,$p1y $p2x,$p2y $p3x,$p3y'\
 fill='none' stroke='$fg' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'/></svg>"

    # Hover unchecked
    set svg_off_h "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<rect x='1' y='1' width='[expr {$sz-2}]' height='[expr {$sz-2}]' rx='$r' ry='$r'\
 fill='$bg' stroke='$hex' stroke-width='2'/></svg>"

    # Hover checked
    set dk [ttkbootstrap::_darken $hex 10]
    set svg_on_h "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<rect x='1' y='1' width='[expr {$sz-2}]' height='[expr {$sz-2}]' rx='$r' ry='$r'\
 fill='$dk' stroke='$dk' stroke-width='2'/>\
<polyline points='$p1x,$p1y $p2x,$p2y $p3x,$p3y'\
 fill='none' stroke='$fg' stroke-width='2.5' stroke-linecap='round' stroke-linejoin='round'/></svg>"

    foreach s {img_off img_on img_off_h img_on_h} { catch { image delete ${w}::$s } }
    image create photo ${w}::img_off   -data $svg_off   -format svg
    image create photo ${w}::img_on    -data $svg_on    -format svg
    image create photo ${w}::img_off_h -data $svg_off_h -format svg
    image create photo ${w}::img_on_h  -data $svg_on_h  -format svg
}

proc _svgck_update {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgck::$w
    array set o [set ${ns}::o]
    set val [expr {$o(-variable) ne {} ? [set $o(-variable)] : 0}]
    set hov [set ${ns}::hover]
    if {$val} {
        $w.box configure -image [expr {$hov ? "${w}::img_on_h" : "${w}::img_on"}]
    } else {
        $w.box configure -image [expr {$hov ? "${w}::img_off_h" : "${w}::img_off"}]
    }
}

proc _svgck_toggle {w} {
    set ns ::ttkbootstrap::svgck::$w
    array set o [set ${ns}::o]
    if {$o(-state) eq "disabled"} return
    if {$o(-variable) ne {}} {
        set cur [set $o(-variable)]
        set $o(-variable) [expr {!$cur}]
    }
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _svgck_hover {w state} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgck::$w
    set ${ns}::hover $state
    _svgck_update $w
}

proc _svgck_retheme {w} {
    if {![winfo exists $w]} return
    _svgck_gen $w
    _svgck_update $w
    $w.lbl configure -foreground [ttkbootstrap::getColor fg]
}

} ;# end namespace ttkbootstrap

# ── SVGRadio ──────────────────────────────────────────────────────────────────
# SVG radio button with filled circle indicator.
#
# USAGE
#   ttkbootstrap::SVGRadio .r1 \
#       -text "Option A" -bootstyle primary -variable ::choice -value "a"
#
namespace eval ttkbootstrap {

proc SVGRadio {w args} {
    array set o {
        -text      ""
        -bootstyle primary
        -variable  {}
        -value     ""
        -command   {}
        -state     normal
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGRadio -bootstyle $o(-bootstyle)

    set ns ::ttkbootstrap::svgrd::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::hover 0

    set sz [ttkbootstrap::_sf 20]
    set ${ns}::sz $sz

    _svgrd_gen $w

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]

    ttk::frame $w
    ttk::label $w.dot -image ${w}::img_off -cursor hand2
    ttk::label $w.lbl -text $o(-text) -font [list $fn $fs] \
        -cursor hand2 -foreground [ttkbootstrap::getColor fg]
    pack $w.dot -side left -padx [ttkbootstrap::_sp2 0 6]
    pack $w.lbl -side left

    if {$o(-variable) ne {}} {
        if {![info exists $o(-variable)]} { set $o(-variable) "" }
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgrd_update $w }} $w]
    }

    foreach ww [list $w.dot $w.lbl] {
        bind $ww <Button-1>      [list ttkbootstrap::_svgrd_select $w]
        bind $ww <Enter>         [list ttkbootstrap::_svgrd_hover $w 1]
        bind $ww <Leave>         [list ttkbootstrap::_svgrd_hover $w 0]
    }
    bind $w <<ThemeChanged>>     [list ttkbootstrap::_svgrd_retheme $w]

    _svgrd_update $w
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgrd
    return $w
}

proc _svgrd_gen {w} {
    set ns ::ttkbootstrap::svgrd::$w
    array set o [set ${ns}::o]
    set sz [set ${ns}::sz]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set fg  [ttkbootstrap::_contrastFg $hex]
    set cx [expr {$sz / 2.0}]; set cy $cx
    set ro [expr {$sz / 2.0 - 1}]
    set ri [expr {$sz / 4.5}]

    set svg_off "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<circle cx='$cx' cy='$cy' r='$ro' fill='$bg' stroke='$bdr' stroke-width='2'/></svg>"

    set svg_on "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<circle cx='$cx' cy='$cy' r='$ro' fill='$hex' stroke='$hex' stroke-width='2'/>\
<circle cx='$cx' cy='$cy' r='$ri' fill='$fg'/></svg>"

    set svg_off_h "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<circle cx='$cx' cy='$cy' r='$ro' fill='$bg' stroke='$hex' stroke-width='2'/></svg>"

    set dk [ttkbootstrap::_darken $hex 10]
    set svg_on_h "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'><rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>\
<circle cx='$cx' cy='$cy' r='$ro' fill='$dk' stroke='$dk' stroke-width='2'/>\
<circle cx='$cx' cy='$cy' r='$ri' fill='$fg'/></svg>"

    foreach s {img_off img_on img_off_h img_on_h} { catch { image delete ${w}::$s } }
    image create photo ${w}::img_off   -data $svg_off   -format svg
    image create photo ${w}::img_on    -data $svg_on    -format svg
    image create photo ${w}::img_off_h -data $svg_off_h -format svg
    image create photo ${w}::img_on_h  -data $svg_on_h  -format svg
}

proc _svgrd_update {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgrd::$w
    array set o [set ${ns}::o]
    set val [expr {$o(-variable) ne {} ? [set $o(-variable)] : ""}]
    set sel [expr {$val eq $o(-value)}]
    set hov [set ${ns}::hover]
    if {$sel} {
        $w.dot configure -image [expr {$hov ? "${w}::img_on_h" : "${w}::img_on"}]
    } else {
        $w.dot configure -image [expr {$hov ? "${w}::img_off_h" : "${w}::img_off"}]
    }
}

proc _svgrd_select {w} {
    set ns ::ttkbootstrap::svgrd::$w
    array set o [set ${ns}::o]
    if {$o(-state) eq "disabled"} return
    if {$o(-variable) ne {}} { set $o(-variable) $o(-value) }
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _svgrd_hover {w state} {
    if {![winfo exists $w]} return
    set ::ttkbootstrap::svgrd::${w}::hover $state
    _svgrd_update $w
}

proc _svgrd_retheme {w} {
    if {![winfo exists $w]} return
    _svgrd_gen $w
    _svgrd_update $w
    $w.lbl configure -foreground [ttkbootstrap::getColor fg]
}

} ;# end namespace ttkbootstrap

# ── SVGEntry ──────────────────────────────────────────────────────────────────
# Entry field with SVG pill-shaped border. Uses a real ttk::entry inside a
# frame that draws an SVG border behind it.
#
# USAGE
#   ttkbootstrap::SVGEntry .e \
#       -bootstyle primary -textvariable ::myvar -width 30
#
namespace eval ttkbootstrap {

proc SVGEntry {w args} {
    array set o {
        -bootstyle  primary
        -textvariable {}
        -width      20
        -state      normal
        -placeholder {}
        -height     0
        -radius     -1
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGEntry -bootstyle $o(-bootstyle)
    if {$o(-height) == 0} {
        set _fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
        set _fs [ttkbootstrap::_sf 12]
        set _ls [font metrics [list $_fn $_fs] -linespace]
        set o(-height) [expr {$_ls + [ttkbootstrap::_sp 12]}]
    }
    # Default shape is a stadium/pill: radius = half the inner height (the SVG
    # border rect is inset 1px, so the inner height is H-2). An explicit
    # -radius still yields a rounded rectangle. capR is how far content must be
    # inset horizontally so it clears the rounded caps.
    if {$o(-radius) < 0} { set o(-radius) [expr {($o(-height) - 2) / 2.0}] }
    set capR [expr {int(ceil($o(-radius)))}]

    set ns ::ttkbootstrap::svge::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::focus 0

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]

    # Compute width first so SVG is generated at correct size. Add room for the
    # two caps (2*capR) so the visible text capacity is preserved on a pill.
    set ew [expr {[font measure [list $fn $fs] "0"] * $o(-width) + [ttkbootstrap::_sp 20] + 2 * $capR}]
    set ${ns}::W $ew
    set ${ns}::H $o(-height)

    set _bg [ttkbootstrap::getColor bg]
    frame $w -highlightthickness 0 -bd 0 -width $ew -height $o(-height) -bg $_bg
    pack propagate $w 0

    # The SVG border image behind the entry — generated at exact widget width
    _svge_gen $w
    label $w.bg -image ${w}::img_n -bd 0 -highlightthickness 0 -bg $_bg
    place $w.bg -x 0 -y 0 -relwidth 1 -relheight 1

    # The actual entry widget — flat, no border, sits on top of the SVG
    set ecmd [list ttk::entry $w.ent -width $o(-width) \
        -font [list $fn $fs]]
    if {$o(-textvariable) ne {}} { lappend ecmd -textvariable $o(-textvariable) }
    if {$o(-state) ne "normal"} { lappend ecmd -state $o(-state) }
    {*}$ecmd
    set _ibg [ttkbootstrap::getColor inputbg]
    catch {
        ttk::style configure flat.TEntry \
            -fieldbackground $_ibg -background $_ibg \
            -bordercolor $_ibg -lightcolor $_ibg -darkcolor $_ibg \
            -borderwidth 0 -relief flat -padding [ttkbootstrap::_sp2 6 4]
        # Flatten the layout so clam's Entry.field (which bakes a 1px border
        # that -borderwidth can't remove) is dropped — only the SVG pill border
        # should show, with no inner rectangle seam.
        ttk::style layout flat.TEntry {
            Entry.padding -sticky nswe -children {
                Entry.textarea -sticky nswe
            }
        }
    }
    $w.ent configure -style "flat.TEntry"
    # Inset horizontally by the cap radius so text clears the rounded caps;
    # pady must exceed the focus stroke (2px) so the opaque field never paints
    # over the border lines.
    pack $w.ent -fill both -expand 1 -padx $capR -pady [ttkbootstrap::_sp 3]

    # Focus highlight
    bind $w.ent <FocusIn>  [list ttkbootstrap::_svge_focus $w 1]
    bind $w.ent <FocusOut> [list ttkbootstrap::_svge_focus $w 0]
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svge_retheme $w]

    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svge
    return $w
}

proc _svge_gen {w} {
    set ns ::ttkbootstrap::svge::$w
    array set o [set ${ns}::o]
    set W [set ${ns}::W]
    set H [set ${ns}::H]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bdr [ttkbootstrap::getColor border]
    set ibg [ttkbootstrap::getColor inputbg]
    set bg  [ttkbootstrap::getColor bg]
    set r $o(-radius)

    # Canvas fill is the PAGE bg so the area outside the rounded shape blends
    # into the page (on a pill the outside-corner area is large; filling it
    # with inputbg would show as lighter "tips" past the caps on dark themes).
    set svg_n "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'><rect x='0' y='0' width='$W' height='$H' fill='$bg'/>\
<rect x='1' y='1' width='[expr {$W-2}]' height='[expr {$H-2}]' rx='$r' ry='$r'\
 fill='$ibg' stroke='$bdr' stroke-width='1.5'/></svg>"

    set svg_f "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'><rect x='0' y='0' width='$W' height='$H' fill='$bg'/>\
<rect x='1' y='1' width='[expr {$W-2}]' height='[expr {$H-2}]' rx='$r' ry='$r'\
 fill='$ibg' stroke='$hex' stroke-width='2'/></svg>"

    foreach s {img_n img_f} { catch { image delete ${w}::$s } }
    image create photo ${w}::img_n -data $svg_n -format svg
    image create photo ${w}::img_f -data $svg_f -format svg
}

proc _svge_focus {w state} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svge::$w
    set ${ns}::focus $state
    $w.bg configure -image [expr {$state ? "${w}::img_f" : "${w}::img_n"}]
}

proc _svge_retheme {w} {
    if {![winfo exists $w]} return
    set bg [ttkbootstrap::getColor bg]
    _svge_gen $w
    set ns ::ttkbootstrap::svge::$w
    set f [set ${ns}::focus]
    $w configure -bg $bg
    $w.bg configure -image [expr {$f ? "${w}::img_f" : "${w}::img_n"}] -bg $bg
    catch {
        set ibg [ttkbootstrap::getColor inputbg]
        ttk::style configure flat.TEntry \
            -fieldbackground $ibg -background $ibg \
            -bordercolor $ibg -lightcolor $ibg -darkcolor $ibg \
            -foreground [ttkbootstrap::getColor fg] \
            -borderwidth 0 -relief flat
    }
}

} ;# end namespace ttkbootstrap

# ── SVGProgress ───────────────────────────────────────────────────────────────
# SVG rounded progress bar.
#
# USAGE
#   ttkbootstrap::SVGProgress .p \
#       -bootstyle success -value 65 -maximum 100 -length 300
#
namespace eval ttkbootstrap {

proc SVGProgress {w args} {
    array set o {
        -bootstyle success
        -value     0
        -maximum   100
        -length    0
        -height    0
        -radius    -1
        -variable  {}
        -offset    -1
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGProgress -bootstyle $o(-bootstyle)
    if {$o(-length) == 0} { set o(-length) [ttkbootstrap::_sp 300] }
    if {$o(-height) == 0} { set o(-height) [ttkbootstrap::_sp 20] }
    if {$o(-radius) < 0} { set o(-radius) [ttkbootstrap::_sp 10] }

    set ns ::ttkbootstrap::svgpb::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    # Use a fixed-size frame so it doesn't expand to fill container
    frame $w -width $o(-length) -height $o(-height) \
        -highlightthickness 0 -bd 0
    pack propagate $w 0

    label $w.img -bd 0 -highlightthickness 0 -bg [ttkbootstrap::getColor bg]
    place $w.img -x 0 -y 0 -relwidth 1 -relheight 1

    if {$o(-variable) ne {}} {
        if {![info exists $o(-variable)]} { set $o(-variable) $o(-value) }
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgpb_redraw $w }} $w]
    }

    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgpb_redraw $w]

    after idle [list ttkbootstrap::_svgpb_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgpb
    return $w
}

proc _svgpb_redraw {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgpb::$w
    array set o [set ${ns}::o]

    set val $o(-value)
    if {$o(-variable) ne {} && [info exists $o(-variable)]} {
        set val [set $o(-variable)]
    }

    set W $o(-length)
    set H $o(-height)
    set r $o(-radius)

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor success] }
    # Track colour: lighter shade of the bootstyle colour (not grey)
    set trk [ttkbootstrap::_lighten $hex 35]

    set pct [expr {$o(-maximum) > 0 ? double($val) / $o(-maximum) : 0.0}]
    if {$pct > 1.0} { set pct 1.0 }
    if {$pct < 0.0} { set pct 0.0 }
    set fillW [expr {int($W * $pct)}]
    if {$fillW < 1 && $pct > 0} { set fillW 1 }

    # Track (light bootstyle background)
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'><rect x='0' y='0' width='$W' height='$H' fill='[ttkbootstrap::getColor bg]'/>"  ;# bgfill_done
    append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$trk'/>"

    # Fill bar — pill-shaped (rounded rect matching track radius)
    set offset $o(-offset)
    if {$fillW > 0} {
        if {$offset >= 0} {
            # Indeterminate mode: sliding pill at offset position
            set fx [expr {int($W * $offset / 100.0)}]
            append svg "<rect x='$fx' y='0' width='$fillW' height='$H' rx='$r' ry='$r' fill='$hex'/>"
        } else {
            # Determinate mode: fill from left with rounded ends
            if {$fillW >= $W} {
                # Full — just draw matching rounded rect
                append svg "<rect x='0' y='0' width='$fillW' height='$H' rx='$r' ry='$r' fill='$hex'/>"
            } else {
                # Partial — rounded left end, track covers right overhang
                # Draw fill as tall rounded rect, then track rect covers the right side
                append svg "<rect x='0' y='0' width='[expr {max($fillW, $r * 2)}]' height='$H' rx='$r' ry='$r' fill='$hex'/>"
                if {$fillW > $r * 2} {
                    # Fill the gap between rounded end and actual fill width
                    append svg "<rect x='$r' y='0' width='[expr {$fillW - $r}]' height='$H' fill='$hex'/>"
                }
            }
        }
    }
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w.img configure -image ${w}::img -bg [ttkbootstrap::getColor bg]
}

proc SVGProgress_set {w value} {
    set ns ::ttkbootstrap::svgpb::$w
    array set o [set ${ns}::o]
    set o(-value) $value
    set ${ns}::o [array get o]
    _svgpb_redraw $w
}

} ;# end namespace ttkbootstrap

# ── SVGScale ──────────────────────────────────────────────────────────────────
# SVG slider/scale widget with rounded track and circle thumb.
#
# USAGE
#   ttkbootstrap::SVGScale .sc \
#       -from 0 -to 100 -bootstyle info -variable ::val -length 300
#
namespace eval ttkbootstrap {

proc SVGScale {w args} {
    array set o {
        -from      0
        -to        100
        -bootstyle primary
        -variable  {}
        -length    0
        -height    0
        -command   {}
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGScale -bootstyle $o(-bootstyle)
    if {$o(-from) > $o(-to)} {
        ttkbootstrap::_warn "SVGScale $w: -from ($o(-from)) > -to ($o(-to)); swapping them"
        lassign [list $o(-to) $o(-from)] o(-from) o(-to)
    } elseif {$o(-from) == $o(-to)} {
        ttkbootstrap::_warn "SVGScale $w: -from equals -to ($o(-from)); widening -to by 1"
        set o(-to) [expr {$o(-from) + 1}]
    }
    if {$o(-length) == 0} { set o(-length) [ttkbootstrap::_sp 300] }
    if {$o(-height) == 0} { set o(-height) [ttkbootstrap::_sp 30] }

    set ns ::ttkbootstrap::svgsc::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::dragging 0

    if {$o(-variable) ne {}} {
        if {![info exists $o(-variable)]} {
            set $o(-variable) [expr {($o(-from) + $o(-to)) / 2.0}]
        }
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgsc_redraw $w }} $w]
    }

    canvas $w -width $o(-length) -height $o(-height) \
        -highlightthickness 0 -bd 0 -cursor hand2 \
        -bg [ttkbootstrap::getColor bg]

    bind $w <ButtonPress-1>   [list ttkbootstrap::_svgsc_click $w %x]
    bind $w <B1-Motion>       [list ttkbootstrap::_svgsc_drag  $w %x]
    bind $w <ButtonRelease-1> [list ttkbootstrap::_svgsc_endrag $w]
    bind $w <Configure>       [list ttkbootstrap::_svgsc_redraw $w]
    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgsc_redraw $w]

    after idle [list ttkbootstrap::_svgsc_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsc
    return $w
}

proc _svgsc_redraw {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsc::$w
    array set o [set ${ns}::o]

    set val $o(-from)
    if {$o(-variable) ne {} && [info exists $o(-variable)]} {
        set val [set $o(-variable)]
    }

    set W [winfo width $w]; set H [winfo height $w]
    if {$W < 10} { set W $o(-length) }
    set bg [ttkbootstrap::getColor bg]
    $w configure -bg $bg

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set trk [ttkbootstrap::_lighten [ttkbootstrap::getColor secondary] 30]

    set th [ttkbootstrap::_sp 6] ;# track height
    set thumbR [ttkbootstrap::_sp 8] ;# thumb radius
    set pad [expr {$thumbR + [ttkbootstrap::_sp 2]}]
    set trackW [expr {$W - $pad*2}]
    set cy [expr {$H / 2}]
    set ty [expr {$cy - $th/2}]

    set range [expr {double($o(-to) - $o(-from))}]
    set pct [expr {$range > 0 ? ($val - $o(-from)) / $range : 0.0}]
    if {$pct < 0} {set pct 0}; if {$pct > 1} {set pct 1}
    set thumbX [expr {$pad + int($trackW * $pct)}]

    $w delete all

    # Track background
    set tr [expr {$th / 2}]
    set x1 $pad; set x2 [expr {$pad + $trackW}]
    # SVG would be cleaner but canvas ovals work well for this
    $w create oval $x1 [expr {$cy-$tr}] [expr {$x1+$th}] [expr {$cy+$tr}] \
        -fill $trk -outline $trk
    $w create oval [expr {$x2-$th}] [expr {$cy-$tr}] $x2 [expr {$cy+$tr}] \
        -fill $trk -outline $trk
    $w create rectangle [expr {$x1+$tr}] [expr {$cy-$tr}] [expr {$x2-$tr}] [expr {$cy+$tr}] \
        -fill $trk -outline $trk

    # Track fill (left of thumb)
    if {$thumbX > $x1} {
        $w create oval $x1 [expr {$cy-$tr}] [expr {$x1+$th}] [expr {$cy+$tr}] \
            -fill $hex -outline $hex
        if {$thumbX > [expr {$x1+$tr}]} {
            $w create rectangle [expr {$x1+$tr}] [expr {$cy-$tr}] $thumbX [expr {$cy+$tr}] \
                -fill $hex -outline $hex
        }
    }

    # Thumb circle — use SVG for crisp anti-aliased circle
    set tsz [expr {$thumbR * 2 + 4}]
    set fg [ttkbootstrap::_contrastFg $hex]
    set svg_thumb "<svg xmlns='http://www.w3.org/2000/svg' width='$tsz' height='$tsz'><rect x='0' y='0' width='$tsz' height='$tsz' fill='$bg'/>\
<circle cx='[expr {$tsz/2}]' cy='[expr {$tsz/2}]' r='$thumbR'\
 fill='$hex' stroke='white' stroke-width='2'/></svg>"
    catch { image delete ${w}::thumb }
    image create photo ${w}::thumb -data $svg_thumb -format svg
    $w create image $thumbX $cy -image ${w}::thumb -anchor center -tags thumb
}

proc _svgsc_click {w x} {
    set ns ::ttkbootstrap::svgsc::$w
    set ${ns}::dragging 1
    _svgsc_set_from_x $w $x
}

proc _svgsc_drag {w x} {
    set ns ::ttkbootstrap::svgsc::$w
    if {![set ${ns}::dragging]} return
    _svgsc_set_from_x $w $x
}

proc _svgsc_endrag {w} {
    set ns ::ttkbootstrap::svgsc::$w
    set ${ns}::dragging 0
}

proc _svgsc_set_from_x {w x} {
    set ns ::ttkbootstrap::svgsc::$w
    array set o [set ${ns}::o]
    set W [winfo width $w]
    set pad [expr {[ttkbootstrap::_sp 8] + [ttkbootstrap::_sp 2]}]
    set trackW [expr {$W - $pad*2}]
    set pct [expr {double($x - $pad) / $trackW}]
    if {$pct < 0} {set pct 0}; if {$pct > 1} {set pct 1}
    set val [expr {$o(-from) + $pct * ($o(-to) - $o(-from))}]
    set val [expr {int($val + 0.5)}]
    if {$o(-variable) ne {}} {
        set $o(-variable) $val
    }
    if {$o(-command) ne {}} {
        uplevel #0 $o(-command) $val
    }
}

} ;# end namespace ttkbootstrap

# ── SVGMeter ──────────────────────────────────────────────────────────────────
# Circular gauge: SVG arc for the ring, ttk::labels for text overlay.
# No text in the SVG avoids font-name escaping issues.
#
# USAGE
#   ttkbootstrap::SVGMeter .m \
#       -bootstyle success -amountused 72 -amounttotal 100 \
#       -metersize 180 -subtext "CPU" -textright "%" -interactive 1
#
namespace eval ttkbootstrap {

proc SVGMeter {w args} {
    array set o {
        -bootstyle      primary
        -amountused     0
        -amounttotal    100
        -metersize      0
        -meterthickness 0
        -metertype      arc
        -subtext        ""
        -textright      ""
        -showvalue      1
        -interactive    0
        -command        {}
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGMeter -bootstyle $o(-bootstyle)
    if {$o(-amounttotal) <= 0} {
        ttkbootstrap::_warn "SVGMeter $w: -amounttotal must be > 0 (got $o(-amounttotal)); using 100"
        set o(-amounttotal) 100
    }

    set ns ::ttkbootstrap::svgm::$w
    namespace eval $ns {}
    if {$o(-metersize) == 0} { set o(-metersize) [ttkbootstrap::_sp 180] }
    if {$o(-meterthickness) == 0} { set o(-meterthickness) [ttkbootstrap::_sp 10] }
    set ${ns}::o [array get o]

    set sz $o(-metersize)

    # Container frame
    ttk::frame $w -width $sz -height $sz
    pack propagate $w 0

    # SVG arc image (no text — text drawn by plain Tk labels)
    label $w.arc -anchor center -bd 0 -highlightthickness 0
    place $w.arc -relx 0.5 -rely 0.5 -anchor center

    # Font sizes proportional to meter — use raw pixel size divided by
    # the DPI scale factor to get the point size, avoiding double-scaling
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set scale_factor [expr {[tk scaling] / 1.333333}]
    if {$scale_factor < 0.5} { set scale_factor 1.0 }
    set fsl [expr {int($sz / (6.5 * $scale_factor))}]
    set fss [expr {int($sz / (15.0 * $scale_factor))}]
    if {$fsl < 10} { set fsl 10 }
    if {$fss < 7}  { set fss 7 }
    set bg [ttkbootstrap::getColor bg]

    label $w.val -text "" \
        -font [list $fn $fsl bold] \
        -fg [ttkbootstrap::getColor fg] \
        -bg $bg -bd 0 -highlightthickness 0 \
        -anchor center
    place $w.val -relx 0.5 -rely 0.44 -anchor center

    # Subtext label
    label $w.sub -text $o(-subtext) \
        -font [list $fn $fss] \
        -fg [ttkbootstrap::getColor fg] \
        -bg $bg -bd 0 -highlightthickness 0 \
        -anchor center
    place $w.sub -relx 0.5 -rely 0.60 -anchor center

    _svgm_redraw $w

    if {$o(-interactive)} {
        foreach child [list $w $w.arc $w.val $w.sub] {
            bind $child <ButtonPress-1> [list ttkbootstrap::_svgm_start $w %Y]
            bind $child <B1-Motion>     [list ttkbootstrap::_svgm_drag  $w %Y]
            catch { $child configure -cursor hand2 }
        }
    }
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgm_retheme $w]

    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgm
    return $w
}

proc _svgm_redraw {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgm::$w
    array set o [set ${ns}::o]

    set sz $o(-metersize)
    set thick $o(-meterthickness)
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set trk [ttkbootstrap::_lighten [ttkbootstrap::getColor secondary] 25]

    set pct [expr {$o(-amounttotal) > 0 ? double($o(-amountused)) / $o(-amounttotal) : 0.0}]
    if {$pct > 1.0} {set pct 1.0}
    if {$pct < 0.0} {set pct 0.0}

    set cx [expr {$sz / 2.0}]
    set cy $cx
    set r  [expr {$cx - $thick / 2.0 - 4}]

    # Build SVG — arc only, no text
    set bg [ttkbootstrap::getColor bg]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>"
    append svg "<rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>"
    append svg "<circle cx='$cx' cy='$cy' r='$r' fill='none' stroke='$trk' stroke-width='$thick' stroke-linecap='round'/>"

    if {$pct > 0.001} {
        set pi 3.14159265358979
        set a1 [expr {-90.0 * $pi / 180.0}]
        set a2 [expr {(-90.0 + 360.0 * $pct) * $pi / 180.0}]
        set x1 [expr {$cx + $r * cos($a1)}]
        set y1 [expr {$cy + $r * sin($a1)}]
        set x2 [expr {$cx + $r * cos($a2)}]
        set y2 [expr {$cy + $r * sin($a2)}]
        set la [expr {$pct > 0.5 ? 1 : 0}]
        append svg "<path d='M $x1 $y1 A $r $r 0 $la 1 $x2 $y2' fill='none' stroke='$hex' stroke-width='$thick' stroke-linecap='round'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::arc_img }
    image create photo ${w}::arc_img -data $svg -format {svg}
    $w.arc configure -image ${w}::arc_img

    # Update label backgrounds to match theme bg (prevents white box)
    set bg [ttkbootstrap::getColor bg]
    $w.arc configure -bg $bg
    $w.val configure -bg $bg
    $w.sub configure -bg $bg

    # Update value text
    if {$o(-showvalue)} {
        $w.val configure -text "[expr {int($o(-amountused))}]$o(-textright)"
    } else {
        $w.val configure -text ""
    }
    $w.sub configure -text $o(-subtext)
}

proc _svgm_retheme {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgm::$w
    array set o [set ${ns}::o]
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fg [ttkbootstrap::getColor fg]
    set bg [ttkbootstrap::getColor bg]
    set sz $o(-metersize)
    set scale_factor [expr {[tk scaling] / 1.333333}]
    if {$scale_factor < 0.5} { set scale_factor 1.0 }
    set fsl [expr {int($sz / (6.5 * $scale_factor))}]
    set fss [expr {int($sz / (15.0 * $scale_factor))}]
    if {$fsl < 10} { set fsl 10 }
    if {$fss < 7}  { set fss 7 }
    $w.val configure -fg $fg -bg $bg -font [list $fn $fsl bold]
    $w.sub configure -fg $fg -bg $bg -font [list $fn $fss]
    $w.arc configure -bg $bg
    _svgm_redraw $w
}

proc _svgm_start {w Y} {
    set ns ::ttkbootstrap::svgm::$w
    set ${ns}::last_y $Y
}

proc _svgm_drag {w Y} {
    set ns ::ttkbootstrap::svgm::$w
    array set o [set ${ns}::o]
    set last [set ${ns}::last_y]
    set dy [expr {$last - $Y}]
    set ${ns}::last_y $Y
    set delta [expr {$dy * $o(-amounttotal) / $o(-metersize)}]
    set newval [expr {$o(-amountused) + $delta}]
    if {$newval < 0} {set newval 0}
    if {$newval > $o(-amounttotal)} {set newval $o(-amounttotal)}
    set o(-amountused) [expr {int($newval + 0.5)}]
    set ${ns}::o [array get o]
    _svgm_redraw $w
    if {$o(-command) ne {}} {
        uplevel #0 $o(-command) $o(-amountused)
    }
}

} ;# end namespace ttkbootstrap

# ── SVGStepProgress ───────────────────────────────────────────────────────────
# Horizontal step indicator rendered with SVG circles and connector lines.
# Crisp rendering at any DPI. Same API as StepProgress.
#
# USAGE
#   ttkbootstrap::SVGStepProgress .sp \
#       -steps {"Account" "Profile" "Settings" "Done"} \
#       -current 1 -bootstyle primary
#   pack .sp -fill x
#
#   ttkbootstrap::SVGStepProgress::next .sp
#   ttkbootstrap::SVGStepProgress::prev .sp
#   ttkbootstrap::SVGStepProgress::set  .sp 2
#
namespace eval ttkbootstrap {

proc SVGStepProgress {w args} {
    array set o {
        -steps     {}
        -current   0
        -bootstyle primary
        -complete  success
        -size      0
        -command   {}
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGStepProgress -bootstyle $o(-bootstyle)

    set ns ::ttkbootstrap::svgsp::$w
    namespace eval $ns {}

    if {$o(-size) == 0} { set o(-size) [ttkbootstrap::_sp 28] }
    set ${ns}::o [array get o]

    set sz $o(-size)
    set H [expr {$sz + [ttkbootstrap::_sp 40]}]

    canvas $w -highlightthickness 0 -bd 0 -height $H         -bg [ttkbootstrap::getColor bg]

    bind $w <Configure>      [list ttkbootstrap::_svgsp_redraw $w]
    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgsp_redraw $w]

    after idle [list ttkbootstrap::_svgsp_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsp
    return $w
}

proc _svgsp_redraw {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsp::$w
    array set o [set ${ns}::o]

    set steps $o(-steps)
    set nsteps [llength $steps]
    if {$nsteps < 2} return

    set cur $o(-current)
    set sz $o(-size)
    set r  [expr {$sz / 2.0}]

    set W [winfo width $w]
    if {$W < 50} { set W [ttkbootstrap::_sp 400] }
    set H [expr {$sz + [ttkbootstrap::_sp 40]}]

    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]
    set bdr [ttkbootstrap::getColor border]
    set hexA [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hexA eq ""} { set hexA [ttkbootstrap::getColor primary] }
    set hexC [ttkbootstrap::getColor $o(-complete)]
    if {$hexC eq ""} { set hexC [ttkbootstrap::getColor success] }
    set fgA [ttkbootstrap::_contrastFg $hexA]
    set fgC [ttkbootstrap::_contrastFg $hexC]

    $w delete all
    $w configure -bg $bg -height $H

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set numfont [list $fn [ttkbootstrap::_sf 11] bold]
    set lblfont [list $fn [ttkbootstrap::_sf 10]]

    set sidepad [ttkbootstrap::_sp 40]
    set topmargin [ttkbootstrap::_sp 6]
    set spacing [expr {($W - 2.0*$sidepad) / max($nsteps - 1, 1)}]
    set cy [expr {$r + $topmargin}]

    # Connector lines
    for {set i 0} {$i < $nsteps - 1} {incr i} {
        set x1 [expr {$sidepad + $i * $spacing + $r}]
        set x2 [expr {$sidepad + ($i+1) * $spacing - $r}]
        set lnCol [expr {$i < $cur ? $hexC : $bdr}]
        $w create line $x1 $cy $x2 $cy             -fill $lnCol -width [ttkbootstrap::_sp 3] -capstyle round
    }

    # Circles with SVG for crisp rendering, then text on top via canvas text
    for {set i 0} {$i < $nsteps} {incr i} {
        set cx [expr {$sidepad + $i * $spacing}]
        set label [lindex $steps $i]

        if {$i < $cur} {
            set fill $hexC; set stroke $hexC; set txtFg $fgC
            set numTxt "✓"
        } elseif {$i == $cur} {
            set fill $hexA; set stroke $hexA; set txtFg $fgA
            set numTxt [expr {$i + 1}]
        } else {
            set fill $bg; set stroke $bdr; set txtFg $fg
            set numTxt [expr {$i + 1}]
        }

        # SVG circle image
        set csvg "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>"
        append csvg "<rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>"
        append csvg "<circle cx='[expr {$sz/2.0}]' cy='[expr {$sz/2.0}]' r='[expr {$sz/2.0 - 1}]' fill='$fill' stroke='$stroke' stroke-width='2'/>"
        append csvg "</svg>"
        catch { image delete ${w}::c$i }
        image create photo ${w}::c$i -data $csvg -format {svg}
        $w create image $cx $cy -image ${w}::c$i -anchor center

        # Number text on top of circle
        $w create text $cx $cy -text $numTxt -fill $txtFg             -font $numfont -anchor center

        # Step label below circle — colour changes with state
        set lbly [expr {$cy + $r + [ttkbootstrap::_sp 8]}]
        if {$i < $cur} {
            set lblCol $hexC
        } elseif {$i == $cur} {
            set lblCol $hexA
        } else {
            set lblCol $fg
        }
        $w create text $cx $lbly -text $label -fill $lblCol -font $lblfont -anchor n
    }
}

proc _svgsp_click {w x} {
    set ns ::ttkbootstrap::svgsp::$w
    array set o [set ${ns}::o]
    set nsteps [llength $o(-steps)]
    set W [winfo width $w]
    set pad [expr {$o(-size) / 2.0 + [ttkbootstrap::_sp 10]}]
    set spacing [expr {($W - 2.0*$pad) / ($nsteps - 1)}]

    # Find closest step
    set best 0
    set bestDist 99999
    for {set i 0} {$i < $nsteps} {incr i} {
        set cx [expr {$pad + $i * $spacing}]
        set dist [expr {abs($x - $cx)}]
        if {$dist < $bestDist} { set bestDist $dist; set best $i }
    }
    SVGStepProgress::goto $w $best
}

namespace eval SVGStepProgress {
    proc goto {w idx} {
        ::set ns ::ttkbootstrap::svgsp::$w
        array set o [::set ${ns}::o]
        ::set max [expr {[llength $o(-steps)] - 1}]
        if {$idx < 0} { ::set idx 0 }
        if {$idx > $max} { ::set idx $max }
        ::set o(-current) $idx
        ::set ${ns}::o [array get o]
        ttkbootstrap::_svgsp_redraw $w
        if {$o(-command) ne {}} { uplevel #0 $o(-command) $idx }
    }

    proc next {w} {
        ::set ns ::ttkbootstrap::svgsp::$w
        array set o [::set ${ns}::o]
        goto $w [expr {$o(-current) + 1}]
    }

    proc prev {w} {
        ::set ns ::ttkbootstrap::svgsp::$w
        array set o [::set ${ns}::o]
        goto $w [expr {$o(-current) - 1}]
    }

    proc current {w} {
        ::set ns ::ttkbootstrap::svgsp::$w
        array set o [::set ${ns}::o]
        return $o(-current)
    }
}

} ;# end namespace ttkbootstrap

# ── SVGFloodgauge ─────────────────────────────────────────────────────────────
# Progressbar with text overlay. SVG track + fill, label for text.
namespace eval ttkbootstrap {

proc SVGFloodgauge {w args} {
    array set o {
        -bootstyle primary -value 0 -maximum 100
        -text "" -mask "" -width 0 -height 0
        -orient horizontal -radius -1 -variable {}
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGFloodgauge -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgfg::$w
    namespace eval $ns {}
    if {$o(-width)  == 0} { set o(-width)  [ttkbootstrap::_sp 300] }
    if {$o(-height) == 0} { set o(-height) [ttkbootstrap::_sp 40] }
    if {$o(-radius) < 0} { set o(-radius) [ttkbootstrap::_sp 8] }
    set ${ns}::o [array get o]

    frame $w -width $o(-width) -height $o(-height) -highlightthickness 0 -bd 0         -bg [ttkbootstrap::getColor bg]
    pack propagate $w 0

    label $w.bg -bd 0 -highlightthickness 0 -bg [ttkbootstrap::getColor bg]
    place $w.bg -x 0 -y 0 -relwidth 1 -relheight 1

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]
    label $w.txt -text "" -bd 0 -highlightthickness 0 \
        -font [list $fn $fs bold] -bg [ttkbootstrap::getColor bg]
    place $w.txt -relx 0.5 -rely 0.5 -anchor center

    if {$o(-variable) ne {}} {
        if {![info exists $o(-variable)]} { set $o(-variable) $o(-value) }
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgfg_redraw $w }} $w]
    }
    _svgfg_redraw $w
    bind $w <Configure>      [list ttkbootstrap::_svgfg_redraw $w]
    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgfg_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgfg
    return $w
}

proc _svgfg_redraw {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgfg::$w
    array set o [set ${ns}::o]
    set val $o(-value)
    if {$o(-variable) ne {} && [info exists $o(-variable)]} { set val [set $o(-variable)] }

    set W $o(-width); set H $o(-height); set r $o(-radius)
    set ww [winfo width $w]; if {$ww > 10} { set W $ww }
    set hh [winfo height $w]; if {$hh > 10} { set H $hh }

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    # Track: very pale version of bootstyle colour (not grey)
    set trk [ttkbootstrap::_lighten $hex 40]
    set fgC [ttkbootstrap::_contrastFg $hex]
    set bg  [ttkbootstrap::getColor bg]

    set pct [expr {$o(-maximum) > 0 ? double($val) / $o(-maximum) : 0.0}]
    if {$pct > 1} {set pct 1}; if {$pct < 0} {set pct 0}
    set fillW [expr {int($W * $pct)}]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'><rect x='0' y='0' width='$W' height='$H' fill='$bg'/>"  ;# bgfill_done
    append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$trk'/>"
    if {$fillW > 0} {
        append svg "<defs><clipPath id='fgc'><rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r'/></clipPath></defs>"
        append svg "<rect x='0' y='0' width='$fillW' height='$H' fill='$hex' clip-path='url(#fgc)'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w configure -bg $bg
    $w.bg configure -image ${w}::img -bg $bg

    set txt $o(-text)
    if {$o(-mask) ne ""} { set txt [format $o(-mask) $val] }
    set txtFg [expr {$pct > 0.5 ? $fgC : [ttkbootstrap::getColor fg]}]
    set txtBg [expr {$pct > 0.5 ? $hex : $trk}]
    $w.txt configure -text $txt -fg $txtFg -bg $txtBg
}

proc SVGFloodgauge_set {w value} {
    set ns ::ttkbootstrap::svgfg::$w
    array set o [set ${ns}::o]
    set o(-value) $value
    set ${ns}::o [array get o]
    _svgfg_redraw $w
}

} ;# end namespace ttkbootstrap

# ── SVGBadge ──────────────────────────────────────────────────────────────────
# Small coloured pill label. SVG pill background + Tk label for text.
namespace eval ttkbootstrap {

proc SVGBadge {w args} {
    array set o {-text "" -bootstyle danger}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGBadge -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgbg::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 11]
    set font [list $fn $fs bold]
    set ${ns}::font $font

    set tw [font measure $font $o(-text)]
    set th [font metrics $font -linespace]
    set W [expr {$tw + [ttkbootstrap::_sp 18]}]
    set H [expr {$th + [ttkbootstrap::_sp 8]}]
    set ${ns}::W $W; set ${ns}::H $H

    _svgbg_gen $w

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor danger] }
    set fg [ttkbootstrap::_contrastFg $hex]

    # Single label: SVG pill as background image, text on top via -compound
    label $w -image ${w}::img -text $o(-text) -compound center \
        -font $font -fg $fg -bd 0 -highlightthickness 0 \
        -bg [ttkbootstrap::getColor bg]

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgbg_retheme $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgbg
    return $w
}

proc _svgbg_gen {w} {
    set ns ::ttkbootstrap::svgbg::$w
    array set o [set ${ns}::o]
    set W [set ${ns}::W]; set H [set ${ns}::H]

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor danger] }
    set r [expr {$H / 2}]
    set bg [ttkbootstrap::getColor bg]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>"
    append svg "<rect x='0' y='0' width='$W' height='$H' fill='$bg'/>"
    append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$hex'/>"
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
}

proc _svgbg_retheme {w} {
    if {![winfo exists $w]} return
    _svgbg_gen $w
    set ns ::ttkbootstrap::svgbg::$w
    array set o [set ${ns}::o]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor danger] }
    set fg [ttkbootstrap::_contrastFg $hex]
    $w configure -image ${w}::img -fg $fg -bg [ttkbootstrap::getColor bg]
}

proc SVGBadge_set {w text} {
    set ns ::ttkbootstrap::svgbg::$w
    array set o [set ${ns}::o]
    set o(-text) $text; set ${ns}::o [array get o]
    # Recalculate size for new text
    set font [set ${ns}::font]
    set tw [font measure $font $text]
    set th [font metrics $font -linespace]
    set ${ns}::W [expr {$tw + [ttkbootstrap::_sp 18]}]
    set ${ns}::H [expr {$th + [ttkbootstrap::_sp 8]}]
    _svgbg_gen $w
    $w configure -image ${w}::img -text $text
}

} ;# end namespace ttkbootstrap

# ── SVGRatingBar ──────────────────────────────────────────────────────────────
# Clickable star rating widget rendered in SVG.
#
# USAGE
#   ttkbootstrap::SVGRatingBar .r \
#       -variable ::rating -maximum 5 -bootstyle warning \
#       -command { puts "rated $::rating" }
#
namespace eval ttkbootstrap {

proc SVGRatingBar {w args} {
    array set o {
        -variable  {}
        -value     0
        -maximum   5
        -bootstyle warning
        -size      0
        -readonly  0
        -command   {}
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGRatingBar -bootstyle $o(-bootstyle)

    set ns ::ttkbootstrap::svgrb::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    if {$o(-size) == 0} { set o(-size) [ttkbootstrap::_sp 24] }
    set ${ns}::hover -1

    if {$o(-variable) ne {}} {
        if {![info exists $o(-variable)]} { set $o(-variable) $o(-value) }
        trace add variable $o(-variable) write \
            [list apply {{w args} { ttkbootstrap::_svgrb_redraw $w }} $w]
    }

    label $w -bd 0 -highlightthickness 0 \
        -bg [ttkbootstrap::getColor bg] \
        -cursor [expr {$o(-readonly) ? "" : "hand2"}]

    _svgrb_redraw $w
    if {!$o(-readonly)} {
        bind $w <Button-1> [list ttkbootstrap::_svgrb_click $w %x]
        bind $w <Motion>   [list ttkbootstrap::_svgrb_motion $w %x]
        bind $w <Leave>    [list ttkbootstrap::_svgrb_leave $w]
    }
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgrb_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgrb
    return $w
}

proc _svgrb_redraw {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgrb::$w
    array set o [set ${ns}::o]
    set hov [set ${ns}::hover]

    set val $o(-value)
    if {$o(-variable) ne {} && [info exists $o(-variable)]} { set val [set $o(-variable)] }

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor warning] }
    set bg  [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]

    set sz $o(-size)
    set gap 4
    set n $o(-maximum)
    set W [expr {$n * ($sz + $gap)}]
    set H $sz

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>"

    for {set i 0} {$i < $n} {incr i} {
        set cx [expr {$i * ($sz + $gap) + $sz / 2.0}]
        set cy [expr {$sz / 2.0}]
        set r  [expr {$sz / 2.0 - 2}]
        # Star path (5-point)
        set pts ""
        for {set j 0} {$j < 10} {incr j} {
            set angle [expr {-90 + $j * 36.0}]
            set rad   [expr {$angle * 3.14159265 / 180.0}]
            set rr    [expr {$j % 2 == 0 ? $r : $r * 0.4}]
            set px    [expr {$cx + $rr * cos($rad)}]
            set py    [expr {$cy + $rr * sin($rad)}]
            append pts "$px,$py "
        }

        set filled [expr {($i + 1) <= $val}]
        set hovered [expr {$hov >= 0 && ($i + 1) <= ($hov + 1)}]

        if {$filled || $hovered} {
            set fill $hex
        } else {
            set fill $bdr
        }
        append svg "<polygon points='$pts' fill='$fill'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w configure -image ${w}::img -bg $bg
}

proc _svgrb_click {w x} {
    set ns ::ttkbootstrap::svgrb::$w
    array set o [set ${ns}::o]
    set sz $o(-size); set gap 4
    set idx [expr {int($x / ($sz + $gap)) + 1}]
    if {$idx > $o(-maximum)} { set idx $o(-maximum) }
    if {$o(-variable) ne {}} { set $o(-variable) $idx }
    set o(-value) $idx
    set ${ns}::o [array get o]
    _svgrb_redraw $w
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

proc _svgrb_motion {w x} {
    set ns ::ttkbootstrap::svgrb::$w
    array set o [set ${ns}::o]
    set sz $o(-size); set gap 4
    set idx [expr {int($x / ($sz + $gap))}]
    if {$idx >= $o(-maximum)} { set idx [expr {$o(-maximum) - 1}] }
    if {[set ${ns}::hover] != $idx} {
        set ${ns}::hover $idx
        _svgrb_redraw $w
    }
}

proc _svgrb_leave {w} {
    set ns ::ttkbootstrap::svgrb::$w
    set ${ns}::hover -1
    _svgrb_redraw $w
}

} ;# end namespace ttkbootstrap

# ── SVGSparkLine ──────────────────────────────────────────────────────────────
# Inline mini-chart rendered in SVG — line or bar type.
#
# USAGE
#   ttkbootstrap::SVGSparkLine .sl \
#       -data {12 34 28 45 39 52 61} -bootstyle primary \
#       -width 100 -height 28 -type line
#
namespace eval ttkbootstrap {

proc SVGSparkLine {w args} {
    array set o {
        -data      {}
        -bootstyle primary
        -width     0
        -height    0
        -type      line
        -filled    1
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGSparkLine -bootstyle $o(-bootstyle)

    set ns ::ttkbootstrap::svgsl::$w
    namespace eval $ns {}
    if {$o(-width)  == 0} { set o(-width)  [ttkbootstrap::_sp 100] }
    if {$o(-height) == 0} { set o(-height) [ttkbootstrap::_sp 28] }
    set ${ns}::o [array get o]

    label $w -bd 0 -highlightthickness 0 -bg [ttkbootstrap::getColor bg]
    _svgsl_redraw $w
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgsl_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsl
    return $w
}

proc _svgsl_redraw {w args} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsl::$w
    array set o [set ${ns}::o]

    set data $o(-data)
    set n [llength $data]
    if {$n < 2} return

    set W $o(-width); set H $o(-height)
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor bg]
    set lt [ttkbootstrap::_lighten $hex 30]

    set dmin [lindex [lsort -real $data] 0]
    set dmax [lindex [lsort -real $data] end]
    set range [expr {$dmax - $dmin}]
    if {$range < 0.001} { set range 1 }

    set pad 2
    set usableW [expr {$W - $pad * 2}]
    set usableH [expr {$H - $pad * 2}]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'><rect x='0' y='0' width='$W' height='$H' fill='$bg'/>"  ;# bgfill_done

    if {$o(-type) eq "bar"} {
        set bw [expr {$usableW / double($n) - 1}]
        if {$bw < 2} { set bw 2 }
        for {set i 0} {$i < $n} {incr i} {
            set v [lindex $data $i]
            set bh [expr {$usableH * ($v - $dmin) / $range}]
            if {$bh < 1} { set bh 1 }
            set x [expr {$pad + $i * ($bw + 1)}]
            set y [expr {$H - $pad - $bh}]
            append svg "<rect x='$x' y='$y' width='$bw' height='$bh' rx='1' fill='$hex'/>"
        }
    } else {
        # Line chart
        set pts ""
        set polyPts ""
        for {set i 0} {$i < $n} {incr i} {
            set v [lindex $data $i]
            set x [expr {$pad + $i * $usableW / double($n - 1)}]
            set y [expr {$H - $pad - $usableH * ($v - $dmin) / $range}]
            append pts "$x,$y "
            append polyPts "$x,$y "
        }
        if {$o(-filled)} {
            set x0 [expr {$pad}]
            set xn [expr {$pad + $usableW}]
            set bot [expr {$H - $pad}]
            append svg "<polygon points='$x0,$bot $polyPts $xn,$bot' fill='$lt' opacity='0.4'/>"
        }
        append svg "<polyline points='$pts' fill='none' stroke='$hex' stroke-width='2' stroke-linejoin='round' stroke-linecap='round'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w configure -image ${w}::img -bg $bg
}

proc SVGSparkLine_set {w data} {
    set ns ::ttkbootstrap::svgsl::$w
    array set o [set ${ns}::o]
    set o(-data) $data
    set ${ns}::o [array get o]
    _svgsl_redraw $w
}

proc SVGSparkLine_push {w value {maxpoints 20}} {
    set ns ::ttkbootstrap::svgsl::$w
    array set o [set ${ns}::o]
    lappend o(-data) $value
    if {[llength $o(-data)] > $maxpoints} {
        set o(-data) [lrange $o(-data) end-[expr {$maxpoints-1}] end]
    }
    set ${ns}::o [array get o]
    _svgsl_redraw $w
}

} ;# end namespace ttkbootstrap

# ── SVGScrollbar ──────────────────────────────────────────────────────────────
# Vertical or horizontal scrollbar with SVG pill-shaped thumb on SVG track.
# Attach to a widget via -yscrollcommand / -xscrollcommand.
#
# USAGE
#   ttkbootstrap::SVGScrollbar .sb -orient vertical -bootstyle primary \
#       -command {.text yview}
#   .text configure -yscrollcommand {ttkbootstrap::SVGScrollbar_set .sb}
#
namespace eval ttkbootstrap {

proc SVGScrollbar {w args} {
    array set o {-orient vertical -bootstyle primary -command {} -width 0}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGScrollbar -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgsb::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::first 0.0
    set ${ns}::last 1.0
    if {$o(-width) == 0} { set o(-width) [ttkbootstrap::_sp 12] }
    set ${ns}::dragging 0

    if {$o(-orient) eq "vertical"} {
        canvas $w -width $o(-width) -highlightthickness 0 -bd 0 \
            -bg [ttkbootstrap::getColor bg]
    } else {
        canvas $w -height $o(-width) -highlightthickness 0 -bd 0 \
            -bg [ttkbootstrap::getColor bg]
    }
    bind $w <Configure>       [list ttkbootstrap::_svgsb_draw $w]
    bind $w <ButtonPress-1>   [list ttkbootstrap::_svgsb_press $w %x %y]
    bind $w <B1-Motion>       [list ttkbootstrap::_svgsb_drag $w %x %y]
    bind $w <ButtonRelease-1> [list set ::ttkbootstrap::svgsb::${w}::dragging 0]
    bind $w <<ThemeChanged>>  [list ttkbootstrap::_svgsb_draw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsb
    return $w
}

proc SVGScrollbar_set {w first last} {
    set ns ::ttkbootstrap::svgsb::$w
    set ${ns}::first $first
    set ${ns}::last $last
    _svgsb_draw $w
}

proc _svgsb_draw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsb::$w
    array set o [set ${ns}::o]
    set f [set ${ns}::first]; set l [set ${ns}::last]
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set trk [ttkbootstrap::_lighten $hex 35]
    set bg  [ttkbootstrap::getColor bg]
    $w configure -bg $bg
    $w delete all

    set vert [expr {$o(-orient) eq "vertical"}]
    set W [winfo width $w]; set H [winfo height $w]
    if {$W < 2 || $H < 2} return

    set len [expr {$vert ? $H : $W}]
    set thick [expr {$vert ? $W : $H}]
    set pad 2; set r [expr {($thick - $pad*2) / 2}]

    # Track
    if {$vert} {
        $w create rectangle $pad $pad [expr {$W-$pad}] [expr {$H-$pad}] \
            -fill $trk -outline $trk
    } else {
        $w create rectangle $pad $pad [expr {$W-$pad}] [expr {$H-$pad}] \
            -fill $trk -outline $trk
    }

    # Thumb
    if {$l - $f < 0.999} {
        set t0 [expr {$pad + int(($len - $pad*2) * $f)}]
        set t1 [expr {$pad + int(($len - $pad*2) * $l)}]
        set tlen [expr {$t1 - $t0}]
        if {$tlen < [expr {$r * 3}]} { set tlen [expr {$r * 3}] }
        set t1 [expr {$t0 + $tlen}]

        set tsz [expr {$vert ? $W : $H}]
        set svg "<svg xmlns='http://www.w3.org/2000/svg' "
        if {$vert} {
            append svg "width='[expr {$tsz-$pad*2}]' height='$tlen'>"
            append svg "<rect x='0' y='0' width='[expr {$tsz-$pad*2}]' height='$tlen' rx='$r' ry='$r' fill='$hex'/>"
        } else {
            append svg "width='$tlen' height='[expr {$tsz-$pad*2}]'>"
            append svg "<rect x='0' y='0' width='$tlen' height='[expr {$tsz-$pad*2}]' rx='$r' ry='$r' fill='$hex'/>"
        }
        append svg "</svg>"
        catch { image delete ${w}::thumb }
        image create photo ${w}::thumb -data $svg -format {svg}
        if {$vert} {
            $w create image [expr {$W/2}] [expr {$t0 + $tlen/2}] \
                -image ${w}::thumb -anchor center -tags thumb
        } else {
            $w create image [expr {$t0 + $tlen/2}] [expr {$H/2}] \
                -image ${w}::thumb -anchor center -tags thumb
        }
    }
}

proc _svgsb_press {w x y} {
    set ns ::ttkbootstrap::svgsb::$w
    array set o [set ${ns}::o]
    set ${ns}::dragging 1
    set ${ns}::drag_start [expr {$o(-orient) eq "vertical" ? $y : $x}]
    set ${ns}::drag_f0 [set ${ns}::first]
}

proc _svgsb_drag {w x y} {
    set ns ::ttkbootstrap::svgsb::$w
    if {![set ${ns}::dragging]} return
    array set o [set ${ns}::o]
    set vert [expr {$o(-orient) eq "vertical"}]
    set pos [expr {$vert ? $y : $x}]
    set len [expr {$vert ? [winfo height $w] : [winfo width $w]}]
    set delta [expr {double($pos - [set ${ns}::drag_start]) / $len}]
    set span [expr {[set ${ns}::last] - [set ${ns}::first]}]
    set newf [expr {[set ${ns}::drag_f0] + $delta}]
    if {$newf < 0} {set newf 0}
    if {$newf + $span > 1} {set newf [expr {1 - $span}]}
    if {$o(-command) ne {}} {
        uplevel #0 $o(-command) moveto $newf
    }
}

} ;# end namespace ttkbootstrap

# ── SVGTimeline ───────────────────────────────────────────────────────────────
# Vertical timeline with SVG circles, connector lines, and label overlays.
#
# USAGE
#   set tl [ttkbootstrap::SVGTimeline .tl]
#   ttkbootstrap::SVGTimeline::add $tl \
#       -title "Deployed v2.0" -timestamp "14:32" \
#       -body "All services running." -bootstyle success -icon "✓"
#
namespace eval ttkbootstrap {

proc SVGTimeline {w args} {
    array set o {-bootstyle primary}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGTimeline -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgtl::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::items {}

    ttk::frame $w
    set ${ns}::interior $w

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgtl_rebuild $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgtl
    return $w
}

namespace eval SVGTimeline {
    proc add {w args} {
        array set o {-title "" -timestamp "" -body "" -bootstyle "" -icon "\u2022" -shape circle}
        array set o $args
        set ns ::ttkbootstrap::svgtl::$w
        lappend ${ns}::items [array get o]
        ttkbootstrap::_svgtl_add_item $w [array get o]
    }
}

proc _svgtl_add_item {w item_opts} {
    array set o $item_opts
    set ns ::ttkbootstrap::svgtl::$w
    array set wo [set ${ns}::o]
    set interior [set ${ns}::interior]

    if {![info exists ${ns}::counter]} { set ${ns}::counter 0 }
    set idx [incr ${ns}::counter]

    set bs $o(-bootstyle)
    if {$bs eq ""} { set bs $wo(-bootstyle) }
    set hex [ttkbootstrap::getColor $bs]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set fg [ttkbootstrap::_contrastFg $hex]
    set bg [ttkbootstrap::getColor bg]
    set fgn [ttkbootstrap::getColor fg]
    set bdr [ttkbootstrap::getColor border]
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]

    set row [ttk::frame $interior.tl$idx]
    pack $row -fill x -pady [ttkbootstrap::_sp2 0 2]

    # SVG shape for the dot — circle or square
    set csz [ttkbootstrap::_sp 32]
    set cx [expr {$csz / 2}]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$csz' height='$csz'>"
    set shape [expr {[info exists o(-shape)] ? $o(-shape) : "circle"}]
    if {$shape eq "square"} {
        set r 3
        append svg "<rect x='2' y='2' width='[expr {$csz-4}]' height='[expr {$csz-4}]' rx='$r' ry='$r' fill='$hex'/>"
    } else {
        append svg "<circle cx='$cx' cy='$cx' r='[expr {$cx-2}]' fill='$hex'/>"
    }
    append svg "</svg>"
    catch { image delete ${row}::dot }
    image create photo ${row}::dot -data $svg -format {svg}

    # Left column: dot + line — same approach as original Timeline
    set left [frame $row.left -bg $bg -width [ttkbootstrap::_sp 40]]
    pack $left -side left -fill y
    $left configure -width [ttkbootstrap::_sp 40]
    pack propagate $left 0

    # Dot image with icon text overlaid via -compound center
    label $left.dotimg -image ${row}::dot -bd 0 -highlightthickness 0 -bg $bg \
        -text $o(-icon) -compound center -fg $fg \
        -font [list $fn [ttkbootstrap::_sf 11] bold]
    place $left.dotimg -anchor n -relx 0.5 -y [ttkbootstrap::_sp 4]

    # Connector line — full height, centred
    frame $left.line -bg $bdr -width [ttkbootstrap::_sp 2]
    place $left.line -anchor n -relx 0.5 \
        -y [expr {[ttkbootstrap::_sp 4] + $csz}] \
        -width [ttkbootstrap::_sp 2] -relheight 1.0

    # Right column: content
    set cf [frame $row.content -bg $bg -padx [ttkbootstrap::_sp 8]]
    pack $cf -side left -fill both -expand 1 -pady [ttkbootstrap::_sp2 4 8]
    ttk::label $cf.ts -text $o(-timestamp) -foreground [ttkbootstrap::getColor secondary] \
        -font [list $fn [ttkbootstrap::_sf 10]]
    ttk::label $cf.title -text $o(-title) -foreground $fgn \
        -font [list $fn [ttkbootstrap::_sf 12] bold]
    if {$o(-body) ne ""} {
        ttk::label $cf.body -text $o(-body) -foreground $fgn \
            -font [list $fn [ttkbootstrap::_sf 11]] -wraplength 300
        pack $cf.ts $cf.title $cf.body -anchor w
    } else {
        pack $cf.ts $cf.title -anchor w
    }
}

proc _svgtl_rebuild {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgtl::$w
    set interior [set ${ns}::interior]
    foreach child [winfo children $interior] { destroy $child }
    set ${ns}::counter 0
    foreach item [set ${ns}::items] {
        _svgtl_add_item $w $item
    }
}

} ;# end namespace ttkbootstrap

# ── SVGBreadcrumb ─────────────────────────────────────────────────────────────
# Breadcrumb navigation with SVG chevron separators.
#
# USAGE
#   ttkbootstrap::SVGBreadcrumb .bc \
#       -items {Home Settings Users} -bootstyle primary \
#       -command { puts "clicked $idx" }
#
namespace eval ttkbootstrap {

proc SVGBreadcrumb {w args} {
    array set o {-items {} -bootstyle primary -command {}}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGBreadcrumb -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgbc::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    ttk::frame $w
    _svgbc_rebuild $w
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgbc_rebuild $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgbc
    return $w
}

proc _svgbc_rebuild {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgbc::$w
    array set o [set ${ns}::o]
    foreach child [winfo children $w] { destroy $child }

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set fg  [ttkbootstrap::getColor fg]
    set bdr [ttkbootstrap::getColor border]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs  [ttkbootstrap::_sf 12]

    # SVG chevron separator
    set chsz 14
    set _bcbg [ttkbootstrap::getColor bg]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$chsz' height='$chsz'>"
    append svg "<rect x='0' y='0' width='$chsz' height='$chsz' fill='$_bcbg'/>"
    append svg "<polyline points='3,2 11,7 3,12' fill='none' stroke='$bdr' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>"
    append svg "</svg>"
    catch { image delete ${w}::chev }
    image create photo ${w}::chev -data $svg -format {svg}

    set items $o(-items)
    set n [llength $items]
    for {set i 0} {$i < $n} {incr i} {
        set lbl [lindex $items $i]
        set last [expr {$i == $n - 1}]

        if {$i > 0} {
            label $w.sep$i -image ${w}::chev -bd 0 -highlightthickness 0 \
                -bg [ttkbootstrap::getColor bg]
            pack $w.sep$i -side left -padx 2
        }

        set color [expr {$last ? $fg : $hex}]
        set fstyle [expr {$last ? "bold" : "normal"}]
        label $w.item$i -text $lbl -fg $color -bg [ttkbootstrap::getColor bg] \
            -font [list $fn $fs $fstyle] -bd 0 -highlightthickness 0 \
            -cursor [expr {$last ? "" : "hand2"}]
        pack $w.item$i -side left

        if {!$last} {
            set cmd $o(-command)
            bind $w.item$i <Button-1> [list apply {{w cmd idx} {
                if {$cmd ne {}} {
                    set ::idx $idx
                    uplevel #0 $cmd
                }
            }} $w $cmd $i]
            bind $w.item$i <Enter> [list $w.item$i configure \
                -fg [ttkbootstrap::_darken $hex 15]]
            bind $w.item$i <Leave> [list $w.item$i configure -fg $hex]
        }
    }
}

namespace eval SVGBreadcrumb {
    proc load {w items} {
        set ns ::ttkbootstrap::svgbc::$w
        array set o [::set ${ns}::o]
        ::set o(-items) $items
        ::set ${ns}::o [array get o]
        ttkbootstrap::_svgbc_rebuild $w
    }
    proc get {w} {
        set ns ::ttkbootstrap::svgbc::$w
        array set o [::set ${ns}::o]
        return $o(-items)
    }
}

} ;# end namespace ttkbootstrap

# ── SVGCard ───────────────────────────────────────────────────────────────────
# Content card with SVG rounded border and title bar.
#
# USAGE
#   set c [ttkbootstrap::SVGCard .c -title "Summary" -bootstyle primary]
#   set body [ttkbootstrap::SVGCard::body $c]
#   ttk::label $body.l -text "Content here"
#   pack $body.l
#
namespace eval ttkbootstrap {

proc SVGCard {w args} {
    array set o {-title "" -bootstyle primary -padding 0 -width 0 -height 0}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGCard -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgcd::$w
    namespace eval $ns {}

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set cfgfg [ttkbootstrap::_contrastFg $hex]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    if {$o(-padding) == 0} { set o(-padding) [ttkbootstrap::_sp 10] }
    if {$o(-width) == 0}  { set o(-width) [ttkbootstrap::_sp 200] }
    if {$o(-height) == 0} { set o(-height) [ttkbootstrap::_sp 120] }
    set ${ns}::o [array get o]

    # Canvas-based card with SVG rounded background
    canvas $w -highlightthickness 0 -bd 0 -bg $bg \
        -width $o(-width) -height $o(-height)
    set ${ns}::canvas $w

    bind $w <Configure> [list ttkbootstrap::_svgcd_draw $w]
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgcd_retheme $w]

    # Create body frame (will be embedded into canvas)
    frame $w.body -bg $bg -highlightthickness 0 -bd 0 \
        -padx $o(-padding) -pady $o(-padding)
    set ${ns}::body $w.body

    after idle [list ttkbootstrap::_svgcd_draw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgcd
    return $w
}

proc _svgcd_draw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgcd::$w
    array set o [set ${ns}::o]

    set W [winfo width $w]
    set H [winfo height $w]
    if {$W < 20 || $H < 20} return

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set cfgfg [ttkbootstrap::_contrastFg $hex]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set r [ttkbootstrap::_sp 12]

    $w configure -bg $bg
    $w delete all

    # Compute header height
    set hdr_h 0
    if {$o(-title) ne ""} {
        set fs [ttkbootstrap::_sf 12]
        set hdr_h [expr {[font metrics [list $fn $fs bold] -linespace] + [ttkbootstrap::_sp 12]}]
    }

    # Draw SVG card as two joined shapes:
    # 1. Header: rounded top corners, straight bottom
    # 2. Body: straight top, rounded bottom corners, with border
    set sw 1.5
    set hw [expr {$sw / 2.0}]
    set x1 $hw
    set y1 $hw
    set x2 [expr {$W - $hw}]
    set y2 [expr {$H - $hw}]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'><rect x='0' y='0' width='$W' height='$H' fill='$bg'/>"  ;# bgfill_done
    if {$hdr_h > 0} {
        set hy [expr {$hdr_h + $y1}]
        # Header — rounded top, straight bottom
        append svg "<path d='M [expr {$r+$x1}] $y1"
        append svg " Q $x1 $y1 $x1 [expr {$r+$y1}]"
        append svg " L $x1 $hy"
        append svg " L $x2 $hy"
        append svg " L $x2 [expr {$r+$y1}]"
        append svg " Q $x2 $y1 [expr {$x2-$r}] $y1"
        append svg " Z' fill='$hex' stroke='$hex' stroke-width='$sw'/>"
        # Body — straight top, rounded bottom
        append svg "<path d='M $x1 $hy"
        append svg " L $x1 [expr {$y2-$r}]"
        append svg " Q $x1 $y2 [expr {$r+$x1}] $y2"
        append svg " L [expr {$x2-$r}] $y2"
        append svg " Q $x2 $y2 $x2 [expr {$y2-$r}]"
        append svg " L $x2 $hy"
        append svg " Z' fill='$bg' stroke='$bdr' stroke-width='$sw'/>"
    } else {
        append svg "<rect x='$x1' y='$y1' width='[expr {$x2-$x1}]' height='[expr {$y2-$y1}]' rx='$r' ry='$r' fill='$bg' stroke='$bdr' stroke-width='$sw'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::card_img }
    image create photo ${w}::card_img -data $svg -format {svg}
    $w create image 0 0 -image ${w}::card_img -anchor nw

    # Title text on canvas (not a widget — no rectangular bg)
    if {$o(-title) ne ""} {
        $w create text [ttkbootstrap::_sp 14] [expr {$hdr_h / 2}] \
            -text $o(-title) -fill $cfgfg \
            -font [list $fn [ttkbootstrap::_sf 12] bold] \
            -anchor w
    }

    # Embed body frame
    set pad [ttkbootstrap::_sp 4]
    $w create window $pad [expr {$hdr_h + $pad}] -window $w.body \
        -anchor nw -width [expr {$W - $pad*2}] -height [expr {$H - $hdr_h - $pad*2}]
}

proc _svgcd_retheme {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgcd::$w
    array set o [set ${ns}::o]
    set bg [ttkbootstrap::getColor bg]
    $w.body configure -bg $bg
    after idle [list ttkbootstrap::_svgcd_draw $w]
}

namespace eval SVGCard {
    proc body {w} { return $w.body }
}

} ;# end namespace ttkbootstrap


# ── SVGShadowCard ─────────────────────────────────────────────────────────────
# Card with layered SVG drop shadow effect.
#
# USAGE
#   set c [ttkbootstrap::SVGShadowCard .c -title "Dashboard" -bootstyle primary]
#   set body [ttkbootstrap::SVGShadowCard::body $c]
#   ttk::label $body.l -text "Content here"
#   pack $body.l
#
namespace eval ttkbootstrap {

proc SVGShadowCard {w args} {
    array set o {-title "" -bootstyle primary -padding 0 -width 0 -height 0 -shadow 10}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGShadowCard -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgsc::$w
    namespace eval $ns {}

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set cfgfg [ttkbootstrap::_contrastFg $hex]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    if {$o(-padding) == 0} { set o(-padding) [ttkbootstrap::_sp 10] }
    if {$o(-width) == 0}  { set o(-width) [ttkbootstrap::_sp 200] }
    if {$o(-height) == 0} { set o(-height) [ttkbootstrap::_sp 140] }
    set ${ns}::o [array get o]

    # Shadow layers need extra space
    set shpad [ttkbootstrap::_sp [expr {$o(-shadow) * 3}]]

    # Canvas with extra room for shadow
    canvas $w -highlightthickness 0 -bd 0 -bg $bg \
        -width [expr {$o(-width) + $shpad}] \
        -height [expr {$o(-height) + $shpad}]
    set ${ns}::canvas $w

    # Header height
    set hdr_h 0
    if {$o(-title) ne ""} {
        set hdr_h [expr {[font metrics [list $fn [ttkbootstrap::_sf 12] bold] -linespace] + [ttkbootstrap::_sp 12]}]
    }
    set ${ns}::hdr_h $hdr_h

    # Body frame embedded in the canvas — sized to fit the CARD area, not the canvas
    set body [frame $w.body -bg $bg -highlightthickness 0 -bd 0 \
        -padx $o(-padding) -pady $o(-padding)]
    set body_y [expr {$hdr_h + [ttkbootstrap::_sp 2]}]
    set body_w [expr {$o(-width) - [ttkbootstrap::_sp 4]}]
    set body_h [expr {$o(-height) - $hdr_h - [ttkbootstrap::_sp 4]}]
    $w create window [ttkbootstrap::_sp 2] $body_y \
        -window $body -anchor nw \
        -width $body_w -height $body_h
    set ${ns}::body $body

    bind $w <Configure> [list ttkbootstrap::_svgshc_draw $w]
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgshc_retheme $w]
    after idle [list ttkbootstrap::_svgshc_draw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsc
    return $w
}

proc _svgshc_draw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsc::$w
    array set o [set ${ns}::o]

    set cW [winfo width $w]
    set cH [winfo height $w]
    if {$cW < 20 || $cH < 20} return

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set cfgfg [ttkbootstrap::_contrastFg $hex]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set isDark [expr {[ttkbootstrap::getColor type] eq "dark"}]

    $w configure -bg $bg
    $w delete svgbg

    set r [ttkbootstrap::_sp 10]
    set hdr_h [set ${ns}::hdr_h]
    set nlayers $o(-shadow)
    set shoff 1

    # Card dimensions (smaller than canvas to leave room for shadow)
    set cardW [expr {$cW - $nlayers * $shoff - [ttkbootstrap::_sp 2]}]
    set cardH [expr {$cH - $nlayers * $shoff - [ttkbootstrap::_sp 2]}]
    if {$cardW < 20 || $cardH < 20} return

    # Shadow — single SVG containing all shadow layers + bg cutout.
    # Total shadow area is card size + padding for the shadow spread.
    set spread [expr {$nlayers * $shoff}]
    set sW [expr {$cardW + $spread + $shoff}]
    set sH [expr {$cardH + $spread + $shoff}]
    set ssvg "<svg xmlns='http://www.w3.org/2000/svg' width='$sW' height='$sH'>"
    # Draw outermost layer first (lightest), then progressively darker/smaller
    for {set i $nlayers} {$i >= 1} {incr i -1} {
        # Each layer: same card size, but offset by i*shoff down-right
        set lx [expr {$i * $shoff}]
        set ly [expr {$i * $shoff}]
        # Colour: outermost is lightest, innermost is darkest
        set frac [expr {double($nlayers - $i + 1) / double($nlayers)}]
        if {$isDark} {
            set shcol [ttkbootstrap::_darken $bg [expr {int(25 * $frac)}]]
        } else {
            set shcol [ttkbootstrap::_darken $bg [expr {int(18 * $frac)}]]
        }
        append ssvg "<rect x='$lx' y='$ly' width='$cardW' height='$cardH' rx='$r' ry='$r' fill='$shcol'/>"
    }
    # Final layer: page bg at card position (0,0) to cleanly erase shadow behind card
    append ssvg "<rect x='0' y='0' width='$cardW' height='$cardH' rx='$r' ry='$r' fill='$bg'/>"
    append ssvg "</svg>"
    catch { image delete ${w}::shadow }
    image create photo ${w}::shadow -data $ssvg -format {svg}
    $w create image 0 0 -image ${w}::shadow -anchor nw -tags svgbg

    # Card SVG — header + body (same as SVGCard)
    set sw 1.5
    set hw [expr {$sw / 2.0}]
    set x1 $hw
    set y1 $hw
    set x2 [expr {$cardW - $hw}]
    set y2 [expr {$cardH - $hw}]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$cardW' height='$cardH'>"
    if {$hdr_h > 0} {
        set hy [expr {$hdr_h + $y1}]
        # Header
        append svg "<path d='M [expr {$r+$x1}] $y1"
        append svg " Q $x1 $y1 $x1 [expr {$r+$y1}]"
        append svg " L $x1 $hy L $x2 $hy"
        append svg " L $x2 [expr {$r+$y1}]"
        append svg " Q $x2 $y1 [expr {$x2-$r}] $y1"
        append svg " Z' fill='$hex' stroke='$hex' stroke-width='$sw'/>"
        # Body
        append svg "<path d='M $x1 $hy"
        append svg " L $x1 [expr {$y2-$r}]"
        append svg " Q $x1 $y2 [expr {$r+$x1}] $y2"
        append svg " L [expr {$x2-$r}] $y2"
        append svg " Q $x2 $y2 $x2 [expr {$y2-$r}]"
        append svg " L $x2 $hy"
        append svg " Z' fill='$bg' stroke='$bdr' stroke-width='$sw'/>"
    } else {
        append svg "<rect x='$x1' y='$y1' width='[expr {$x2-$x1}]' height='[expr {$y2-$y1}]' rx='$r' ry='$r' fill='$bg' stroke='$bdr' stroke-width='$sw'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::card }
    image create photo ${w}::card -data $svg -format {svg}
    $w create image 0 0 -image ${w}::card -anchor nw -tags svgbg

    # Title text
    if {$hdr_h > 0} {
        $w create text [ttkbootstrap::_sp 14] [expr {$hdr_h / 2 + 1}] \
            -text $o(-title) -fill $cfgfg \
            -font [list $fn [ttkbootstrap::_sf 12] bold] \
            -anchor w -tags svgbg
    }

    # Ensure body window is on top
    raise $w.body
}

proc _svgshc_retheme {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsc::$w
    set bg [ttkbootstrap::getColor bg]
    $w configure -bg $bg
    $w.body configure -bg $bg
    after idle [list ttkbootstrap::_svgshc_draw $w]
}

namespace eval SVGShadowCard {
    proc body {w} {
        set ns ::ttkbootstrap::svgsc::$w
        return [set ${ns}::body]
    }
}

} ;# end namespace ttkbootstrap

# ── SVGTooltip ────────────────────────────────────────────────────────────────
# Themed tooltip with SVG rounded background that appears on hover.
#
# USAGE
#   ttkbootstrap::SVGTooltip .mybutton "Click to submit" -bootstyle dark
#
namespace eval ttkbootstrap {

proc SVGTooltip {widget text args} {
    array set o {-bootstyle dark -delay 500 -wraplength 200}
    array set o $args
    _validateBootstyle SVGTooltip -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgtt::$widget
    namespace eval $ns {}
    set ${ns}::text $text
    set ${ns}::o [array get o]
    set ${ns}::afterid {}

    bind $widget <Enter> [list ttkbootstrap::_svgtt_schedule $widget]
    bind $widget <Leave> [list ttkbootstrap::_svgtt_hide $widget]
    bind $widget <ButtonPress> [list ttkbootstrap::_svgtt_hide $widget]
}

proc _svgtt_schedule {widget} {
    set ns ::ttkbootstrap::svgtt::$widget
    array set o [set ${ns}::o]
    _svgtt_hide $widget
    set ${ns}::afterid [after $o(-delay) [list ttkbootstrap::_svgtt_show $widget]]
}

proc _svgtt_show {widget} {
    if {![winfo exists $widget]} return
    set ns ::ttkbootstrap::svgtt::$widget
    set text [set ${ns}::text]
    array set o [set ${ns}::o]

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor dark] }
    set fg [ttkbootstrap::_contrastFg $hex]
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 11]

    catch { destroy .svgtt_popup }
    set p [toplevel .svgtt_popup]
    wm overrideredirect $p 1
    catch { wm attributes $p -topmost 1 }
    wm withdraw $p

    # Build tooltip with SVG rounded background
    set tw [font measure [list $fn $fs] $text]
    set th [font metrics [list $fn $fs] -linespace]
    set W [expr {min($tw + 20, $o(-wraplength) + 20)}]
    set H [expr {$th + 12}]
    # If text wraps, estimate height
    if {$tw > $o(-wraplength)} {
        set nlines [expr {int(ceil(double($tw) / $o(-wraplength)))}]
        set H [expr {$th * $nlines + 12}]
    }
    set r 6

    # Position: prefer above the widget, fall back to below
    set wx [expr {[winfo rootx $widget] + [winfo width $widget] / 2}]
    set wy_below [expr {[winfo rooty $widget] + [winfo height $widget] + 4}]
    set wy_above [expr {[winfo rooty $widget] - $H - 4}]
    set sh [winfo screenheight $widget]
    # Show above if below would go off screen, or above has room
    if {$wy_above >= 0 && ($wy_below + $H > $sh || $wy_above > 40)} {
        set y $wy_above
    } else {
        set y $wy_below
    }
    set x $wx

    # Rounded tooltip. A full-canvas rect in the page background sits BEHIND the
    # rounded coloured rect so the antialiased corner fringe blends
    # colour->page-bg inside the image (no white/light corner tips).
    set r [ttkbootstrap::_sp 6]
    set ttpagebg [ttkbootstrap::getColor bg]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>"
    append svg "<rect x='0' y='0' width='$W' height='$H' fill='$ttpagebg'/>"
    append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$hex'/>"
    append svg "</svg>"

    catch { image delete .svgtt_popup::bg }
    image create photo .svgtt_popup::bg -data $svg -format {svg}

    # Use page bg for the toplevel/label: transparent corners blend into page.
    set ttpagebg [ttkbootstrap::getColor bg]
    $p configure -bg $ttpagebg
    label $p.bg -image .svgtt_popup::bg -bd 0 -highlightthickness 0 -bg $ttpagebg
    place $p.bg -x 0 -y 0 -relwidth 1 -relheight 1

    label $p.txt -text $text -fg $fg -bg $hex \
        -font [list $fn $fs] -wraplength $o(-wraplength) \
        -bd 0 -highlightthickness 0 -justify left
    place $p.txt -relx 0.5 -rely 0.5 -anchor center

    wm geometry $p ${W}x${H}+[expr {$x - $W/2}]+$y
    wm deiconify $p
    raise $p
}

proc _svgtt_hide {widget} {
    set ns ::ttkbootstrap::svgtt::$widget
    catch { after cancel [set ${ns}::afterid] }
    catch { destroy .svgtt_popup }
}

} ;# end namespace ttkbootstrap

# ── SVGDateEntry ──────────────────────────────────────────────────────────────
# Entry with calendar popup. Calendar grid uses SVG circles for day highlights.
#
# USAGE
#   ttkbootstrap::SVGDateEntry .de -bootstyle primary \
#       -dateformat "%Y-%m-%d" -textvariable ::mydate
#
namespace eval ttkbootstrap {

proc SVGDateEntry {w args} {
    array set o {
        -bootstyle primary -dateformat "%Y-%m-%d"
        -textvariable {} -firstweekday 0
    }
    array set o $args
    ttkbootstrap::_validateBootstyle SVGDateEntry -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgde::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    # Current date for initial display
    set now [clock seconds]
    set ${ns}::year  [clock format $now -format "%Y"]
    set ${ns}::month [clock format $now -format "%m"]
    set ${ns}::day   [clock format $now -format "%d"]
    scan [set ${ns}::month] %d m; set ${ns}::month $m
    scan [set ${ns}::day]   %d d; set ${ns}::day   $d

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 11]

    ttk::frame $w
    set ecmd [list ttk::entry $w.ent -width 14 -font [list $fn $fs]]
    if {$o(-textvariable) ne {}} { lappend ecmd -textvariable $o(-textvariable) }
    {*}$ecmd

    # Calendar button — SVG calendar icon sized to match entry field height
    set _fn_tmp [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set _fs_tmp [ttkbootstrap::_sf 12]
    set _ls_tmp [font metrics [list $_fn_tmp $_fs_tmp] -linespace]
    set _icon_sz [expr {$_ls_tmp + [ttkbootstrap::_sp 4]}]
    set _iscale [expr {$_icon_sz / 22.0}]
    set _calstroke [ttkbootstrap::_contrastFg [ttkbootstrap::getColor $o(-bootstyle)]]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='21' height='22'>"
    # Body outline
    append svg "<rect x='2' y='4' width='17' height='16' rx='2' ry='2' fill='none' stroke='$_calstroke' stroke-width='1.6'/>"
    # Header divider
    append svg "<line x1='2' y1='9' x2='19' y2='9' stroke='$_calstroke' stroke-width='1.6'/>"
    # Hanging rings
    append svg "<line x1='7' y1='2' x2='7' y2='6' stroke='$_calstroke' stroke-width='2' stroke-linecap='round'/>"
    append svg "<line x1='14' y1='2' x2='14' y2='6' stroke='$_calstroke' stroke-width='2' stroke-linecap='round'/>"
    # A sparse 3x2 grid of day dots, well spaced so it reads as a calendar
    append svg "<rect x='5'  y='12' width='2.2' height='2.2' rx='0.6' fill='$_calstroke'/>"
    append svg "<rect x='9.5' y='12' width='2.2' height='2.2' rx='0.6' fill='$_calstroke'/>"
    append svg "<rect x='14' y='12' width='2.2' height='2.2' rx='0.6' fill='$_calstroke'/>"
    append svg "<rect x='5'  y='15.5' width='2.2' height='2.2' rx='0.6' fill='$_calstroke'/>"
    append svg "<rect x='9.5' y='15.5' width='2.2' height='2.2' rx='0.6' fill='$_calstroke'/>"
    append svg "</svg>"
    catch { image delete ${w}::cal_icon }
    image create photo ${w}::cal_icon -data $svg -format [list svg -scale $_iscale]

    ttk::button $w.btn -image ${w}::cal_icon \
        -style "${o(-bootstyle)}.TButton" \
        -padding [ttkbootstrap::_sp2 4 2] \
        -command [list ttkbootstrap::_svgde_popup $w]

    pack $w.ent -side left -fill x -expand 1
    pack $w.btn -side left -padx {2 0}

    # Set initial date
    set datestr [clock format $now -format $o(-dateformat)]
    if {$o(-textvariable) ne {}} {
        if {![info exists $o(-textvariable)] || [set $o(-textvariable)] eq ""} {
            set $o(-textvariable) $datestr
        }
    } else {
        $w.ent insert 0 $datestr
    }

    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgde
    return $w
}

proc _svgde_popup {w} {
    set ns ::ttkbootstrap::svgde::$w
    array set o [set ${ns}::o]

    catch { destroy .svgde_cal }
    set cal [toplevel .svgde_cal]
    wm overrideredirect $cal 1
    catch { wm attributes $cal -topmost 1 }
    wm withdraw $cal

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]
    set bdr [ttkbootstrap::getColor border]
    set cfgfg [ttkbootstrap::_contrastFg $hex]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]

    frame $cal.f -bg $bg -relief solid -bd 1
    pack $cal.f -fill both -expand 1

    set ${ns}::cal $cal

    _svgde_draw_month $w

    set x [winfo rootx $w]
    set y [expr {[winfo rooty $w] + [winfo height $w] + 2}]
    wm geometry $cal +$x+$y
    wm deiconify $cal
    raise $cal

    bind $cal <FocusOut> [list after idle [list ttkbootstrap::_svgde_focusout $w $cal]]
    bind $cal <Escape>   [list catch [list destroy $cal]]
    after idle [list focus $cal]
}

proc _svgde_focusout {w cal} {
    # Mirror the Original DateEntry's robust dismiss: defer via 'after idle' so
    # the new focus target settles, then only close if focus has moved TRULY
    # outside the popup. Closing unconditionally on every <FocusOut> dismissed
    # the popup the instant the pointer/focus transiently left the toplevel
    # (e.g. while moving the cursor into the popup), making dates unselectable.
    if {![winfo exists $cal]} return
    set f [focus]
    if {$f eq ""} return
    if {![winfo exists $f]} return
    if {[string match "${cal}*" $f] || $f eq $cal} return
    catch { destroy $cal }
}

proc _svgde_draw_month {w} {
    set ns ::ttkbootstrap::svgde::$w
    array set o [set ${ns}::o]
    set cal [set ${ns}::cal]
    set year [set ${ns}::year]
    set month [set ${ns}::month]
    set selday [set ${ns}::day]

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]
    set cfgfg [ttkbootstrap::_contrastFg $hex]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs  [ttkbootstrap::_sf 11]

    # Clear
    foreach child [winfo children $cal.f] { destroy $child }

    # Nav bar
    set nav [frame $cal.f.nav -bg $bg]
    pack $nav -fill x -padx [ttkbootstrap::_sp 4] -pady [ttkbootstrap::_sp 4]
    label $nav.prev -text "\u25c0" -fg $hex -bg $bg -cursor hand2 \
        -font [list $fn [ttkbootstrap::_sf 12]]
    label $nav.title -text "[lindex {_ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec} $month] $year" \
        -fg $fg -bg $bg -font [list $fn $fs bold]
    label $nav.next -text "\u25b6" -fg $hex -bg $bg -cursor hand2 \
        -font [list $fn [ttkbootstrap::_sf 12]]
    pack $nav.prev -side left -padx [ttkbootstrap::_sp 4]
    pack $nav.next -side right -padx [ttkbootstrap::_sp 4]
    pack $nav.title -fill x

    bind $nav.prev <Button-1> [list apply {{w ns} {
        set m [set ${ns}::month]; set y [set ${ns}::year]
        incr m -1; if {$m < 1} { set m 12; incr y -1 }
        set ${ns}::month $m; set ${ns}::year $y
        ttkbootstrap::_svgde_draw_month $w
    }} $w $ns]
    bind $nav.next <Button-1> [list apply {{w ns} {
        set m [set ${ns}::month]; set y [set ${ns}::year]
        incr m 1; if {$m > 12} { set m 1; incr y 1 }
        set ${ns}::month $m; set ${ns}::year $y
        ttkbootstrap::_svgde_draw_month $w
    }} $w $ns]

    # Cell size: large enough for the widest two-digit date at the current
    # font, plus padding — so digits never collide at any DPI/scale. Computed
    # once here and shared by the day headers and the day grid below.
    set digitW [font measure [list $fn $fs] "00"]
    set csz [expr {$digitW + [ttkbootstrap::_sp 12]}]
    set mincell [ttkbootstrap::_sp 30]
    if {$csz < $mincell} { set csz $mincell }

    # Day headers — same fixed-size columns as the day grid so they line up.
    set hdr [frame $cal.f.hdr -bg $bg]
    pack $hdr -fill x -padx [ttkbootstrap::_sp 4]
    set hc 0
    foreach d {Su Mo Tu We Th Fr Sa} {
        label $hdr.d$d -text $d -fg [ttkbootstrap::getColor secondary] -bg $bg \
            -font [list $fn [ttkbootstrap::_sf 10]] -anchor center
        grid $hdr.d$d -row 0 -column $hc -sticky nsew
        incr hc
    }
    for {set c 0} {$c < 7} {incr c} {
        grid columnconfigure $hdr $c -weight 1 -uniform daycol -minsize $csz
    }

    # Day grid. Use a fixed scaled cell size so two-digit dates never collide
    # and every column has equal width regardless of DPI/scale.
    set grid [frame $cal.f.grid -bg $bg]
    pack $grid -fill both -expand 1 -padx [ttkbootstrap::_sp 4] -pady [ttkbootstrap::_sp2 0 4]

    # First day of month
    set first [clock scan "$year-$month-01" -format "%Y-%m-%d"]
    set dow [clock format $first -format "%w"]
    set daysInMonth [clock format [clock add $first 1 month -1 day] -format "%d"]
    scan $daysInMonth %d dim

    set row 0; set col $dow
    for {set d 1} {$d <= $dim} {incr d} {
        set isSel [expr {$d == $selday}]

        if {$isSel} {
            # SVG filled circle for selected day — single label with compound center
            set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$csz' height='$csz'>"
            append svg "<circle cx='[expr {$csz/2}]' cy='[expr {$csz/2}]' r='[expr {$csz/2-1}]' fill='$hex'/>"
            append svg "</svg>"
            catch { image delete ${grid}::day$d }
            image create photo ${grid}::day$d -data $svg -format {svg}
            label $grid.d$d -image ${grid}::day$d -text $d -compound center \
                -fg $cfgfg -bg $bg -bd 0 -highlightthickness 0 \
                -font [list $fn $fs bold]
        } else {
            label $grid.d$d -text $d -fg $fg -bg $bg \
                -font [list $fn $fs] -anchor center -cursor hand2
            bind $grid.d$d <Button-1> [list ttkbootstrap::_svgde_select $w $d]
        }
        # Each cell occupies one fixed-size grid cell; the label fills it.
        grid $grid.d$d -row $row -column $col -sticky nsew
        incr col
        if {$col > 6} { set col 0; incr row }
    }

    # Equal, fixed-size columns and rows so digits never overlap.
    for {set c 0} {$c < 7} {incr c} {
        grid columnconfigure $grid $c -weight 1 -uniform daycol -minsize $csz
    }
    for {set rr 0} {$rr <= $row} {incr rr} {
        grid rowconfigure $grid $rr -weight 1 -uniform dayrow -minsize $csz
    }

    # Size the popup to fit 7 columns of $csz plus padding, and all rows.
    set popW [expr {7 * $csz + [ttkbootstrap::_sp 16]}]
    set popH [expr {($row + 1) * $csz + [ttkbootstrap::_sp 78]}]
    wm geometry [set ${ns}::cal] ${popW}x${popH}
}

proc _svgde_select {w d} {
    set ns ::ttkbootstrap::svgde::$w
    set ${ns}::day $d
    array set o [set ${ns}::o]
    set y [set ${ns}::year]; set m [set ${ns}::month]
    set date [clock scan [format {%04d-%02d-%02d} $y $m $d] -format {%Y-%m-%d}]
    set datestr [clock format $date -format $o(-dateformat)]
    if {$o(-textvariable) ne {}} {
        set $o(-textvariable) $datestr
    } else {
        $w.ent delete 0 end
        $w.ent insert 0 $datestr
    }
    catch { destroy [set ${ns}::cal] }
}

} ;# end namespace ttkbootstrap

# ── SVGSidebar ────────────────────────────────────────────────────────────────
# Navigation sidebar with SVG rounded active indicator.
#
# USAGE
#   set sb [ttkbootstrap::SVGSidebar .sb -bootstyle primary -width 200]
#   ttkbootstrap::SVGSidebar::add $sb home "Home" -command { show_home }
#   ttkbootstrap::SVGSidebar::add $sb settings "Settings"
#   ttkbootstrap::SVGSidebar::select $sb home
#
namespace eval ttkbootstrap {

proc SVGSidebar {w args} {
    array set o {-bootstyle primary -width 0}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGSidebar -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgsbar::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::items {}
    set ${ns}::selected {}
    if {$o(-width) == 0} { set o(-width) [ttkbootstrap::_sp 200] }

    set bg [ttkbootstrap::getColor bg]
    frame $w -bg $bg -width $o(-width) -highlightthickness 0 -bd 0
    pack propagate $w 0

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgsbar_retheme $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsbar
    return $w
}

namespace eval SVGSidebar {
    proc add {w key label args} {
        array set o {-command {} -icon ""}
        array set o $args
        set ns ::ttkbootstrap::svgsbar::$w
        lappend ${ns}::items [list $key $label [array get o]]
        ttkbootstrap::_svgsbar_add_item $w $key $label [array get o]
    }
    proc select {w key} {
        set ns ::ttkbootstrap::svgsbar::$w
        ::set ${ns}::selected $key
        ttkbootstrap::_svgsbar_update $w
    }
}

proc _svgsbar_add_item {w key label item_opts} {
    array set o $item_opts
    set ns ::ttkbootstrap::svgsbar::$w
    array set wo [set ${ns}::o]

    set bg [ttkbootstrap::getColor bg]
    set fg [ttkbootstrap::getColor fg]
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]

    set row [frame $w.$key -bg $bg -cursor hand2]
    pack $row -fill x -pady 1

    if {$o(-icon) ne ""} {
        label $row.icon -text $o(-icon) -bg $bg -fg $fg \
            -font [list $fn $fs] -width 3 -anchor center
        pack $row.icon -side left
    }
    label $row.lbl -text $label -bg $bg -fg $fg \
        -font [list $fn $fs] -anchor w -padx [ttkbootstrap::_sp 8] -pady [ttkbootstrap::_sp 6]
    pack $row.lbl -side left -fill x -expand 1

    foreach child [list $row $row.lbl] {
        bind $child <Button-1> [list ttkbootstrap::SVGSidebar::select $w $key]
        if {[info exists o(-command)] && $o(-command) ne {}} {
            bind $child <Button-1> "+$o(-command)"
        }
        bind $child <Enter> [list ttkbootstrap::_svgsbar_hover $w $key 1]
        bind $child <Leave> [list ttkbootstrap::_svgsbar_hover $w $key 0]
    }
    if {[info exists row.icon] && [winfo exists $row.icon]} {
        bind $row.icon <Button-1> [list ttkbootstrap::SVGSidebar::select $w $key]
        bind $row.icon <Enter> [list ttkbootstrap::_svgsbar_hover $w $key 1]
        bind $row.icon <Leave> [list ttkbootstrap::_svgsbar_hover $w $key 0]
    }
}

proc _svgsbar_update {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsbar::$w
    array set wo [set ${ns}::o]
    set sel [set ${ns}::selected]

    set hex [ttkbootstrap::getColor $wo(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]
    set lt  [ttkbootstrap::_lighten $hex 35]
    set cfgfg [ttkbootstrap::_contrastFg $hex]

    foreach item [set ${ns}::items] {
        lassign $item key label opts
        if {![winfo exists $w.$key]} continue
        if {$key eq $sel} {
            $w.$key configure -bg $lt
            $w.$key.lbl configure -bg $lt -fg $hex \
                -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                            [ttkbootstrap::_sf 12] bold]
            catch { $w.$key.icon configure -bg $lt -fg $hex }
        } else {
            $w.$key configure -bg $bg
            $w.$key.lbl configure -bg $bg -fg $fg \
                -font [list [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]] \
                            [ttkbootstrap::_sf 12]]
            catch { $w.$key.icon configure -bg $bg -fg $fg }
        }
    }
}

proc _svgsbar_hover {w key state} {
    if {![winfo exists $w.$key]} return
    set ns ::ttkbootstrap::svgsbar::$w
    set sel [set ${ns}::selected]
    if {$key eq $sel} return

    set bg [ttkbootstrap::getColor bg]
    array set wo [set ${ns}::o]
    set hex [ttkbootstrap::getColor $wo(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set hvr [ttkbootstrap::_lighten $hex 40]

    if {$state} {
        $w.$key configure -bg $hvr
        $w.$key.lbl configure -bg $hvr
        catch { $w.$key.icon configure -bg $hvr }
    } else {
        $w.$key configure -bg $bg
        $w.$key.lbl configure -bg $bg
        catch { $w.$key.icon configure -bg $bg }
    }
}

proc _svgsbar_retheme {w} {
    if {![winfo exists $w]} return
    $w configure -bg [ttkbootstrap::getColor bg]
    _svgsbar_update $w
}

} ;# end namespace ttkbootstrap

# ── SVGTimePicker ─────────────────────────────────────────────────────────────
# Entry with clock popup. Clock face uses SVG circle and hands.
#
# USAGE
#   ttkbootstrap::SVGTimePicker .tp -bootstyle primary \
#       -textvariable ::mytime -timeformat "%H:%M"
#
namespace eval ttkbootstrap {

proc SVGTimePicker {w args} {
    array set o {-bootstyle primary -timeformat "%H:%M" -textvariable {}}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGTimePicker -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgtp::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::hour 12
    set ${ns}::minute 0

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 11]

    ttk::frame $w
    set ecmd [list ttk::entry $w.ent -width 10 -font [list $fn $fs]]
    if {$o(-textvariable) ne {}} { lappend ecmd -textvariable $o(-textvariable) }
    {*}$ecmd

    # Clock icon — sized to match entry field height
    set _fn_tmp [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set _fs_tmp [ttkbootstrap::_sf 12]
    set _ls_tmp [font metrics [list $_fn_tmp $_fs_tmp] -linespace]
    set _icon_sz [expr {$_ls_tmp + [ttkbootstrap::_sp 4]}]
    set _iscale [expr {$_icon_sz / 18.0}]
    set isz 18
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$isz' height='$isz'>"
    append svg "<rect x='0' y='0' width='$isz' height='$isz' fill='$hex'/>"
    append svg "<circle cx='9' cy='9' r='7' fill='none' stroke='white' stroke-width='1.5'/>"
    append svg "<line x1='9' y1='9' x2='9' y2='5' stroke='white' stroke-width='1.5' stroke-linecap='round'/>"
    append svg "<line x1='9' y1='9' x2='12' y2='11' stroke='white' stroke-width='1.5' stroke-linecap='round'/>"
    append svg "</svg>"
    catch { image delete ${w}::clk_icon }
    image create photo ${w}::clk_icon -data $svg -format [list svg -scale $_iscale]

    ttk::button $w.btn -image ${w}::clk_icon \
        -style "${o(-bootstyle)}.TButton" -padding [ttkbootstrap::_sp 2] \
        -command [list ttkbootstrap::_svgtp_popup $w]

    pack $w.ent -side left -fill x -expand 1
    pack $w.btn -side left -padx {2 0}

    # Set initial time
    set now [clock seconds]
    set timestr [clock format $now -format $o(-timeformat)]
    if {$o(-textvariable) ne {}} {
        if {![info exists $o(-textvariable)] || [set $o(-textvariable)] eq ""} {
            set $o(-textvariable) $timestr
        }
    } else {
        $w.ent insert 0 $timestr
    }
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgtp
    return $w
}

proc _svgtp_popup {w} {
    set ns ::ttkbootstrap::svgtp::$w
    array set o [set ${ns}::o]

    catch { destroy .svgtp_popup }
    set pop [toplevel .svgtp_popup]
    wm overrideredirect $pop 1
    catch { wm attributes $pop -topmost 1 }
    wm withdraw $pop

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg  [ttkbootstrap::getColor bg]
    set fg  [ttkbootstrap::getColor fg]
    set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set ${ns}::pop $pop

    frame $pop.f -bg $bg -relief solid -bd 1
    pack $pop.f -fill both -expand 1

    # Hour/Minute spinboxes
    set ctrl [frame $pop.f.ctrl -bg $bg]
    pack $ctrl -padx [ttkbootstrap::_sp 8] -pady [ttkbootstrap::_sp 8]

    set h [set ${ns}::hour]; set m [set ${ns}::minute]

    ttk::spinbox $ctrl.hr -from 0 -to 23 -width 3 -format "%02.0f" \
        -font [list $fn [ttkbootstrap::_sf 12]] -justify center \
        -style "${o(-bootstyle)}.TSpinbox" -wrap 1
    $ctrl.hr set [format "%02d" $h]
    label $ctrl.sep -text ":" -bg $bg -fg $fg \
        -font [list $fn [ttkbootstrap::_sf 12]]
    ttk::spinbox $ctrl.mn -from 0 -to 59 -width 3 -format "%02.0f" \
        -font [list $fn [ttkbootstrap::_sf 12]] -justify center \
        -style "${o(-bootstyle)}.TSpinbox" -wrap 1
    $ctrl.mn set [format "%02d" $m]

    pack $ctrl.hr $ctrl.sep $ctrl.mn -side left -padx [ttkbootstrap::_sp 2]

    # OK button
    ttk::button $pop.f.ok -text "OK" -style "${o(-bootstyle)}.TButton" \
        -padding [ttkbootstrap::_sp2 16 4] -command [list apply {{w ns} {
            array set o [set ${ns}::o]
            set pop [set ${ns}::pop]
            set h [$pop.f.ctrl.hr get]; set m [$pop.f.ctrl.mn get]
            scan $h %d h; scan $m %d m
            set ${ns}::hour $h; set ${ns}::minute $m
            set timestr [format "%02d:%02d" $h $m]
            if {$o(-textvariable) ne {}} {
                set $o(-textvariable) $timestr
            } else {
                $w.ent delete 0 end; $w.ent insert 0 $timestr
            }
            destroy $pop
        }} $w $ns]
    pack $pop.f.ok -pady [ttkbootstrap::_sp2 0 8]

    set x [winfo rootx $w]
    set y [expr {[winfo rooty $w] + [winfo height $w] + 2}]
    # Let the popup auto-size based on its content
    update idletasks
    set _pw [winfo reqwidth $pop]
    set _ph [winfo reqheight $pop]
    # Add a small margin
    incr _pw [ttkbootstrap::_sp 16]
    incr _ph [ttkbootstrap::_sp 8]
    wm geometry $pop ${_pw}x${_ph}+$x+$y
    wm deiconify $pop
    raise $pop
    focus $pop
}

} ;# end namespace ttkbootstrap

# ── SVGToggleSwitch ───────────────────────────────────────────────────────────
# Animated toggle switch with SVG track and thumb.
#
# USAGE
#   ttkbootstrap::SVGToggleSwitch .ts \
#       -variable ::enabled -bootstyle success -text "Dark mode"
#
namespace eval ttkbootstrap {

proc SVGToggleSwitch {w args} {
    array set o {-variable {} -bootstyle success -text "" -command {} -shape round}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGToggleSwitch -bootstyle $o(-bootstyle)
    _validateEnum SVGToggleSwitch -shape $o(-shape) {round square}
    set ns ::ttkbootstrap::svgts::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::anim_pos 0.0

    if {$o(-variable) ne {} && ![info exists $o(-variable)]} {
        set $o(-variable) 0
    }

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]

    ttk::frame $w
    set trackW [ttkbootstrap::_sp 44]
    set trackH [ttkbootstrap::_sp 22]
    set ${ns}::trackW $trackW
    set ${ns}::trackH $trackH

    canvas $w.track -width $trackW -height $trackH \
        -highlightthickness 0 -bd 0 \
        -bg [ttkbootstrap::getColor bg] -cursor hand2
    pack $w.track -side left

    if {$o(-text) ne ""} {
        ttk::label $w.lbl -text $o(-text) -font [list $fn $fs]
        pack $w.lbl -side left -padx [ttkbootstrap::_sp 6]
    }

    bind $w.track <Button-1> [list ttkbootstrap::_svgts_toggle $w]
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgts_draw $w]

    if {$o(-variable) ne {}} {
        trace add variable $o(-variable) write \
            [list ttkbootstrap::_svgts_varchange $w]
        bind $w <Destroy> [list catch [list trace remove variable \
            $o(-variable) write [list ttkbootstrap::_svgts_varchange $w]]]
    }

    # Set initial position based on variable
    if {$o(-variable) ne {} && [set $o(-variable)]} {
        set ${ns}::anim_pos 1.0
    }
    after idle [list ttkbootstrap::_svgts_draw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgts
    return $w
}

proc _svgts_toggle {w} {
    set ns ::ttkbootstrap::svgts::$w
    array set o [set ${ns}::o]
    if {$o(-variable) ne {}} {
        set cur [set $o(-variable)]
        set $o(-variable) [expr {!$cur}]
    }
    if {$o(-command) ne {}} {
        uplevel #0 $o(-command)
    }
}

proc _svgts_varchange {w args} {
    after idle [list ttkbootstrap::_svgts_animate $w]
}

proc _svgts_animate {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgts::$w
    array set o [set ${ns}::o]
    set on [expr {$o(-variable) ne {} ? [set $o(-variable)] : 0}]
    set target [expr {$on ? 1.0 : 0.0}]
    set pos [set ${ns}::anim_pos]

    # Animate in steps
    if {abs($pos - $target) < 0.05} {
        set ${ns}::anim_pos $target
        _svgts_draw $w
        return
    }
    set step [expr {$on ? 0.15 : -0.15}]
    set newpos [expr {$pos + $step}]
    if {$newpos > 1.0} { set newpos 1.0 }
    if {$newpos < 0.0} { set newpos 0.0 }
    set ${ns}::anim_pos $newpos
    _svgts_draw $w
    after 12 [list ttkbootstrap::_svgts_animate $w]
}

proc _svgts_draw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgts::$w
    array set o [set ${ns}::o]
    set pos [set ${ns}::anim_pos]
    set trackW [set ${ns}::trackW]
    set trackH [set ${ns}::trackH]

    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor success] }
    set bg [ttkbootstrap::getColor bg]
    set bdr [ttkbootstrap::getColor border]
    set on [expr {$o(-variable) ne {} ? [set $o(-variable)] : 0}]

    set r [expr {$trackH / 2}]
    set thumbR [expr {$r - 2}]
    # Track colour interpolated between off (border) and on (bootstyle)
    set trackCol [expr {$pos > 0.5 ? $hex : $bdr}]

    # Single combined SVG: page-bg fill, then the track, then the thumb drawn
    # directly on top. Drawing the thumb in the same image (instead of as a
    # separate overlaid photo) avoids the white background box that a separate
    # thumb image would show around the circle on the coloured track.
    set thumbCX [expr {int($r + $pos * ($trackW - 2 * $r))}]
    set thumbCY [expr {$trackH / 2}]

    # No background fill: the corners outside the rounded track stay transparent
    # so the canvas background shows through cleanly on any parent surface.
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$trackW' height='$trackH'>"
    if {$o(-shape) eq "square"} {
        set sr [_sp 4]
        append svg "<rect x='1' y='1' width='[expr {$trackW-2}]' height='[expr {$trackH-2}]' rx='$sr' ry='$sr' fill='$trackCol'/>"
        set tr [_sp 3]
        set tx [expr {$thumbCX - $thumbR}]
        set ty [expr {$thumbCY - $thumbR}]
        append svg "<rect x='$tx' y='$ty' width='[expr {$thumbR*2}]' height='[expr {$thumbR*2}]' rx='$tr' ry='$tr' fill='white' stroke='#ccc' stroke-width='0.5'/>"
    } else {
        append svg "<rect x='1' y='1' width='[expr {$trackW-2}]' height='[expr {$trackH-2}]' rx='$r' ry='$r' fill='$trackCol'/>"
        append svg "<circle cx='$thumbCX' cy='$thumbCY' r='[expr {$thumbR-1}]' fill='white' stroke='#ccc' stroke-width='0.5'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::track_img }
    image create photo ${w}::track_img -data $svg -format {svg}

    $w.track delete all
    $w.track configure -bg $bg
    $w.track create image 0 0 -image ${w}::track_img -anchor nw
}

} ;# end namespace ttkbootstrap

# ── SVGProgressRing ───────────────────────────────────────────────────────────
# Circular progress/loading indicator with SVG arc.
#
# USAGE
#   set pr [ttkbootstrap::SVGProgressRing .pr -bootstyle primary -size 40]
#   ttkbootstrap::SVGProgressRing_set .pr 75   ;# 0-100
#   ttkbootstrap::SVGProgressRing_spin .pr     ;# indeterminate spin
#   ttkbootstrap::SVGProgressRing_stop .pr     ;# stop spinning
#
namespace eval ttkbootstrap {

proc SVGProgressRing {w args} {
    array set o {-bootstyle primary -size 0 -thickness 0 -value 0}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGProgressRing -bootstyle $o(-bootstyle)
    _validateRange SVGProgressRing -value $o(-value) 0 100
    set ns ::ttkbootstrap::svgpr::$w
    namespace eval $ns {}
    if {$o(-size) == 0} { set o(-size) [ttkbootstrap::_sp 40] }
    if {$o(-thickness) == 0} { set o(-thickness) [ttkbootstrap::_sp 4] }
    set ${ns}::o [array get o]
    set ${ns}::spinning 0
    set ${ns}::spin_angle 0

    label $w -bd 0 -highlightthickness 0 -bg [ttkbootstrap::getColor bg]
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgpr_draw $w]
    _svgpr_draw $w
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgpr
    return $w
}

proc SVGProgressRing_set {w value} {
    set ns ::ttkbootstrap::svgpr::$w
    array set o [set ${ns}::o]
    set o(-value) $value
    set ${ns}::o [array get o]
    _svgpr_draw $w
}

proc SVGProgressRing_spin {w} {
    set ns ::ttkbootstrap::svgpr::$w
    set ${ns}::spinning 1
    _svgpr_spin_tick $w
}

proc SVGProgressRing_stop {w} {
    set ns ::ttkbootstrap::svgpr::$w
    set ${ns}::spinning 0
}

proc _svgpr_spin_tick {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgpr::$w
    if {![set ${ns}::spinning]} return
    set ${ns}::spin_angle [expr {([set ${ns}::spin_angle] + 8) % 360}]
    _svgpr_draw $w 1
    after 30 [list ttkbootstrap::_svgpr_spin_tick $w]
}

proc _svgpr_draw {w {spinning 0}} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgpr::$w
    array set o [set ${ns}::o]
    set sz $o(-size)
    set th $o(-thickness)
    set hex [ttkbootstrap::getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
    set bg [ttkbootstrap::getColor bg]
    set trk [ttkbootstrap::_lighten $hex 35]

    set cx [expr {$sz / 2.0}]
    set r [expr {$cx - $th / 2.0 - 1}]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>"
    append svg "<rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>"
    # Track ring
    append svg "<circle cx='$cx' cy='$cx' r='$r' fill='none' stroke='$trk' stroke-width='$th'/>"

    if {$spinning || [set ${ns}::spinning]} {
        # Spinning arc (90 degrees)
        set startA [set ${ns}::spin_angle]
        set endA [expr {$startA + 90}]
    } else {
        # Determinate arc
        set pct [expr {min(100, max(0, $o(-value)))}]
        set startA -90
        set endA [expr {-90 + $pct * 3.6}]
    }

    # Draw arc as SVG path
    set startRad [expr {$startA * 3.14159265 / 180.0}]
    set endRad [expr {$endA * 3.14159265 / 180.0}]
    set x1 [expr {$cx + $r * cos($startRad)}]
    set y1 [expr {$cx + $r * sin($startRad)}]
    set x2 [expr {$cx + $r * cos($endRad)}]
    set y2 [expr {$cx + $r * sin($endRad)}]
    set largeArc [expr {abs($endA - $startA) > 180 ? 1 : 0}]
    append svg "<path d='M $x1 $y1 A $r $r 0 $largeArc 1 $x2 $y2' fill='none' stroke='$hex' stroke-width='$th' stroke-linecap='round'/>"
    append svg "</svg>"

    catch { image delete ${w}::ring }
    image create photo ${w}::ring -data $svg -format {svg}
    $w configure -image ${w}::ring -bg $bg
}

} ;# end namespace ttkbootstrap

# ── SVGIcon ───────────────────────────────────────────────────────────────────
# Built-in SVG icon library. Returns a photo image at the given size.
#
# USAGE
#   set img [ttkbootstrap::SVGIcon home -size 24 -colour "#333"]
#   label .l -image $img
#
namespace eval ttkbootstrap {

variable _svgicon_cache
array set _svgicon_cache {}

variable _svgicon_paths
array set _svgicon_paths {
    home        "M3 12L5 10V19A1 1 0 006 20H10V14H14V20H18A1 1 0 0019 19V10L21 12L12 3L3 12Z"
    settings    "M12 15A3 3 0 1012 9A3 3 0 1012 15ZM19.4 15A1.6 1.6 0 0019.7 16.8L19.8 16.9A2 2 0 1117 19.7L16.9 19.6A1.6 1.6 0 0015 19.4A1.6 1.6 0 0014 20.9V21A2 2 0 1110 21V20.9A1.6 1.6 0 009 19.4A1.6 1.6 0 007.1 19.6L7 19.7A2 2 0 114.3 16.9L4.4 16.8A1.6 1.6 0 004.6 15A1.6 1.6 0 003.1 14H3A2 2 0 113 10H3.1A1.6 1.6 0 004.6 9A1.6 1.6 0 004.4 7.2L4.3 7.1A2 2 0 117 4.3L7.1 4.4A1.6 1.6 0 009 4.6A1.6 1.6 0 0010 3.1V3A2 2 0 1114 3V3.1A1.6 1.6 0 0015 4.6A1.6 1.6 0 0016.8 4.4L16.9 4.3A2 2 0 1119.7 7L19.6 7.1A1.6 1.6 0 0019.4 9A1.6 1.6 0 0020.9 10H21A2 2 0 1121 14H20.9A1.6 1.6 0 0019.4 15Z"
    search      "M21 21L16.7 16.7M11 4A7 7 0 1111 18A7 7 0 1111 4Z"
    user        "M20 21V19A4 4 0 0016 15H8A4 4 0 004 19V21M12 11A4 4 0 1012 3A4 4 0 1012 11Z"
    mail        "M4 4H20A2 2 0 0122 6V18A2 2 0 0120 20H4A2 2 0 012 18V6A2 2 0 014 4ZM22 6L12 13L2 6"
    check       "M20 6L9 17L4 12"
    close       "M18 6L6 18M6 6L18 18"
    plus        "M12 5V19M5 12H19"
    minus       "M5 12H19"
    chevron_r   "M9 18L15 12L9 6"
    chevron_l   "M15 18L9 12L15 6"
    chevron_d   "M6 9L12 15L18 9"
    chevron_u   "M18 15L12 9L6 15"
    edit        "M11 4H4A2 2 0 002 6V20A2 2 0 004 22H18A2 2 0 0020 20V13M18.5 2.5A2.1 2.1 0 0121.5 5.5L12 15L8 16L9 12L18.5 2.5Z"
    trash       "M3 6H5H21M19 6V20A2 2 0 0117 22H7A2 2 0 015 20V6M8 6V4A2 2 0 0110 2H14A2 2 0 0116 4V6M10 11V17M14 11V17"
    save        "M19 21H5A2 2 0 013 19V5A2 2 0 015 3H16L21 8V19A2 2 0 0119 21ZM17 21V13H7V21M7 3V8H15"
    download    "M21 15V19A2 2 0 0119 21H5A2 2 0 013 19V15M7 10L12 15L17 10M12 15V3"
    upload      "M21 15V19A2 2 0 0119 21H5A2 2 0 013 19V15M17 8L12 3L7 8M12 3V15"
    calendar    "M19 4H5A2 2 0 003 6V20A2 2 0 005 22H19A2 2 0 0021 20V6A2 2 0 0019 4ZM16 2V6M8 2V6M3 10H21M8 14H8.01M12 14H12.01M16 14H16.01M8 18H8.01M12 18H12.01M16 18H16.01"
    clock       "M12 2A10 10 0 1012 22A10 10 0 1012 2ZM12 6V12L16 14"
    star        "M12 2L15.1 8.3L22 9.2L17 14.1L18.2 21L12 17.8L5.8 21L7 14.1L2 9.2L8.9 8.3L12 2Z"
    heart       "M20.8 4.6A5.5 5.5 0 0013 4.6L12 5.7L11 4.6A5.5 5.5 0 003.2 4.6A5.5 5.5 0 003.2 12.4L12 21.3L20.8 12.4A5.5 5.5 0 0020.8 4.6Z"
    bell        "M18 8A6 6 0 006 8C6 15 3 17 3 17H21S18 15 18 8ZM13.7 21A2 2 0 0110.3 21M12 2V4"
    info        "M12 2A10 10 0 1012 22A10 10 0 1012 2ZM12 16V12M12 8H12.01"
    warning     "M10.3 2.3L1.4 18A2 2 0 003.2 21H20.8A2 2 0 0022.6 18L13.7 2.3A2 2 0 0010.3 2.3ZM12 9V13M12 17H12.01"
    error       "M12 2A10 10 0 1012 22A10 10 0 1012 2ZM15 9L9 15M9 9L15 15"
    folder      "M22 19A2 2 0 0120 21H4A2 2 0 012 19V5A2 2 0 014 3H9L11 5H20A2 2 0 0122 7V19Z"
    file        "M13 2H6A2 2 0 004 4V20A2 2 0 006 22H18A2 2 0 0020 20V9L13 2ZM13 2V9H20"
    refresh     "M23 4V10H17M1 20V14H7M3.5 9A9 9 0 0118.4 5.6L23 10M1 14L5.6 18.4A9 9 0 0020.5 15"
    lock        "M19 11H5A2 2 0 003 13V20A2 2 0 005 22H19A2 2 0 0021 20V13A2 2 0 0019 11ZM7 11V7A5 5 0 0117 7V11M12 15V18"
    logout      "M9 21H5A2 2 0 013 19V5A2 2 0 015 3H9M16 17L21 12L16 7M21 12H9"
    database    "M12 2C7.6 2 4 3.8 4 6S7.6 10 12 10S20 8.2 20 6S16.4 2 12 2ZM4 6V12C4 14.2 7.6 16 12 16S20 14.2 20 12V6M4 12V18C4 20.2 7.6 22 12 22S20 20.2 20 18V12"
}

proc SVGIcon {name args} {
    variable _svgicon_paths
    variable _svgicon_cache

    array set o {-size 0 -colour ""}
    array set o $args
    if {$o(-size) == 0} { set o(-size) [_sp 20] }
    if {$o(-colour) eq ""} { set o(-colour) [getColor fg] }

    set key "${name}_$o(-size)_$o(-colour)"
    if {[info exists _svgicon_cache($key)]} {
        return $_svgicon_cache($key)
    }

    if {![info exists _svgicon_paths($name)]} {
        error "Unknown icon: $name. Available: [lsort [array names _svgicon_paths]]"
    }

    set path $_svgicon_paths($name)
    set sz $o(-size)
    set scale [expr {$sz / 24.0}]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz' viewBox='0 0 24 24'>"
    append svg "<path d='$path' fill='none' stroke='$o(-colour)' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>"
    append svg "</svg>"

    set img [image create photo _svgicon_$key -data $svg -format {svg}]
    set _svgicon_cache($key) $img
    return $img
}

proc SVGIconNames {} {
    variable _svgicon_paths
    return [lsort [array names _svgicon_paths]]
}

proc SVGIconFlush {} {
    variable _svgicon_cache
    foreach key [array names _svgicon_cache] {
        catch { image delete $_svgicon_cache($key) }
    }
    array unset _svgicon_cache
    array set _svgicon_cache {}
}

} ;# end namespace ttkbootstrap

# ── SVGCombobox ───────────────────────────────────────────────────────────────
# Combobox with SVG pill-shaped border matching SVGEntry.
#
# USAGE
#   ttkbootstrap::SVGCombobox .cb \
#       -values {Red Green Blue} -bootstyle primary
#
namespace eval ttkbootstrap {

proc SVGCombobox {w args} {
    array set o {-bootstyle primary -values {} -textvariable {} -width 20 -height 0 -radius -1}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGCombobox -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgcb::$w
    namespace eval $ns {}

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]
    if {$o(-height) == 0} {
        set ls [font metrics [list $fn $fs] -linespace]
        set o(-height) [expr {$ls + [_sp 12]}]
    }
    # Pill by default: radius = half the inner height (border rect inset 1px).
    if {$o(-radius) < 0} { set o(-radius) [expr {($o(-height) - 2) / 2.0}] }
    set capR [expr {int(ceil($o(-radius)))}]

    # Store as svge-compatible options so we can reuse _svge_gen. Widen by the
    # two caps so the field keeps its text capacity on a pill.
    set ew [expr {[font measure [list $fn $fs] "0"] * $o(-width) + [_sp 20] + 2 * $capR}]
    set ${ns}::o [array get o]
    set ${ns}::W $ew
    set ${ns}::H $o(-height)
    set ${ns}::focus 0

    # Reuse SVGEntry's border generation
    # _svge_gen reads from ::ttkbootstrap::svge::$w but we use svgcb
    # So create the SVG inline using the same approach
    set bg [getColor bg]
    set inputbg [getColor inputbg]
    set hex [getColor $o(-bootstyle)]
    set bdr [getColor border]
    set r $o(-radius)

    frame $w -highlightthickness 0 -bd 0 -width $ew -height $o(-height) -bg $bg
    pack propagate $w 0

    # Normal border SVG — no bg fill so rounded corners are transparent
    set svg_n "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$o(-height)'>"
    append svg_n "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$o(-height)-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$bdr' stroke-width='1'/>"
    append svg_n "</svg>"
    image create photo ${w}::img_n -data $svg_n -format {svg}

    # Focused border SVG
    set svg_f "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$o(-height)'>"
    append svg_f "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$o(-height)-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$hex' stroke-width='1.5'/>"
    append svg_f "</svg>"
    image create photo ${w}::img_f -data $svg_f -format {svg}

    label $w.bg -image ${w}::img_n -bd 0 -highlightthickness 0 -bg $bg \
        -anchor nw -width $ew -height $o(-height)
    place $w.bg -x 0 -y 0 -width $ew -height $o(-height)

    ttk::combobox $w.cb -width $o(-width)         -font [list $fn $fs]         -values $o(-values)         -style flat.TCombobox
    if {$o(-textvariable) ne {}} {
        $w.cb configure -textvariable $o(-textvariable)
    }

    catch {
        ttk::style configure flat.TCombobox \
            -fieldbackground $inputbg -background $inputbg \
            -bordercolor $inputbg -lightcolor $inputbg -darkcolor $inputbg \
            -foreground [getColor fg] -arrowcolor [getColor fg] \
            -borderwidth 0 -relief flat -padding [_sp2 6 4]
        # The base TCombobox style MAPS the field border to the focus colour on
        # focus, which paints a rectangle inside the pill. Override the map so
        # every state keeps inputbg — the SVG pill supplies the focus border.
        ttk::style map flat.TCombobox \
            -bordercolor [list focus $inputbg active $inputbg readonly $inputbg] \
            -lightcolor  [list focus $inputbg active $inputbg readonly $inputbg] \
            -darkcolor   [list focus $inputbg active $inputbg readonly $inputbg] \
            -fieldbackground [list focus $inputbg readonly $inputbg disabled $inputbg] \
            -arrowcolor [list focus [getColor fg] active [getColor fg]]
        # Definitive fix: drop Combobox.field from the layout entirely, so there
        # is no field element left to draw a focus/border rectangle inside the
        # SVG pill. The pill's colour swap (img_f) is the focus indicator.
        ttk::style layout flat.TCombobox {
            Combobox.downarrow -side right -sticky ns
            Combobox.padding -sticky nswe -children {
                Combobox.textarea -sticky nswe
            }
        }
    }

    pack $w.cb -fill both -expand 1 -padx $capR -pady [_sp 3]

    bind $w.cb <FocusIn>  [list apply {{w} {
        $w.bg configure -image ${w}::img_f
    }} $w]
    bind $w.cb <FocusOut> [list apply {{w} {
        $w.bg configure -image ${w}::img_n
    }} $w]

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgcb_retheme $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgcb
    return $w
}

proc _svgcb_retheme {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgcb::$w
    array set o [set ${ns}::o]
    set bg [getColor bg]
    set inputbg [getColor inputbg]
    set hex [getColor $o(-bootstyle)]
    set bdr [getColor border]
    set r $o(-radius)
    set ew [set ${ns}::W]
    set H [set ${ns}::H]

    $w configure -bg $bg
    $w.bg configure -bg $bg

    # The combobox field/arrow/text live in the shared flat.TCombobox style,
    # not the SVG pill — refresh it or the input box stays a stale white box
    # on dark themes. Popdown listbox colours are option-db driven.
    catch {
        ttk::style configure flat.TCombobox \
            -fieldbackground $inputbg -background $inputbg \
            -bordercolor $inputbg -lightcolor $inputbg -darkcolor $inputbg \
            -foreground [getColor fg] -arrowcolor [getColor fg] \
            -borderwidth 0 -relief flat -padding [_sp2 6 4]
    }
    catch {
        option add *flat.TCombobox*Listbox.background $inputbg
        option add *flat.TCombobox*Listbox.foreground [getColor fg]
        option add *flat.TCombobox*Listbox.selectBackground $hex
        option add *flat.TCombobox*Listbox.selectForeground [_contrastFg $hex]
    }

    set svg_n "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'><rect x='0' y='0' width='$ew' height='$H' fill='$bg'/>"  ;# bgfill_done
    append svg_n "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$bdr' stroke-width='1'/>"
    append svg_n "</svg>"
    catch { image delete ${w}::img_n }
    image create photo ${w}::img_n -data $svg_n -format {svg}

    set svg_f "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'><rect x='0' y='0' width='$ew' height='$H' fill='$bg'/>"  ;# bgfill_done
    append svg_f "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$hex' stroke-width='1.5'/>"
    append svg_f "</svg>"
    catch { image delete ${w}::img_f }
    image create photo ${w}::img_f -data $svg_f -format {svg}

    $w.bg configure -image ${w}::img_n
}

} ;# end namespace ttkbootstrap

# ── SVGSpinbox ────────────────────────────────────────────────────────────────
# Spinbox with SVG pill-shaped border matching SVGEntry.
#
# USAGE
#   ttkbootstrap::SVGSpinbox .sp -from 0 -to 100 -bootstyle primary
#
namespace eval ttkbootstrap {

proc SVGSpinbox {w args} {
    array set o {-bootstyle primary -from 0 -to 100 -textvariable {}
                 -width 10 -height 0 -radius -1 -wrap 0 -format ""}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGSpinbox -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgspb::$w
    namespace eval $ns {}

    set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs [ttkbootstrap::_sf 12]
    if {$o(-height) == 0} {
        set ls [font metrics [list $fn $fs] -linespace]
        set o(-height) [expr {$ls + [_sp 18]}]
    }
    # Pill by default: radius = half the inner height (border rect inset 1px).
    if {$o(-radius) < 0} { set o(-radius) [expr {($o(-height) - 2) / 2.0}] }
    set capR [expr {int(ceil($o(-radius)))}]

    set ${ns}::o [array get o]
    set bg [getColor bg]
    set inputbg [getColor inputbg]
    set hex [getColor $o(-bootstyle)]
    set bdr [getColor border]
    set r $o(-radius)

    set ew [expr {[font measure [list $fn $fs] "0"] * $o(-width) + [_sp 30] + 2 * $capR}]
    set ${ns}::W $ew
    set ${ns}::H $o(-height)

    frame $w -highlightthickness 0 -bd 0 -width $ew -height $o(-height) -bg $bg
    pack propagate $w 0

    # Normal border
    set svg_n "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$o(-height)'><rect x='0' y='0' width='$ew' height='$o(-height)' fill='$bg'/>"  ;# bgfill_done
    append svg_n "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$o(-height)-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$bdr' stroke-width='1'/>"
    append svg_n "</svg>"
    image create photo ${w}::img_n -data $svg_n -format {svg}

    # Focused border
    set svg_f "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$o(-height)'><rect x='0' y='0' width='$ew' height='$o(-height)' fill='$bg'/>"  ;# bgfill_done
    append svg_f "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$o(-height)-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$hex' stroke-width='1.5'/>"
    append svg_f "</svg>"
    image create photo ${w}::img_f -data $svg_f -format {svg}

    label $w.bg -image ${w}::img_n -bd 0 -highlightthickness 0 -bg $bg \
        -anchor nw -width $ew -height $o(-height)
    place $w.bg -x 0 -y 0 -width $ew -height $o(-height)

    # Flat style so the spinbox does not paint its own bordered field/arrow
    # box over the SVG pill (blend border + arrow background into inputbg).
    set fg [getColor fg]
    catch {
        ttk::style configure flat.TSpinbox \
            -fieldbackground $inputbg -background $inputbg \
            -bordercolor $inputbg -lightcolor $inputbg -darkcolor $inputbg \
            -foreground $fg -arrowcolor $fg \
            -borderwidth 0 -relief flat -arrowsize [_sp 12] -padding [_sp2 6 4]
        # The base TSpinbox style maps the field border to the focus colour on
        # focus (a rectangle inside the pill). Override the map to keep inputbg
        # in every state; the SVG pill supplies the focus border.
        ttk::style map flat.TSpinbox \
            -bordercolor [list focus $inputbg active $inputbg readonly $inputbg] \
            -lightcolor  [list focus $inputbg active $inputbg readonly $inputbg] \
            -darkcolor   [list focus $inputbg active $inputbg readonly $inputbg] \
            -fieldbackground [list focus $inputbg readonly $inputbg disabled $inputbg] \
            -arrowcolor [list focus $fg active $fg]
        # Definitive fix: drop Spinbox.field from the layout entirely, so there
        # is no field element left to draw a focus/border rectangle inside the
        # SVG pill. The pill's colour swap (img_f) is the focus indicator.
        ttk::style layout flat.TSpinbox {
            null -side right -sticky {} -children {
                Spinbox.uparrow -side top -sticky e
                Spinbox.downarrow -side bottom -sticky e
            }
            Spinbox.padding -sticky nswe -children {
                Spinbox.textarea -sticky nswe
            }
        }
    }
    set scmd [list ttk::spinbox $w.sp -from $o(-from) -to $o(-to)         -width $o(-width) -font [list $fn $fs]         -style "flat.TSpinbox"]
    if {$o(-wrap)} { lappend scmd -wrap 1 }
    if {$o(-format) ne ""} { lappend scmd -format $o(-format) }
    if {$o(-textvariable) ne {}} { lappend scmd -textvariable $o(-textvariable) }
    {*}$scmd

    pack $w.sp -fill both -expand 1 -padx $capR -pady [_sp 3]

    bind $w.sp <FocusIn>  [list apply {{w} {
        $w.bg configure -image ${w}::img_f
    }} $w]
    bind $w.sp <FocusOut> [list apply {{w} {
        $w.bg configure -image ${w}::img_n
    }} $w]

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgspb_retheme $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgspb
    return $w
}

proc _svgspb_retheme {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgspb::$w
    array set o [set ${ns}::o]
    set bg [getColor bg]
    set inputbg [getColor inputbg]
    set hex [getColor $o(-bootstyle)]
    set bdr [getColor border]
    set fg [getColor fg]
    set r $o(-radius)
    set ew [set ${ns}::W]
    set H  [set ${ns}::H]

    $w configure -bg $bg
    $w.bg configure -bg $bg

    catch {
        ttk::style configure flat.TSpinbox \
            -fieldbackground $inputbg -background $inputbg \
            -bordercolor $inputbg -lightcolor $inputbg -darkcolor $inputbg \
            -foreground $fg -arrowcolor $fg \
            -borderwidth 0 -relief flat
    }

    # Regenerate the pill photos (they bake in inputbg / border / hex).
    set svg_n "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'><rect x='0' y='0' width='$ew' height='$H' fill='$bg'/>"  ;# bgfill_done
    append svg_n "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$bdr' stroke-width='1'/>"
    append svg_n "</svg>"
    catch { image delete ${w}::img_n }
    image create photo ${w}::img_n -data $svg_n -format {svg}

    set svg_f "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'><rect x='0' y='0' width='$ew' height='$H' fill='$bg'/>"  ;# bgfill_done
    append svg_f "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$r' ry='$r' fill='$inputbg' stroke='$hex' stroke-width='1.5'/>"
    append svg_f "</svg>"
    catch { image delete ${w}::img_f }
    image create photo ${w}::img_f -data $svg_f -format {svg}

    $w.bg configure -image ${w}::img_n
}

} ;# end namespace ttkbootstrap

# ── SVGFormField ──────────────────────────────────────────────────────────────
# Form field wrapper: label + SVGEntry + validation message.
#
# USAGE
#   ttkbootstrap::SVGFormField .f \
#       -label "Email" -placeholder "user@example.com" \
#       -validate {regexp {.+@.+\..+} $value} \
#       -validmsg "Valid email" -invalidmsg "Invalid email address"
#
namespace eval ttkbootstrap {

proc SVGFormField {w args} {
    array set o {-label "" -bootstyle primary -textvariable {}
                 -validate {} -validmsg "" -invalidmsg "" -placeholder ""
                 -width 25}
    array set o $args
    _validateBootstyle SVGFormField -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgff::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::valid -1

    set fn [_safeFont [getColor font]]
    set fs [_sf 12]

    ttk::frame $w

    if {$o(-label) ne ""} {
        ttk::label $w.lbl -text $o(-label) \
            -font [list $fn $fs bold] \
            -foreground [getColor fg]
        pack $w.lbl -anchor w -pady [_sp2 0 2]
    }

    SVGEntry $w.ent -bootstyle $o(-bootstyle) \
        -width $o(-width)
    if {$o(-textvariable) ne {}} {
        $w.ent.ent configure -textvariable $o(-textvariable)
    }
    if {$o(-placeholder) ne {}} {
        catch { $w.ent.ent configure -placeholder $o(-placeholder) }
    }
    pack $w.ent -fill x

    ttk::label $w.msg -text "" \
        -font [list $fn [_sf 10]] \
        -foreground [getColor secondary]
    pack $w.msg -anchor w -pady [_sp2 2 0]

    # Validation on key release
    if {$o(-validate) ne {}} {
        bind $w.ent.ent <KeyRelease> [list ttkbootstrap::_svgff_validate $w]
    }

    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgff
    return $w
}

proc _svgff_validate {w} {
    set ns ::ttkbootstrap::svgff::$w
    array set o [set ${ns}::o]
    set value [$w.ent.ent get]

    if {$value eq ""} {
        $w.msg configure -text "" -foreground [getColor secondary]
        set ${ns}::valid -1
        return
    }

    set valid [uplevel #0 [list apply [list {value} $o(-validate)] $value]]
    set ${ns}::valid $valid

    if {$valid} {
        $w.msg configure -text $o(-validmsg) \
            -foreground [getColor success]
    } else {
        $w.msg configure -text $o(-invalidmsg) \
            -foreground [getColor danger]
    }
}

namespace eval SVGFormField {
    proc isValid {w} {
        ::set ns ::ttkbootstrap::svgff::$w
        return [::set ${ns}::valid]
    }
    proc getValue {w} {
        return [$w.ent.ent get]
    }
}

} ;# end namespace ttkbootstrap

# ── SVGColourPicker ───────────────────────────────────────────────────────────
# Colour palette picker with SVG swatches.
#
# USAGE
#   ttkbootstrap::SVGColourPicker .cp -variable ::mycolour -bootstyle primary
#
namespace eval ttkbootstrap {

proc SVGColourPicker {w args} {
    array set o {-variable {} -bootstyle primary -columns 8}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGColourPicker -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgcp::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    if {$o(-variable) ne {} && ![info exists $o(-variable)]} {
        set $o(-variable) "#000000"
    }

    set bg [getColor bg]
    ttk::frame $w

    # Material Design colour palette
    set palette {
        "#F44336" "#E91E63" "#9C27B0" "#673AB7" "#3F51B5" "#2196F3" "#03A9F4" "#00BCD4"
        "#009688" "#4CAF50" "#8BC34A" "#CDDC39" "#FFEB3B" "#FFC107" "#FF9800" "#FF5722"
        "#795548" "#9E9E9E" "#607D8B" "#000000" "#333333" "#666666" "#999999" "#CCCCCC"
        "#FFFFFF" "#F5F5F5" "#E0E0E0" "#BDBDBD" "#757575" "#424242" "#212121" "#263238"
    }

    set swsz [_sp 24]
    set r [_sp 3]
    set col 0
    set row 0

    foreach colour $palette {
        set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$swsz' height='$swsz'>"
        append svg "<rect x='0' y='0' width='$swsz' height='$swsz' fill='$bg'/>"
        append svg "<rect x='1' y='1' width='[expr {$swsz-2}]' height='[expr {$swsz-2}]' rx='$r' ry='$r' fill='$colour' stroke='[getColor border]' stroke-width='0.5'/>"
        append svg "</svg>"

        set imgname ${w}::sw_${row}_${col}
        catch { image delete $imgname }
        image create photo $imgname -data $svg -format {svg}

        label $w.sw_${row}_${col} -image $imgname -bd 0 \
            -highlightthickness 0 -bg $bg -cursor hand2
        grid $w.sw_${row}_${col} -row $row -column $col \
            -padx [_sp 1] -pady [_sp 1]

        bind $w.sw_${row}_${col} <Button-1> \
            [list ttkbootstrap::_svgcp_select $w $colour]

        incr col
        if {$col >= $o(-columns)} { set col 0; incr row }
    }

    # Selected colour display
    ttk::label $w.sel -text "Selected:" \
        -font [list [_safeFont [getColor font]] [_sf 11]]
    grid $w.sel -row [expr {$row + 1}] -column 0 -columnspan 3 \
        -sticky w -pady [_sp2 4 0]

    label $w.preview -width [_sp 6] -height [_sp 2] -bd 1 -relief solid
    grid $w.preview -row [expr {$row + 1}] -column 3 -columnspan 2 \
        -sticky w -pady [_sp2 4 0]

    ttk::label $w.hex -text "" \
        -font [list [_safeFont [getColor font]] [_sf 11]]
    grid $w.hex -row [expr {$row + 1}] -column 5 -columnspan 3 \
        -sticky w -pady [_sp2 4 0]

    if {$o(-variable) ne {}} {
        _svgcp_select $w [set $o(-variable)]
    }

    bind $w <<ThemeChanged>> [list apply {{w} {
        $w.preview configure -bg [ttkbootstrap::getColor bg]
    }} $w]

    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgcp
    return $w
}

proc _svgcp_select {w colour} {
    set ns ::ttkbootstrap::svgcp::$w
    array set o [set ${ns}::o]
    $w.preview configure -bg $colour
    $w.hex configure -text $colour
    if {$o(-variable) ne {}} {
        set $o(-variable) $colour
    }
}

} ;# end namespace ttkbootstrap

# ── SVGNotificationBanner ─────────────────────────────────────────────────────
# Slide-in notification with SVG rounded corners and shadow.
#
# USAGE
#   ttkbootstrap::SVGNotificationBanner::show \
#       -title "Success" -message "File saved." \
#       -bootstyle success -duration 3000 -position topright
#
namespace eval ttkbootstrap {

# Slide-in animation for notification banners: eases the toplevel from startx
# to targetx over the given number of steps.
proc _svgnb_slide {pop startx targetx y step steps} {
    if {![winfo exists $pop]} return
    if {$step >= $steps} {
        catch { wm geometry $pop +$targetx+$y }
        return
    }
    # Ease-out: fraction of the remaining distance covered each step grows.
    set t [expr {($step + 1.0) / $steps}]
    set ease [expr {1.0 - (1.0 - $t) * (1.0 - $t)}]
    set cur [expr {int($startx + ($targetx - $startx) * $ease)}]
    catch { wm geometry $pop +$cur+$y }
    after 16 [list ttkbootstrap::_svgnb_slide $pop $startx $targetx $y [expr {$step + 1}] $steps]
}

# Slide-in for an in-parent (place-managed) banner: eases its place -x from
# startx to targetx. The parent widget clips the part still off its edge.
proc _svgnb_slideChild {f startx targetx y step steps} {
    if {![winfo exists $f]} return
    if {$step >= $steps} {
        catch { place $f -x $targetx -y $y }
        return
    }
    set t [expr {($step + 1.0) / $steps}]
    set ease [expr {1.0 - (1.0 - $t) * (1.0 - $t)}]
    set cur [expr {int($startx + ($targetx - $startx) * $ease)}]
    catch { place $f -x $cur -y $y }
    after 16 [list ttkbootstrap::_svgnb_slideChild $f $startx $targetx $y [expr {$step + 1}] $steps]
}

namespace eval SVGNotificationBanner {
    proc show {args} {
        array set o {-title "" -message "" -bootstyle info -duration 3000 -position topright -parent ""}
        array set o $args

        # If a -parent widget is given, render the banner as a child placed
        # inside that widget. The parent clips the overflow, so the banner can
        # start fully hidden off the parent's edge and visibly slide into view.
        if {$o(-parent) ne "" && [winfo exists $o(-parent)]} {
            return [_showInParent o]
        }

        set hex [ttkbootstrap::getColor $o(-bootstyle)]
        if {$hex eq ""} { set hex [ttkbootstrap::getColor info] }
        set bg [ttkbootstrap::getColor bg]
        set fg [ttkbootstrap::getColor fg]
        set cfgfg [ttkbootstrap::_contrastFg $hex]
        set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]

        # Create popup
        set id [clock microseconds]
        set pop .svgnb_$id
        catch { destroy $pop }
        toplevel $pop -bg $bg
        wm overrideredirect $pop 1
        catch { wm attributes $pop -topmost 1 }
        if {[tk windowingsystem] eq "aqua"} {
            catch { wm attributes $pop -type utility }
        }
        wm withdraw $pop

        set W [ttkbootstrap::_sp 300]
        set H [ttkbootstrap::_sp 80]
        set r 0
        set shadow [ttkbootstrap::_sp 3]

        # -transparentcolor is honoured only on Windows; harmless elsewhere.
        # On X11/aqua the sharp-cornered card (r=0) already fills the toplevel
        # exactly, so no background shows through.
        catch { wm attributes $pop -transparentcolor $bg }

        # Canvas for SVG background
        $pop configure -bg $bg
        canvas $pop.c -width [expr {$W + $shadow}] -height [expr {$H + $shadow}] \
            -highlightthickness 0 -bd 0 -bg $bg

        # Single SVG with shadow + card + accent bar
        set totalW [expr {$W + $shadow}]
        set totalH [expr {$H + $shadow}]
        set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$totalW' height='$totalH'>"
        # Shadow
        append svg "<rect x='$shadow' y='$shadow' width='$W' height='$H' rx='$r' ry='$r' fill='[ttkbootstrap::_darken $bg 15]'/>"
        # Card body
        append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$bg' stroke='$hex' stroke-width='1.5'/>"
        # Coloured left accent bar (two overlapping rects for rounded left edge)
        set barW [ttkbootstrap::_sp 6]
        append svg "<rect x='0' y='0' width='[expr {$barW + $r}]' height='$H' rx='$r' ry='$r' fill='$hex'/>"
        append svg "<rect x='$r' y='0' width='$barW' height='$H' fill='$hex'/>"
        append svg "</svg>"
        catch { image delete ${pop}::card }
        image create photo ${pop}::card -data $svg -format {svg}
        $pop.c create image 0 0 -image ${pop}::card -anchor nw

        # Title text
        $pop.c create text [ttkbootstrap::_sp 16] [ttkbootstrap::_sp 14] \
            -text $o(-title) -fill $fg \
            -font [list $fn [ttkbootstrap::_sf 12] bold] -anchor nw

        # Message text
        $pop.c create text [ttkbootstrap::_sp 16] [ttkbootstrap::_sp 36] \
            -text $o(-message) -fill [ttkbootstrap::getColor secondary] \
            -font [list $fn [ttkbootstrap::_sf 11]] -anchor nw \
            -width [expr {$W - [ttkbootstrap::_sp 32]}]

        # Close button
        $pop.c create text [expr {$W - [ttkbootstrap::_sp 14]}] [ttkbootstrap::_sp 10] \
            -text "\u00d7" -fill [ttkbootstrap::getColor secondary] \
            -font [list $fn [ttkbootstrap::_sf 14]] -anchor ne -tags closebtn
        $pop.c bind closebtn <Button-1> [list destroy $pop]

        pack $pop.c

        # Position relative to the main application window
        set main .
        catch { set main [winfo toplevel [focus]] }
        if {$main eq "" || ![winfo exists $main]} { set main . }
        set wx [winfo rootx $main]
        set wy [winfo rooty $main]
        set ww [winfo width $main]
        set pad [ttkbootstrap::_sp 20]
        switch $o(-position) {
            topright  { set x [expr {$wx + $ww - $W - $pad - $shadow}]; set y [expr {$wy + $pad}] }
            topleft   { set x [expr {$wx + $pad}]; set y [expr {$wy + $pad}] }
            default   { set x [expr {$wx + $ww - $W - $pad - $shadow}]; set y [expr {$wy + $pad}] }
        }

        # Clamp to the visible screen so the banner never lands off-screen
        # (e.g. when the app window straddles a monitor edge).
        set scrW [winfo screenwidth $pop]
        set scrH [winfo screenheight $pop]
        if {$x < 0} { set x 0 }
        if {$y < 0} { set y 0 }
        if {$x + $W + $shadow > $scrW} { set x [expr {$scrW - $W - $shadow}] }
        if {$y + $H + $shadow > $scrH} { set y [expr {$scrH - $H - $shadow}] }
        if {$x < 0} { set x 0 }
        if {$y < 0} { set y 0 }

        # Slide-in animation: start with the banner flush against the window's
        # edge (its outer edge aligned to the window edge, so it is fully inside
        # the window and never spills outside) and glide inward to the padded
        # resting position $x. Works for any window size.
        switch $o(-position) {
            topleft   { set startx [expr {$wx}] }
            default   { set startx [expr {$wx + $ww - $W - $shadow}] }
        }
        wm geometry $pop +$startx+$y
        wm deiconify $pop
        raise $pop

        # Animate from startx to the target x over ~12 steps.
        ttkbootstrap::_svgnb_slide $pop $startx $x $y 0 12

        # Auto-close
        if {$o(-duration) > 0} {
            after $o(-duration) [list catch [list destroy $pop]]
        }
    }

    # Render the banner as a child placed inside -parent. The parent widget
    # clips anything outside its bounds, so the banner starts fully hidden off
    # the edge and slides into view. Returns the banner frame path.
    proc _showInParent {ovar} {
        upvar 1 $ovar o

        set parent $o(-parent)
        set hex [ttkbootstrap::getColor $o(-bootstyle)]
        if {$hex eq ""} { set hex [ttkbootstrap::getColor info] }
        set bg  [ttkbootstrap::getColor bg]
        set fg  [ttkbootstrap::getColor fg]
        set fn  [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]

        set W [ttkbootstrap::_sp 300]
        set H [ttkbootstrap::_sp 80]
        set r 0
        set shadow [ttkbootstrap::_sp 3]
        set totalW [expr {$W + $shadow}]
        set totalH [expr {$H + $shadow}]

        set id [clock microseconds]
        set f $parent.svgnb_$id
        catch { destroy $f }
        frame $f -bd 0 -highlightthickness 0 -bg $bg
        canvas $f.c -width $totalW -height $totalH -highlightthickness 0 -bd 0 -bg $bg
        pack $f.c

        set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$totalW' height='$totalH'>"
        append svg "<rect x='$shadow' y='$shadow' width='$W' height='$H' rx='$r' ry='$r' fill='[ttkbootstrap::_darken $bg 15]'/>"
        append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$bg' stroke='$hex' stroke-width='1.5'/>"
        set barW [ttkbootstrap::_sp 6]
        append svg "<rect x='0' y='0' width='[expr {$barW + $r}]' height='$H' rx='$r' ry='$r' fill='$hex'/>"
        append svg "<rect x='$r' y='0' width='$barW' height='$H' fill='$hex'/>"
        append svg "</svg>"
        catch { image delete ${f}::card }
        image create photo ${f}::card -data $svg -format {svg}
        $f.c create image 0 0 -image ${f}::card -anchor nw

        $f.c create text [ttkbootstrap::_sp 16] [ttkbootstrap::_sp 14] \
            -text $o(-title) -fill $fg \
            -font [list $fn [ttkbootstrap::_sf 12] bold] -anchor nw
        $f.c create text [ttkbootstrap::_sp 16] [ttkbootstrap::_sp 36] \
            -text $o(-message) -fill [ttkbootstrap::getColor secondary] \
            -font [list $fn [ttkbootstrap::_sf 11]] -anchor nw \
            -width [expr {$W - [ttkbootstrap::_sp 32]}]
        $f.c create text [expr {$W - [ttkbootstrap::_sp 14]}] [ttkbootstrap::_sp 10] \
            -text "\u00d7" -fill [ttkbootstrap::getColor secondary] \
            -font [list $fn [ttkbootstrap::_sf 14]] -anchor ne -tags closebtn
        $f.c bind closebtn <Button-1> [list destroy $f]

        # Compute target/start positions in PARENT coordinates.
        update idletasks
        set pw [winfo width $parent]
        set pad [ttkbootstrap::_sp 20]
        switch $o(-position) {
            topleft  { set tx $pad;                                 set startx [expr {-$totalW}] }
            default  { set tx [expr {$pw - $totalW - $pad}];        set startx $pw }
        }
        set ty $pad

        # Start fully off the edge (hidden by the parent's clipping) then slide.
        place $f -x $startx -y $ty
        raise $f
        ttkbootstrap::_svgnb_slideChild $f $startx $tx $ty 0 14

        if {$o(-duration) > 0} {
            after $o(-duration) [list catch [list destroy $f]]
        }
        return $f
    }
}

} ;# end namespace ttkbootstrap

# ── OS Theme Auto-Detect ──────────────────────────────────────────────────────
# Detect OS dark/light preference and select matching theme.
#
# USAGE
#   ttkbootstrap::autoTheme          ;# auto-detect and apply
#   ttkbootstrap::autoTheme -light cosmo -dark darkly  ;# specify preferences
#
namespace eval ttkbootstrap {

proc autoTheme {args} {
    array set o {-light litera -dark darkly}
    array set o $args

    set prefer [_detectOSTheme]
    if {$prefer eq "dark"} {
        setTheme $o(-dark)
    } else {
        setTheme $o(-light)
    }
    return $prefer
}

proc _detectOSTheme {} {
    # Linux: check gsettings or xfconf
    if {[tk windowingsystem] eq "x11"} {
        # GNOME/GTK color-scheme: 'prefer-dark', 'prefer-light', or 'default'.
        # 'default' is ambiguous, so fall through to the gtk-theme name check.
        if {![catch {exec gsettings get org.gnome.desktop.interface color-scheme} result]} {
            if {[string match "*dark*" $result]}  { return "dark" }
            if {[string match "*light*" $result]} { return "light" }
            # 'default' — fall through to theme-name heuristics below
        }
        if {![catch {exec gsettings get org.gnome.desktop.interface gtk-theme} result]} {
            if {[string match -nocase "*dark*" $result]} { return "dark" }
            return "light"
        }
        # XFCE
        if {![catch {exec xfconf-query -c xsettings -p /Net/ThemeName} result]} {
            if {[string match -nocase "*dark*" $result]} { return "dark" }
            return "light"
        }
        # KDE (Plasma 5 and 6 binaries)
        foreach kbin {kreadconfig6 kreadconfig5} {
            if {![catch {exec $kbin --group General --key ColorScheme} result]} {
                if {[string match -nocase "*dark*" $result]} { return "dark" }
                return "light"
            }
        }
    }
    # macOS
    if {[tk windowingsystem] eq "aqua"} {
        if {![catch {exec defaults read -g AppleInterfaceStyle} result]} {
            if {[string match -nocase "*dark*" $result]} { return "dark" }
        }
        return "light"
    }
    # Windows
    if {[tk windowingsystem] eq "win32"} {
        if {![catch {exec reg query \
            "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize" \
            /v AppsUseLightTheme} result]} {
            if {[string match "*0x0*" $result]} { return "dark" }
        }
        return "light"
    }
    return "light"
}

} ;# end namespace ttkbootstrap

# ── SVGSearchBar ──────────────────────────────────────────────────────────────
# Entry with SVG magnifying glass icon and clear button.
#
# USAGE
#   ttkbootstrap::SVGSearchBar .sb -bootstyle primary -placeholder "Search..." \
#       -command {puts "Search: $query"}
#
namespace eval ttkbootstrap {

proc _svgsb_updateClear {w} {
    if {![winfo exists $w] || ![winfo exists $w.clr]} return
    set hh [winfo height $w]
    if {$hh < 4} { set hh [winfo reqheight $w] }
    set capR [expr {max(2, int(($hh-2)/2))}]
    set val [$w.ent get]
    if {$val ne ""} {
        if {![winfo ismapped $w.clr]} {
            pack forget $w.ent
            pack $w.clr -side right -padx [list [ttkbootstrap::_sp 2] $capR]
            pack $w.ent -side left -fill both -expand 1 -pady [ttkbootstrap::_sp 3] -padx [list 0 [ttkbootstrap::_sp 2]]
        }
    } else {
        catch { pack forget $w.clr }
        catch { pack configure $w.ent -padx [list 0 $capR] }
    }
}

# Returns a closed SVG path string for a filled "pill" (stadium) shape covering
# the rectangle (x, y, w, h): two semicircular end caps of radius h/2 joined by
# straight top and bottom edges. Used to draw the search-bar border as the gap
# between two filled pills, which keeps the border an even thickness all round
# (a stroked path antialiases curves and straight edges unevenly in nanosvg).
proc _svgsb_pillPath {x y w h} {
    set r   [expr {$h / 2.0}]
    set xl  [expr {$x + $r}]            ;# centre x of the left cap
    set xr  [expr {$x + $w - $r}]       ;# centre x of the right cap
    set yt  $y
    set yb  [expr {$y + $h}]
    # Top edge L->R, right cap (down), bottom edge R->L, left cap (up), close.
    return "M $xl $yt L $xr $yt A $r $r 0 0 1 $xr $yb L $xl $yb A $r $r 0 0 1 $xl $yt Z"
}

proc SVGSearchBar {w args} {
    array set o {-bootstyle primary -placeholder "Search..." -command {} -width 25 -textvariable {}}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGSearchBar -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgsb::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set fn [_safeFont [getColor font]]
    set fs [_sf 12]
    set hex [getColor $o(-bootstyle)]
    set bg [getColor bg]
    set inputbg [getColor inputbg]
    set bdr [getColor border]
    set fg [getColor fg]

    set ls [font metrics [list $fn $fs] -linespace]
    # Pill height = line height + generous padding so descenders fit AND the
    # border looks even (a larger pill renders the rounded caps and straight
    # edges at a more uniform visual weight than a short one).
    set H [expr {$ls + [_sp 20]}]
    set ew [expr {[font measure [list $fn $fs] "0"] * $o(-width) + [_sp 40]}]
    set ${ns}::W $ew
    set ${ns}::H $H
    frame $w -highlightthickness 0 -bd 0 -width $ew -height $H -bg $bg
    pack propagate $w 0

    # Pill border drawn exactly like the outline pill BUTTONS (_svgb_mk): a
    # single <rect> with rx/ry equal to half the height (so it renders as a
    # stadium/pill) and a stroke — fill='none', stroke-width 2, inset 1px.
    # nanosvg strokes a rounded <rect> evenly all the way round, so the straight
    # top/bottom lines and the rounded caps have identical thickness. A filled
    # field rect sits behind so the interior is the input colour.
    set rr [expr {($H - 2) / 2.0}]   ;# pill radius for the inset rect

    set svg_n "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'>"
    append svg_n "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$rr' ry='$rr' fill='$inputbg' stroke='$bdr' stroke-width='2'/>"
    append svg_n "</svg>"
    image create photo ${w}::img_n -data $svg_n -format {svg}

    set svg_f "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'>"
    append svg_f "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$rr' ry='$rr' fill='$inputbg' stroke='$hex' stroke-width='2'/>"
    append svg_f "</svg>"
    image create photo ${w}::img_f -data $svg_f -format {svg}

    label $w.bg -image ${w}::img_n -bd 0 -highlightthickness 0 -bg $bg \
        -anchor nw -width $ew -height $H
    place $w.bg -x 0 -y 0 -width $ew -height $H

    # Search icon
    set isz [expr {$ls - 2}]
    set search_svg "<svg xmlns='http://www.w3.org/2000/svg' width='$isz' height='$isz' viewBox='0 0 24 24'>"
    append search_svg "<path d='M21 21L16.7 16.7M11 4A7 7 0 1111 18A7 7 0 1111 4Z' fill='none' stroke='[getColor secondary]' stroke-width='2.5' stroke-linecap='round'/>"
    append search_svg "</svg>"
    image create photo ${w}::search_ico -data $search_svg -format {svg}
    label $w.ico -image ${w}::search_ico -bd 0 -bg $inputbg
    # Left pad = cap radius so the icon clears the rounded left cap.
    pack $w.ico -side left -padx [list [expr {int(($H-2)/2)}] [_sp 2]]

    # Borderless entry style so only the SVG pill border shows (the default
    # ttk::entry draws its own sunken rectangle, which would overlap the pill).
    # The clam theme's Entry.field element has a 1px border baked into its
    # layout that -borderwidth can't remove, so we also flatten the layout and
    # match the border colour to the field background.
    catch {
        ttk::style configure flatSearch.TEntry \
            -fieldbackground $inputbg -background $inputbg \
            -bordercolor $inputbg -lightcolor $inputbg -darkcolor $inputbg \
            -borderwidth 0 -relief flat
        ttk::style layout flatSearch.TEntry {
            Entry.padding -sticky nswe -children {
                Entry.textarea -sticky nswe
            }
        }
    }

    # Entry — right padding = cap radius so the text area stops before the
    # rounded right cap and the arc is fully visible. NO separate pad frame
    # (a Tk frame is opaque and would paint over the pill's right cap).
    set capR [expr {int(($H-2)/2)}]
    set ecmd [list ttk::entry $w.ent -width $o(-width) -font [list $fn $fs] \
        -style flatSearch.TEntry]
    if {$o(-textvariable) ne {}} { lappend ecmd -textvariable $o(-textvariable) }
    {*}$ecmd
    # pady must exceed the border stroke (2px) so the entry's opaque
    # background does not paint over the top/bottom border lines.
    pack $w.ent -side left -fill both -expand 1 -pady [_sp 3] -padx [list 0 $capR]

    # Clear button (hidden until text entered)
    set clr_svg "<svg xmlns='http://www.w3.org/2000/svg' width='$isz' height='$isz' viewBox='0 0 24 24'>"
    append clr_svg "<circle cx='12' cy='12' r='10' fill='[getColor secondary]'/>"
    append clr_svg "<path d='M15 9L9 15M9 9L15 15' fill='none' stroke='$inputbg' stroke-width='2' stroke-linecap='round'/>"
    append clr_svg "</svg>"
    image create photo ${w}::clear_ico -data $clr_svg -format {svg}
    label $w.clr -image ${w}::clear_ico -bd 0 -bg $inputbg -cursor hand2
    bind $w.clr <Button-1> [list apply {{w} {
        $w.ent delete 0 end
        focus $w.ent
    }} $w]

    # Show/hide clear button based on content (handler shared with set/clear).
    bind $w.ent <KeyRelease> [list apply {{w cmd} {
        ttkbootstrap::_svgsb_updateClear $w
        set val [$w.ent get]
        if {$cmd ne "" && $val ne ""} {
            set query $val
            uplevel #0 $cmd
        }
    }} $w $o(-command)]

    # Focus handling
    bind $w.ent <FocusIn>  [list $w.bg configure -image ${w}::img_f]
    bind $w.ent <FocusOut> [list $w.bg configure -image ${w}::img_n]

    # Enter key triggers search
    bind $w.ent <Return> [list apply {{w cmd} {
        if {$cmd ne ""} {
            set query [$w.ent get]
            uplevel #0 $cmd
        }
    }} $w $o(-command)]

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgsb_retheme $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsb
    return $w
}

proc _svgsb_retheme {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsb::$w
    array set o [set ${ns}::o]
    set fn [_safeFont [getColor font]]
    set fs [_sf 12]
    set hex     [getColor $o(-bootstyle)]
    set bg      [getColor bg]
    set inputbg [getColor inputbg]
    set bdr     [getColor border]
    set fg      [getColor fg]
    set sec     [getColor secondary]
    set ew [set ${ns}::W]
    set H  [set ${ns}::H]
    set rr [expr {($H - 2) / 2.0}]
    set ls [font metrics [list $fn $fs] -linespace]
    set isz [expr {$ls - 2}]

    $w configure -bg $bg
    $w.bg configure -bg $bg

    # Regenerate the pill border photos — they bake in inputbg / border / hex,
    # none of which a plain -bg update would refresh (white pill on dark theme).
    set svg_n "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'>"
    append svg_n "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$rr' ry='$rr' fill='$inputbg' stroke='$bdr' stroke-width='2'/>"
    append svg_n "</svg>"
    catch { image delete ${w}::img_n }
    image create photo ${w}::img_n -data $svg_n -format {svg}

    set svg_f "<svg xmlns='http://www.w3.org/2000/svg' width='$ew' height='$H'>"
    append svg_f "<rect x='1' y='1' width='[expr {$ew-2}]' height='[expr {$H-2}]' rx='$rr' ry='$rr' fill='$inputbg' stroke='$hex' stroke-width='2'/>"
    append svg_f "</svg>"
    catch { image delete ${w}::img_f }
    image create photo ${w}::img_f -data $svg_f -format {svg}

    # Icons carry theme colours too (secondary stroke / inputbg fill).
    set search_svg "<svg xmlns='http://www.w3.org/2000/svg' width='$isz' height='$isz' viewBox='0 0 24 24'>"
    append search_svg "<path d='M21 21L16.7 16.7M11 4A7 7 0 1111 18A7 7 0 1111 4Z' fill='none' stroke='$sec' stroke-width='2.5' stroke-linecap='round'/>"
    append search_svg "</svg>"
    catch { image delete ${w}::search_ico }
    image create photo ${w}::search_ico -data $search_svg -format {svg}

    set clr_svg "<svg xmlns='http://www.w3.org/2000/svg' width='$isz' height='$isz' viewBox='0 0 24 24'>"
    append clr_svg "<circle cx='12' cy='12' r='10' fill='$sec'/>"
    append clr_svg "<path d='M15 9L9 15M9 9L15 15' fill='none' stroke='$inputbg' stroke-width='2' stroke-linecap='round'/>"
    append clr_svg "</svg>"
    catch { image delete ${w}::clear_ico }
    image create photo ${w}::clear_ico -data $clr_svg -format {svg}

    catch { $w.ico configure -bg $inputbg -image ${w}::search_ico }
    catch { $w.clr configure -bg $inputbg -image ${w}::clear_ico }

    # The borderless entry style is shared (global) — refresh its field colour
    # and text colour so the interior is not a stale light box on dark themes.
    catch {
        ttk::style configure flatSearch.TEntry \
            -fieldbackground $inputbg -background $inputbg \
            -bordercolor $inputbg -lightcolor $inputbg -darkcolor $inputbg \
            -foreground $fg -borderwidth 0 -relief flat
    }

    # Restore the border image matching the current focus state.
    if {[focus -displayof $w] eq "$w.ent"} {
        $w.bg configure -image ${w}::img_f
    } else {
        $w.bg configure -image ${w}::img_n
    }
}

} ;# end namespace ttkbootstrap

# ── SVGAvatar ─────────────────────────────────────────────────────────────────
# Circular avatar showing initials or an image.
#
# USAGE
#   ttkbootstrap::SVGAvatar .av -text "JD" -bootstyle primary -size 48
#
namespace eval ttkbootstrap {

proc SVGAvatar {w args} {
    array set o {-text "" -bootstyle primary -size 0}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGAvatar -bootstyle $o(-bootstyle)
    if {$o(-size) == 0} { set o(-size) [_sp 48] }
    set ns ::ttkbootstrap::svgavatar::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    label $w -compound center -bd 0
    _svgavatar_redraw $w

    # Regenerate on theme change: the circle colour and the corner bg-fill are
    # baked into the cached photo. Updating only -bg leaves the old (light)
    # corner fill showing as white tips outside the circle on dark themes.
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgavatar_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgavatar
    return $w
}

proc _svgavatar_redraw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgavatar::$w
    array set o [set ${ns}::o]

    set hex [getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [getColor primary] }
    set cfgfg [_contrastFg $hex]
    set bg [getColor bg]
    set sz $o(-size)
    set fn [_safeFont [getColor font]]
    # Font sized in PIXELS (negative) and tied to the circle's pixel size, so it
    # scales with the avatar exactly once. A positive point size is scaled a
    # SECOND time by tk scaling on HiDPI, making the initials overflow the circle.
    set fs [expr {-int($sz / 2.5)}]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$sz' height='$sz'>"
    append svg "<rect x='0' y='0' width='$sz' height='$sz' fill='$bg'/>"
    append svg "<circle cx='[expr {$sz/2}]' cy='[expr {$sz/2}]' r='[expr {$sz/2-1}]' fill='$hex'/>"
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w configure -image ${w}::img -text $o(-text) -compound center \
        -fg $cfgfg -font [list $fn $fs bold] -bg $bg
}

} ;# end namespace ttkbootstrap

# ── SVGChip ───────────────────────────────────────────────────────────────────
# Material Design chip with optional leading icon and close button.
#
# USAGE
#   ttkbootstrap::SVGChip .ch -text "Python" -bootstyle primary \
#       -icon "code" -closeable 1 -command {puts "closed"}
#
namespace eval ttkbootstrap {

proc SVGChip {w args} {
    array set o {-text "" -bootstyle primary -icon "" -closeable 0 -command {}}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGChip -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgchip::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    label $w -compound center -bd 0 -cursor hand2
    _svgchip_redraw $w

    if {$o(-closeable) && $o(-command) ne {}} {
        bind $w <Button-1> $o(-command)
    }

    # Cached SVG photos do not follow theme changes — regenerate the whole
    # image (corner bg-fill, chip colour and icon all depend on the theme),
    # not just the host -bg. Updating -bg alone leaves the baked-in light
    # corner-fill showing as white "tips" on dark themes.
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgchip_redraw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgchip
    return $w
}

proc _svgchip_redraw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgchip::$w
    array set o [set ${ns}::o]

    set hex [getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [getColor primary] }
    set fg [_contrastFg $hex]
    set bg [getColor bg]
    set fn [_safeFont [getColor font]]
    set fs [_sf 11]

    set txt $o(-text)
    if {$o(-closeable)} { append txt "  \u00d7" }
    set tw [font measure [list $fn $fs] $txt]
    set th [font metrics [list $fn $fs] -linespace]

    set iconW 0
    if {$o(-icon) ne ""} {
        set iconW [expr {$th + [_sp 4]}]
    }

    set pw [expr {$tw + $iconW + [_sp 20]}]
    set ph [expr {$th + [_sp 8]}]
    set pr [expr {$ph / 2}]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$pw' height='$ph'><rect x='0' y='0' width='$pw' height='$ph' fill='$bg'/>"  ;# bgfill_done
    append svg "<rect x='0' y='0' width='$pw' height='$ph' rx='$pr' ry='$pr' fill='$hex'/>"

    # Leading icon circle
    if {$o(-icon) ne ""} {
        set icr [expr {$ph / 2 - 2}]
        append svg "<circle cx='[expr {$ph/2}]' cy='[expr {$ph/2}]' r='$icr' fill='[_darken $hex 15]'/>"
    }
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w configure -image ${w}::img -text $txt -fg $fg -font [list $fn $fs] -bg $bg
}

} ;# end namespace ttkbootstrap

# ── SVGDialog ─────────────────────────────────────────────────────────────────
# Modal dialog with SVG shadow, title bar, and action buttons.
#
# USAGE
#   ttkbootstrap::SVGDialog::show \
#       -title "Confirm Delete" \
#       -message "Are you sure you want to delete this item?" \
#       -bootstyle danger \
#       -buttons {Cancel OK} \
#       -default OK
#   # Returns the button text that was clicked
#
namespace eval ttkbootstrap {

namespace eval SVGDialog {
    proc show {args} {
        array set o {-title "" -message "" -bootstyle primary -buttons {OK} -default ""}
        array set o $args
        ttkbootstrap::_validateBootstyle SVGDialog -bootstyle $o(-bootstyle)
        if {[llength $o(-buttons)] == 0} {
            error "SVGDialog: -buttons must contain at least one button label"
        }

        set hex [ttkbootstrap::getColor $o(-bootstyle)]
        if {$hex eq ""} { set hex [ttkbootstrap::getColor primary] }
        set bg [ttkbootstrap::getColor bg]
        set fg [ttkbootstrap::getColor fg]
        set cfgfg [ttkbootstrap::_contrastFg $hex]
        set fn [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
        set bdr [ttkbootstrap::getColor border]

        set ::_svgdlg_result ""
        set d .svgdlg_[clock microseconds]
        catch { destroy $d }
        toplevel $d -bg $bg
        wm title $d $o(-title)
        wm resizable $d 0 0
        wm transient $d .

        set W [ttkbootstrap::_sp 360]
        set pad [ttkbootstrap::_sp 16]

        # Title bar
        frame $d.hdr -bg $hex -highlightthickness 0
        label $d.hdr.t -text $o(-title) -bg $hex -fg $cfgfg \
            -font [list $fn [ttkbootstrap::_sf 13] bold] \
            -padx $pad -pady [ttkbootstrap::_sp 8]
        pack $d.hdr.t -fill x
        pack $d.hdr -fill x

        # Message
        frame $d.body -bg $bg
        ttk::label $d.body.msg -text $o(-message) \
            -wraplength [expr {$W - $pad * 2}] \
            -justify left
        pack $d.body.msg -padx $pad -pady $pad
        pack $d.body -fill both -expand 1

        # Buttons
        frame $d.btns -bg $bg
        set bi 0
        foreach btn [lreverse $o(-buttons)] {
            if {$btn eq $o(-default) || ($o(-default) eq "" && $bi == 0)} {
                set style "$o(-bootstyle).TButton"
            } else {
                set style "$o(-bootstyle).Outline.TButton"
            }
            ttk::button $d.btns.b[incr bi] -text $btn -style $style \
                -padding [ttkbootstrap::_sp2 16 4] \
                -command [list set ::_svgdlg_result $btn]
            pack $d.btns.b$bi -side right -padx [ttkbootstrap::_sp 4]
        }
        pack $d.btns -fill x -padx $pad -pady [ttkbootstrap::_sp2 0 12]

        # Center on parent
        wm withdraw $d
        update idletasks
        set pw [winfo width .]
        set ph [winfo height .]
        set px [winfo rootx .]
        set py [winfo rooty .]
        set dw [winfo reqwidth $d]
        set dh [winfo reqheight $d]
        set gx [expr {max(0, $px + ($pw - $dw) / 2)}]
        set gy [expr {max(0, $py + ($ph - $dh) / 2)}]
        wm geometry $d +${gx}+${gy}
        wm deiconify $d

        grab $d
        bind $d <Escape> [list set ::_svgdlg_result [lindex $o(-buttons) 0]]
        vwait ::_svgdlg_result
        grab release $d
        catch { destroy $d }
        return $::_svgdlg_result
    }
}

} ;# end namespace ttkbootstrap

# ── SVGTabNotebook ────────────────────────────────────────────────────────────
# Tabbed notebook with SVG rounded tabs.
#
# USAGE
#   set nb [ttkbootstrap::SVGTabNotebook .nb -bootstyle primary]
#   ttkbootstrap::SVGTabNotebook::add $nb "Tab 1" -create {ttk::label %f.l -text "Page 1"; pack %f.l}
#   ttkbootstrap::SVGTabNotebook::add $nb "Tab 2" -create {ttk::label %f.l -text "Page 2"; pack %f.l}
#   ttkbootstrap::SVGTabNotebook::select $nb 0
#
namespace eval ttkbootstrap {

proc SVGTabNotebook {w args} {
    array set o {-bootstyle primary}
    array set o $args
    _validateBootstyle SVGTabNotebook -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgtab::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::tabs {}
    set ${ns}::current -1

    set bg [getColor bg]
    ttk::frame $w

    # Tab bar
    frame $w.tabbar -bg $bg -highlightthickness 0
    pack $w.tabbar -fill x -padx [_sp 4] -pady [_sp2 4 0]

    # Bottom border line under the tab bar, in the bootstyle colour
    frame $w.tabline -bg [getColor $o(-bootstyle)] -height [_sp 3] -highlightthickness 0
    pack $w.tabline -fill x

    # Content area
    frame $w.content -bg $bg -highlightthickness 0
    pack $w.content -fill both -expand 1

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgtab_retheme $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgtab
    return $w
}

namespace eval SVGTabNotebook {
    proc add {w title args} {
        array set o {-create {}}
        array set o $args
        set ns ::ttkbootstrap::svgtab::$w
        set idx [llength [set ${ns}::tabs]]

        # Create tab frame
        set page [ttk::frame $w.content.page$idx]

        # Execute creation script
        if {$o(-create) ne {}} {
            set script [string map [list %f $page] $o(-create)]
            uplevel #0 $script
        }

        lappend ${ns}::tabs [list $title $page]

        # Create tab button
        ttkbootstrap::_svgtab_maketab $w $idx $title

        # Auto-select first tab
        if {$idx == 0} {
            ttkbootstrap::SVGTabNotebook::select $w 0
        } else {
            # Redraw so this newly-added inactive tab gets its outline image
            # immediately (not only after it is first clicked).
            ttkbootstrap::_svgtab_redraw $w
        }
        return $page
    }

    proc select {w idx} {
        set ns ::ttkbootstrap::svgtab::$w
        set tabs [set ${ns}::tabs]
        set old [set ${ns}::current]

        # Hide old page
        if {$old >= 0 && $old < [llength $tabs]} {
            pack forget [lindex [lindex $tabs $old] 1]
        }

        # Show new page
        set ${ns}::current $idx
        if {$idx >= 0 && $idx < [llength $tabs]} {
            pack [lindex [lindex $tabs $idx] 1] -fill both -expand 1
        }

        # Redraw tabs
        ttkbootstrap::_svgtab_redraw $w
    }
}

proc _svgtab_maketab {w idx title} {
    set ns ::ttkbootstrap::svgtab::$w
    array set o [set ${ns}::o]
    set fn [_safeFont [getColor font]]
    set fs [_sf 12]
    set bg [getColor bg]

    set btn $w.tabbar.tab$idx
    catch { destroy $btn }
    label $btn -text $title -font [list $fn $fs] \
        -bg $bg -bd 0 -cursor hand2
    pack $btn -side left -padx [_sp2 0 2]
    bind $btn <Button-1> [list ttkbootstrap::SVGTabNotebook::select $w $idx]
}

proc _svgtab_redraw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgtab::$w
    array set o [set ${ns}::o]
    set current [set ${ns}::current]
    set hex [getColor $o(-bootstyle)]
    set bg [getColor bg]
    set fg [getColor fg]
    set cfgfg [_contrastFg $hex]
    set fn [_safeFont [getColor font]]
    set fs [_sf 12]

    set idx 0
    foreach tab [set ${ns}::tabs] {
        set btn $w.tabbar.tab$idx
        if {[winfo exists $btn]} {
            set tw [font measure [list $fn $fs] [lindex $tab 0]]
            set th [font metrics [list $fn $fs] -linespace]
            set tW [expr {$tw + [_sp 32]}]
            set tH [expr {$th + [_sp 14]}]
            set r [_sp 6]
            set dark [expr {[getColor type] eq "dark"}]
            set inactivebg [expr {$dark ? [_lighten $bg 6] : [_darken $bg 5]}]
            set bdr [getColor border]
            if {$idx == $current} {
                # Active tab — filled with the bootstyle colour, rounded top,
                # sitting on top of the bar (no bottom border so it "connects").
                set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$tW' height='$tH'>"
                append svg "<path d='M $r 0 L [expr {$tW-$r}] 0 Q $tW 0 $tW $r L $tW $tH L 0 $tH L 0 $r Q 0 0 $r 0 Z' fill='$hex'/>"
                append svg "</svg>"
                catch { image delete ${btn}::bg }
                image create photo ${btn}::bg -data $svg -format {svg}
                $btn configure -image ${btn}::bg -compound center \
                    -fg $cfgfg -font [list $fn $fs bold] -bg $bg
            } else {
                # Inactive tab — outlined so each tab is visibly distinct.
                set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$tW' height='$tH'>"
                append svg "<path d='M [expr {$r+0.5}] 1 L [expr {$tW-$r-0.5}] 1 Q [expr {$tW-0.5}] 1 [expr {$tW-0.5}] [expr {$r+1}] L [expr {$tW-0.5}] $tH L 0.5 $tH L 0.5 [expr {$r+1}] Q 0.5 1 [expr {$r+0.5}] 1 Z' fill='$inactivebg' stroke='$bdr' stroke-width='1'/>"
                append svg "</svg>"
                catch { image delete ${btn}::bg }
                image create photo ${btn}::bg -data $svg -format {svg}
                $btn configure -image ${btn}::bg -compound center \
                    -fg $fg -font [list $fn $fs] -bg $bg
            }
        }
        incr idx
    }
}

proc _svgtab_retheme {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgtab::$w
    set bg [ttkbootstrap::getColor bg]
    $w.tabbar configure -bg $bg
    catch { $w.tabline configure -bg [getColor [dict get [set ${ns}::o] -bootstyle]] }
    $w.content configure -bg $bg
    # Rebuild all tab buttons
    set idx 0
    foreach tab [set ${ns}::tabs] {
        _svgtab_maketab $w $idx [lindex $tab 0]
        incr idx
    }
    _svgtab_redraw $w
}

} ;# end namespace ttkbootstrap

# ── SVGGradientButton ─────────────────────────────────────────────────────────
# Button with a faked vertical gradient (nanosvg has no <linearGradient>, so we
# layer thin horizontal stripes that step between two colours).
#
# USAGE
#   ttkbootstrap::SVGGradientButton .gb -text "Gradient" -bootstyle primary \
#       -command {puts clicked}
#
namespace eval ttkbootstrap {

proc SVGGradientButton {w args} {
    array set o {-text "" -bootstyle primary -command {} -radius -1 -width 0}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGGradientButton -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svggb::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]

    set fn [_safeFont [getColor font]]
    set fs [_sf 12]
    set hex [getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [getColor primary] }
    set cfgfg [_contrastFg $hex]
    set bg [getColor bg]

    set tw [font measure [list $fn $fs] $o(-text)]
    set pad [_sp 28]
    set W [expr {$o(-width) > 0 ? $o(-width) : $tw + $pad}]
    set H [expr {[font metrics [list $fn $fs] -linespace] + [_sp 14]}]
    if {$o(-radius) < 0} { set o(-radius) [_sp 6] }
    set r $o(-radius)
    set ${ns}::W $W
    set ${ns}::H $H

    label $w -bd 0 -highlightthickness 0 -bg $bg -cursor hand2 \
        -text $o(-text) -fg $cfgfg -font [list $fn $fs bold] -compound center
    _svggb_draw $w 0

    bind $w <Enter>          [list ttkbootstrap::_svggb_draw $w 1]
    bind $w <Leave>          [list ttkbootstrap::_svggb_draw $w 0]
    bind $w <Button-1>       [list ttkbootstrap::_svggb_press $w]
    bind $w <ButtonRelease-1> [list ttkbootstrap::_svggb_release $w]
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svggb_draw $w 0]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svggb
    return $w
}

proc _svggb_draw {w hover} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svggb::$w
    array set o [set ${ns}::o]
    set W [set ${ns}::W]
    set H [set ${ns}::H]
    set r $o(-radius)
    set hex [getColor $o(-bootstyle)]
    if {$hex eq ""} { set hex [getColor primary] }
    set bg [getColor bg]

    # Top colour lighter, bottom colour darker (or reversed on hover)
    if {$hover} {
        set top [_darken $hex 5]
        set bot [_darken $hex 22]
    } else {
        set top [_lighten $hex 12]
        set bot [_darken $hex 12]
    }

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>"
    # Rounded base in bottom colour
    append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$bot'/>"
    # Stripe the gradient — 12 bands interpolating top→bottom
    set bands 12
    set r1 [_hexR $top]; set g1 [_hexG $top]; set b1 [_hexB $top]
    set r2 [_hexR $bot]; set g2 [_hexG $bot]; set b2 [_hexB $bot]
    set bandH [expr {double($H) / $bands}]
    for {set i 0} {$i < $bands} {incr i} {
        set t [expr {double($i) / ($bands - 1)}]
        set rr [expr {int($r1 + ($r2 - $r1) * $t)}]
        set gg [expr {int($g1 + ($g2 - $g1) * $t)}]
        set bb [expr {int($b1 + ($b2 - $b1) * $t)}]
        set col [format "#%02x%02x%02x" $rr $gg $bb]
        set y [expr {int($i * $bandH)}]
        set bh [expr {int($bandH) + 1}]
        # Inset stripes so rounded corners of the base show through
        set inset [expr {($i == 0 || $i == $bands-1) ? $r : 0}]
        append svg "<rect x='$inset' y='$y' width='[expr {$W - 2*$inset}]' height='$bh' fill='$col'/>"
    }
    # Re-round the corners by overlaying bg-coloured corner masks via a stroked outline
    append svg "<rect x='0.5' y='0.5' width='[expr {$W-1}]' height='[expr {$H-1}]' rx='$r' ry='$r' fill='none' stroke='$bg' stroke-width='1'/>"
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w configure -image ${w}::img -bg $bg
}

proc _svggb_press {w} {
    set ns ::ttkbootstrap::svggb::$w
    _svggb_draw $w 1
}
proc _svggb_release {w} {
    set ns ::ttkbootstrap::svggb::$w
    array set o [set ${ns}::o]
    _svggb_draw $w 1
    if {$o(-command) ne {}} { uplevel #0 $o(-command) }
}

# Hex channel helpers
proc _hexR {hex} { return [expr {"0x[string range $hex 1 2]"}] }
proc _hexG {hex} { return [expr {"0x[string range $hex 3 4]"}] }
proc _hexB {hex} { return [expr {"0x[string range $hex 5 6]"}] }

} ;# end namespace ttkbootstrap

# ── SVGSkeleton ───────────────────────────────────────────────────────────────
# Animated shimmer placeholder for loading states.
#
# USAGE
#   set sk [ttkbootstrap::SVGSkeleton .sk -width 300 -lines 3]
#   ttkbootstrap::SVGSkeleton::start .sk
#   ... when content ready ...
#   ttkbootstrap::SVGSkeleton::stop .sk
#
namespace eval ttkbootstrap {

proc SVGSkeleton {w args} {
    array set o {-width 0 -height 0 -lines 3 -shape lines -bootstyle ""}
    array set o $args
    _validateEnum SVGSkeleton -shape $o(-shape) {lines card}
    if {$o(-bootstyle) ne ""} { _validateBootstyle SVGSkeleton -bootstyle $o(-bootstyle) }
    _validatePositive SVGSkeleton -lines $o(-lines)
    set ns ::ttkbootstrap::svgsk::$w
    namespace eval $ns {}
    if {$o(-width) == 0}  { set o(-width)  [_sp 300] }
    if {$o(-height) == 0} {
        if {$o(-shape) eq "card"} {
            set o(-height) [_sp 120]
        } else {
            set o(-height) [expr {$o(-lines) * [_sp 22] + [_sp 8]}]
        }
    }
    set ${ns}::o [array get o]
    set ${ns}::pos 0
    set ${ns}::running 0

    set bg [getColor bg]
    label $w -bd 0 -highlightthickness 0 -bg $bg
    _svgsk_draw $w
    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgsk_draw $w]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgsk
    return $w
}

namespace eval SVGSkeleton {
    proc start {w} {
        set ns ::ttkbootstrap::svgsk::$w
        set ${ns}::running 1
        ttkbootstrap::_svgsk_tick $w
    }
    proc stop {w} {
        set ns ::ttkbootstrap::svgsk::$w
        set ${ns}::running 0
    }
}

proc _svgsk_tick {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsk::$w
    if {![set ${ns}::running]} return
    set p [set ${ns}::pos]
    set p [expr {$p + 6}]
    if {$p > 130} { set p -30 }
    set ${ns}::pos $p
    _svgsk_draw $w
    after 40 [list ttkbootstrap::_svgsk_tick $w]
}

proc _svgsk_draw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgsk::$w
    array set o [set ${ns}::o]
    set W $o(-width)
    set H $o(-height)
    set bg [getColor bg]
    set dark [expr {[getColor type] eq "dark"}]
    if {[info exists o(-bootstyle)] && $o(-bootstyle) ne ""} {
        # Colourful skeleton: tint the bars and shimmer with the bootstyle hue.
        set hue [getColor $o(-bootstyle)]
        set base  [expr {$dark ? [_darken $hue 25] : [_lighten $hue 28]}]
        set shine [expr {$dark ? [_darken $hue 5]  : [_lighten $hue 12]}]
    } else {
        set base  [expr {$dark ? [_lighten $bg 8] : [_darken $bg 8]}]
        set shine [expr {$dark ? [_lighten $bg 16] : [_darken $bg 3]}]
    }
    set pos [set ${ns}::pos]
    set r [_sp 4]

    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'><rect x='0' y='0' width='$W' height='$H' fill='$bg'/>"  ;# bgfill_done
    if {$o(-shape) eq "card"} {
        # Avatar circle + two lines
        set cr [_sp 24]
        append svg "<circle cx='[expr {$cr + [_sp 4]}]' cy='[expr {$H/2}]' r='$cr' fill='$base'/>"
        set lx [expr {$cr*2 + [_sp 16]}]
        append svg "<rect x='$lx' y='[expr {$H/2 - [_sp 18]}]' width='[expr {$W - $lx - [_sp 16]}]' height='[_sp 12]' rx='$r' ry='$r' fill='$base'/>"
        append svg "<rect x='$lx' y='[expr {$H/2 + [_sp 2]}]' width='[expr {($W - $lx - [_sp 16]) * 2 / 3}]' height='[_sp 12]' rx='$r' ry='$r' fill='$base'/>"
    } else {
        # Stacked lines, last one shorter
        set lh [_sp 14]
        set gap [_sp 8]
        for {set i 0} {$i < $o(-lines)} {incr i} {
            set y [expr {$i * ($lh + $gap) + [_sp 4]}]
            set lw [expr {$i == $o(-lines)-1 ? int($W * 0.6) : $W - [_sp 8]}]
            append svg "<rect x='[_sp 4]' y='$y' width='$lw' height='$lh' rx='$r' ry='$r' fill='$base'/>"
        }
    }
    # Shimmer band (a translucent-looking lighter vertical strip)
    set sx [expr {int($W * $pos / 100.0)}]
    set sw [_sp 40]
    append svg "<rect x='$sx' y='0' width='$sw' height='$H' fill='$shine' opacity='0.65'/>"
    append svg "</svg>"

    catch { image delete ${w}::img }
    image create photo ${w}::img -data $svg -format {svg}
    $w configure -image ${w}::img -bg $bg
}

} ;# end namespace ttkbootstrap

# ── SVGTreeview ───────────────────────────────────────────────────────────────
# Lightweight tree with SVG expand/collapse chevrons and hover highlight.
#
# USAGE
#   set tv [ttkbootstrap::SVGTreeview .tv -bootstyle primary]
#   set root [ttkbootstrap::SVGTreeview::insert $tv "" "Documents" -open 1]
#   ttkbootstrap::SVGTreeview::insert $tv $root "report.pdf"
#   set sub  [ttkbootstrap::SVGTreeview::insert $tv $root "Images" -open 0]
#   ttkbootstrap::SVGTreeview::insert $tv $sub "photo.png"
#
namespace eval ttkbootstrap {

proc SVGTreeview {w args} {
    array set o {-bootstyle primary -height 0}
    array set o $args
    ttkbootstrap::_validateBootstyle SVGTreeview -bootstyle $o(-bootstyle)
    set ns ::ttkbootstrap::svgtv::$w
    namespace eval $ns {}
    set ${ns}::o [array get o]
    set ${ns}::nodes {}
    set ${ns}::counter 0
    set ${ns}::selected ""
    set ${ns}::hover ""
    set ${ns}::rowH 0
    # node data: id -> {parent text open depth}
    array set ${ns}::node {}
    array set ${ns}::children {}
    array set ${ns}::rowtop {}

    set bg [getColor bg]
    if {$o(-height) == 0} { set o(-height) [_sp 240] }
    set ${ns}::o [array get o]

    ttk::frame $w
    canvas $w.c -highlightthickness 0 -bd 0 -bg [getColor inputbg] \
        -height $o(-height)
    ttk::scrollbar $w.vs -orient vertical -command [list $w.c yview]
    $w.c configure -yscrollcommand [list $w.vs set]
    pack $w.vs -side right -fill y
    pack $w.c -side left -fill both -expand 1

    bind $w <<ThemeChanged>> [list ttkbootstrap::_svgtv_redraw $w]
    bind $w.c <Motion> [list ttkbootstrap::_svgtv_hover $w %y]
    bind $w.c <Leave>  [list ttkbootstrap::_svgtv_hover $w -1]
    ttkbootstrap::_bindCleanup $w ::ttkbootstrap::svgtv
    return $w
}

namespace eval SVGTreeview {
    proc insert {w parent text args} {
        array set o {-open 1}
        array set o $args
        set ns ::ttkbootstrap::svgtv::$w
        set id "n[incr ${ns}::counter]"
        if {$parent eq ""} {
            set depth 0
        } else {
            set pdata [set ${ns}::node($parent)]
            set depth [expr {[lindex $pdata 3] + 1}]
        }
        set ${ns}::node($id) [list $parent $text $o(-open) $depth]
        lappend ${ns}::children($parent) $id
        if {![info exists ${ns}::children($id)]} {
            set ${ns}::children($id) {}
        }
        ttkbootstrap::_svgtv_redraw $w
        return $id
    }
    proc selection {w} {
        set ns ::ttkbootstrap::svgtv::$w
        return [set ${ns}::selected]
    }
}

proc _svgtv_visible {w parent depth acc} {
    upvar $acc out
    set ns ::ttkbootstrap::svgtv::$w
    if {![info exists ${ns}::children($parent)]} return
    foreach child [set ${ns}::children($parent)] {
        set data [set ${ns}::node($child)]
        lappend out $child
        if {[lindex $data 2]} {
            _svgtv_visible $w $child [expr {$depth+1}] out
        }
    }
}

proc _svgtv_redraw {w} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgtv::$w
    array set o [set ${ns}::o]
    set hex [getColor $o(-bootstyle)]
    set fg [getColor fg]
    set inputbg [getColor inputbg]
    set selbg [getColor selectbg]
    set selfg [getColor selectfg]
    set dark [expr {[getColor type] eq "dark"}]
    set hoverbg [expr {$dark ? [_lighten $inputbg 10] : [_darken $inputbg 6]}]
    set stripebg [expr {$dark ? [_lighten $inputbg 4] : [_darken $inputbg 2]}]
    set fn [_safeFont [getColor font]]
    set fs [_sf 12]
    set rowH [expr {[font metrics [list $fn $fs] -linespace] + [_sp 10]}]
    set selected [set ${ns}::selected]
    set hover [set ${ns}::hover]
    set ${ns}::rowH $rowH
    array unset ${ns}::rowtop

    $w.c delete all
    $w.c configure -bg $inputbg

    set vis {}
    _svgtv_visible $w "" 0 vis

    set y 0
    set rownum 0
    set fullw [expr {[winfo width $w.c] > 1 ? [winfo width $w.c] : [_sp 360]}]
    set maxw [_sp 200]
    foreach id $vis {
        set data [set ${ns}::node($id)]
        lassign $data parent text open depth
        set indent [expr {[_sp 10] + $depth * [_sp 22]}]
        set hasKids [expr {[llength [set ${ns}::children($id)]] > 0}]
        set ${ns}::rowtop($id) $y

        # Row background: selection > hover > zebra stripe
        if {$id eq $selected} {
            $w.c create rectangle 0 $y $fullw [expr {$y+$rowH}] \
                -fill $selbg -outline "" -tags [list row_$id]
            # left accent bar in the bootstyle colour
            $w.c create rectangle 0 $y [_sp 3] [expr {$y+$rowH}] \
                -fill $hex -outline "" -tags [list row_$id]
            set txtcol $selfg
        } elseif {$id eq $hover} {
            $w.c create rectangle 0 $y $fullw [expr {$y+$rowH}] \
                -fill $hoverbg -outline "" -tags [list row_$id]
            set txtcol $fg
        } else {
            if {$rownum % 2 == 1} {
                $w.c create rectangle 0 $y $fullw [expr {$y+$rowH}] \
                    -fill $stripebg -outline "" -tags [list row_$id]
            }
            set txtcol $fg
        }

        # Chevron for expandable nodes
        if {$hasKids} {
            set csz [_sp 14]
            set cx $indent
            set cy [expr {$y + ($rowH - $csz)/2}]
            if {$open} {
                set path "M4 6L7 9L10 6"
            } else {
                set path "M6 4L9 7L6 10"
            }
            set csvg "<svg xmlns='http://www.w3.org/2000/svg' width='$csz' height='$csz' viewBox='0 0 14 14'>"
            append csvg "<path d='$path' fill='none' stroke='$txtcol' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'/>"
            append csvg "</svg>"
            set imgname ${w}::chev_$id
            catch { image delete $imgname }
            image create photo $imgname -data $csvg -format {svg}
            $w.c create image $cx $cy -image $imgname -anchor nw -tags [list chev_$id]
            $w.c bind chev_$id <Button-1> [list ttkbootstrap::_svgtv_toggle $w $id]
        }

        # Folder / file icon
        set isz [_sp 16]
        set ix [expr {$indent + [_sp 18]}]
        set iy [expr {$y + ($rowH - $isz)/2}]
        if {$hasKids} {
            set icol [expr {$id eq $selected ? $selfg : $hex}]
            set isvg "<svg xmlns='http://www.w3.org/2000/svg' width='$isz' height='$isz' viewBox='0 0 24 24'>"
            if {$open} {
                append isvg "<path d='M3 7a1 1 0 011-1h5l2 2h9a1 1 0 011 1v1H3z' fill='$icol' opacity='0.55'/>"
                append isvg "<path d='M3 9h18l-2 9a1 1 0 01-1 1H4a1 1 0 01-1-1z' fill='$icol'/>"
            } else {
                append isvg "<path d='M3 7a1 1 0 011-1h5l2 2h9a1 1 0 011 1v9a1 1 0 01-1 1H4a1 1 0 01-1-1z' fill='$icol'/>"
            }
            append isvg "</svg>"
        } else {
            set icol [expr {$id eq $selected ? $selfg : [_darken $fg 0]}]
            set isvg "<svg xmlns='http://www.w3.org/2000/svg' width='$isz' height='$isz' viewBox='0 0 24 24'>"
            append isvg "<path d='M6 2h8l4 4v15a1 1 0 01-1 1H6a1 1 0 01-1-1V3a1 1 0 011-1z' fill='none' stroke='$icol' stroke-width='1.8'/>"
            append isvg "<path d='M14 2v4h4' fill='none' stroke='$icol' stroke-width='1.8'/>"
            append isvg "</svg>"
        }
        set iname ${w}::ico_$id
        catch { image delete $iname }
        image create photo $iname -data $isvg -format {svg}
        $w.c create image $ix $iy -image $iname -anchor nw -tags [list lbl_$id]

        # Label
        set tx [expr {$ix + $isz + [_sp 6]}]
        $w.c create text $tx [expr {$y + $rowH/2}] -text $text \
            -fill $txtcol -font [list $fn $fs] -anchor w -tags [list lbl_$id]
        $w.c bind lbl_$id <Button-1> [list ttkbootstrap::_svgtv_select $w $id]

        set tw [expr {$tx + [font measure [list $fn $fs] $text] + [_sp 20]}]
        if {$tw > $maxw} { set maxw $tw }

        incr y $rowH
        incr rownum
    }

    $w.c configure -scrollregion [list 0 0 [expr {max($maxw,$fullw)}] $y]
}

proc _svgtv_hover {w ypix} {
    if {![winfo exists $w]} return
    set ns ::ttkbootstrap::svgtv::$w
    set rowH [set ${ns}::rowH]
    if {$rowH <= 0} return
    set newhover ""
    if {$ypix >= 0} {
        # account for scroll position
        set ytop [$w.c canvasy $ypix]
        foreach id [array names ${ns}::rowtop] {
            set top [set ${ns}::rowtop($id)]
            if {$ytop >= $top && $ytop < $top + $rowH} { set newhover $id; break }
        }
    }
    if {$newhover ne [set ${ns}::hover]} {
        set ${ns}::hover $newhover
        _svgtv_redraw $w
    }
}

proc _svgtv_toggle {w id} {
    set ns ::ttkbootstrap::svgtv::$w
    set data [set ${ns}::node($id)]
    lassign $data parent text open depth
    set ${ns}::node($id) [list $parent $text [expr {!$open}] $depth]
    _svgtv_redraw $w
}

proc _svgtv_select {w id} {
    set ns ::ttkbootstrap::svgtv::$w
    set ${ns}::selected $id
    _svgtv_redraw $w
}

} ;# end namespace ttkbootstrap

# ── Theme Swatch Helper ───────────────────────────────────────────────────────
# Returns a small SVG image previewing a theme's primary palette. Used for
# theme picker thumbnails.
#
# USAGE
#   set img [ttkbootstrap::themeSwatch darkly -width 120 -height 40]
#   label .l -image $img
#
namespace eval ttkbootstrap {

proc themeSwatch {theme args} {
    array set o {-width 0 -height 0}
    array set o $args
    if {$o(-width) == 0}  { set o(-width)  [_sp 120] }
    if {$o(-height) == 0} { set o(-height) [_sp 44] }

    # Query the theme's colours without switching the live theme
    if {[catch {getColors $theme} pal]} { return "" }
    array set col $pal

    set W $o(-width)
    set H $o(-height)
    set r [_sp 6]
    set bg $col(bg)
    # The container label's background (the live page bg). Fill the corners
    # outside the rounded rect with this so they blend in instead of showing
    # transparent/black square tips beyond the rounded edge.
    set pagebg [getColor bg]
    set svg "<svg xmlns='http://www.w3.org/2000/svg' width='$W' height='$H'>"
    append svg "<rect x='0' y='0' width='$W' height='$H' fill='$pagebg'/>"
    append svg "<rect x='0' y='0' width='$W' height='$H' rx='$r' ry='$r' fill='$bg' stroke='$col(border)' stroke-width='1'/>"
    # Colour dots for the bootstyle palette
    set dots {primary secondary success info warning danger}
    set n [llength $dots]
    set dotR [expr {$H / 4}]
    set spacing [expr {double($W - [_sp 16]) / $n}]
    set i 0
    foreach key $dots {
        if {[info exists col($key)]} {
            set cx [expr {int([_sp 8] + $i * $spacing + $spacing/2)}]
            set cy [expr {$H / 2}]
            append svg "<circle cx='$cx' cy='$cy' r='$dotR' fill='$col($key)'/>"
        }
        incr i
    }
    append svg "</svg>"

    set imgname _themeswatch_$theme
    catch { image delete $imgname }
    return [image create photo $imgname -data $svg -format {svg}]
}

} ;# end namespace ttkbootstrap

# ── API consistency: namespace-ensemble aliases ─────────────────────────────
# These provide Widget::method forms that mirror the older Widget_method
# procs, so the whole library uses one consistent calling convention.
# The underscore forms remain valid for backward compatibility.
namespace eval ttkbootstrap {
    namespace eval SVGProgress {
        proc set {w value} { ttkbootstrap::SVGProgress_set $w $value }
    }
    namespace eval SVGFloodgauge {
        proc set {w value} { ttkbootstrap::SVGFloodgauge_set $w $value }
    }
    namespace eval SVGBadge {
        proc set {w text} { ttkbootstrap::SVGBadge_set $w $text }
    }
    namespace eval SVGSparkLine {
        proc set {w data} { ttkbootstrap::SVGSparkLine_set $w $data }
        proc push {w value {maxpoints 20}} { ttkbootstrap::SVGSparkLine_push $w $value $maxpoints }
    }
    namespace eval SVGScrollbar {
        proc set {w first last} { ttkbootstrap::SVGScrollbar_set $w $first $last }
    }
    namespace eval SVGProgressRing {
        proc set {w value} { ttkbootstrap::SVGProgressRing_set $w $value }
        proc spin {w} { ttkbootstrap::SVGProgressRing_spin $w }
        proc stop {w} { ttkbootstrap::SVGProgressRing_stop $w }
    }
}

# ── Canonical namespace-ensemble API (unifies Widget::method naming) ──────────
# The underscore procs above remain as backward-compatible aliases.
namespace eval ttkbootstrap {
    namespace eval SVGBadge {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGBadge_set {*}$args] }
    }
    namespace eval SVGFloodgauge {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGFloodgauge_set {*}$args] }
    }
    namespace eval SVGProgressRing {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_set {*}$args] }
        proc spin {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_spin {*}$args] }
        proc stop {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_stop {*}$args] }
    }
    namespace eval SVGProgress {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGProgress_set {*}$args] }
    }
    namespace eval SVGScrollbar {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGScrollbar_set {*}$args] }
    }
    namespace eval SVGSparkLine {
        proc push {args} { uplevel 1 [list ttkbootstrap::SVGSparkLine_push {*}$args] }
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGSparkLine_set {*}$args] }
    }
} ;# end namespace ttkbootstrap

# ── Canonical Widget::method API aliases ──────────────────────────────────────
# Every action proc is exposed as the canonical "Widget::method" form.
# The older "Widget_method" underscore forms remain as backward-compatible
# aliases so existing code keeps working.
namespace eval ttkbootstrap {
    namespace eval SVGProgress {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGProgress_set {*}$args] }
    }
    namespace eval SVGFloodgauge {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGFloodgauge_set {*}$args] }
    }
    namespace eval SVGBadge {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGBadge_set {*}$args] }
    }
    namespace eval SVGSparkLine {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGSparkLine_set {*}$args] }
        proc push {args} { uplevel 1 [list ttkbootstrap::SVGSparkLine_push {*}$args] }
    }
    namespace eval SVGScrollbar {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGScrollbar_set {*}$args] }
    }
    namespace eval SVGProgressRing {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_set {*}$args] }
        proc spin {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_spin {*}$args] }
        proc stop {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_stop {*}$args] }
    }
} ;# end namespace ttkbootstrap


# ── Input-widget method layer (1.5) ───────────────────────────────────────────
# Lets callers operate on the OUTER widget path without knowing the child
# entry path. e.g.  ttkbootstrap::SVGEntry::get .e   instead of  .e.ent get
#
# Each wrapper exposes: get, set, insert, delete, clear, focus, entrypath.
namespace eval ttkbootstrap {

    # Map an outer widget path to its editable child, per widget type.
    # The widget's instance namespace records its type via the constructor;
    # we fall back to probing known child names.
    proc _entryChild {w} {
        foreach child {ent cb sp} {
            if {[winfo exists $w.$child]} { return $w.$child }
        }
        # SVGFormField nests one deeper: .ff.ent.ent
        if {[winfo exists $w.ent.ent]} { return $w.ent.ent }
        error "no editable child found under \"$w\""
    }

    # Generic implementations shared by all wrapper namespaces.
    proc _ew_get {w}            { return [[_entryChild $w] get] }
    proc _ew_set {w value}      {
        set e [_entryChild $w]
        if {[winfo class $e] eq "TCombobox"} {
            $e set $value
        } else {
            $e delete 0 end
            $e insert 0 $value
        }
        return $value
    }
    proc _ew_insert {w idx str} { [_entryChild $w] insert $idx $str }
    proc _ew_delete {w args}    { [_entryChild $w] delete {*}$args }
    proc _ew_clear {w}          { [_entryChild $w] delete 0 end }
    proc _ew_focus {w}          { focus [_entryChild $w] }
    proc _ew_entrypath {w}      { return [_entryChild $w] }
}

# Install the methods into each wrapper widget's namespace.
foreach _ttkbs_ewidget {SVGEntry SVGCombobox SVGSpinbox SVGSearchBar SVGFormField} {
    namespace eval ::ttkbootstrap::$_ttkbs_ewidget {
        proc get {w}            { ttkbootstrap::_ew_get $w }
        proc set {w value}      { ttkbootstrap::_ew_set $w $value }
        proc insert {w idx str} { ttkbootstrap::_ew_insert $w $idx $str }
        proc delete {w args}    { ttkbootstrap::_ew_delete $w {*}$args }
        proc clear {w}          { ttkbootstrap::_ew_clear $w }
        proc focus {w}          { ttkbootstrap::_ew_focus $w }
        proc entrypath {w}      { ttkbootstrap::_ew_entrypath $w }
    }
}
unset _ttkbs_ewidget


# ── API consistency: Widget::method aliases ───────────────────────────────────
# Both Widget::method and the legacy Widget_method forms are supported.
namespace eval ttkbootstrap {
    namespace eval SVGBadge {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGBadge_set {*}$args] }
    }
    namespace eval SVGFloodgauge {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGFloodgauge_set {*}$args] }
    }
    namespace eval SVGProgress {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGProgress_set {*}$args] }
    }
    namespace eval SVGProgressRing {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_set {*}$args] }
        proc spin {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_spin {*}$args] }
        proc stop {args} { uplevel 1 [list ttkbootstrap::SVGProgressRing_stop {*}$args] }
    }
    namespace eval SVGScrollbar {
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGScrollbar_set {*}$args] }
    }
    namespace eval SVGSparkLine {
        proc push {args} { uplevel 1 [list ttkbootstrap::SVGSparkLine_push {*}$args] }
        proc set {args} { uplevel 1 [list ttkbootstrap::SVGSparkLine_set {*}$args] }
    }
} ;# end namespace ttkbootstrap


# ── 1.5: Outer-path accessors for composite input widgets ─────────────────────
# Lets users call ttkbootstrap::SVGEntry::get $w etc. instead of reaching into
# child paths (.w.ent). The child paths still work; these are convenience
# wrappers that resolve the editable child for you.
namespace eval ttkbootstrap {

    # Internal: given an outer widget path, return its editable child path.
    # Order matters: SVGFormField nests an SVGEntry, so its real entry is
    # $w.ent.ent and must be checked before $w.ent.
    proc _inputChild {w} {
        if {[winfo exists $w.ent.ent]} { return $w.ent.ent }
        if {[winfo exists $w.ent]}     { return $w.ent }
        if {[winfo exists $w.cb]}      { return $w.cb }
        if {[winfo exists $w.sp]}      { return $w.sp }
        error "$w: not a composite input widget (no editable child found)"
    }

    namespace eval SVGEntry {
        proc get {w}       { return [[ttkbootstrap::_inputChild $w] get] }
        proc set {w value} { ::set e [ttkbootstrap::_inputChild $w]; $e delete 0 end; $e insert 0 $value; return $value }
        proc clear {w}     { [ttkbootstrap::_inputChild $w] delete 0 end }
        proc widget {w}    { return [ttkbootstrap::_inputChild $w] }
    }
    namespace eval SVGCombobox {
        proc get {w}       { return [[ttkbootstrap::_inputChild $w] get] }
        proc set {w value} { [ttkbootstrap::_inputChild $w] set $value; return $value }
        proc clear {w}     { [ttkbootstrap::_inputChild $w] set {} }
        proc widget {w}    { return [ttkbootstrap::_inputChild $w] }
        proc values {w args} {
            ::set e [ttkbootstrap::_inputChild $w]
            if {[llength $args] > 0} { $e configure -values [lindex $args 0] }
            return [$e cget -values]
        }
    }
    namespace eval SVGSpinbox {
        proc get {w}       { return [[ttkbootstrap::_inputChild $w] get] }
        proc set {w value} { [ttkbootstrap::_inputChild $w] set $value; return $value }
        proc clear {w}     { [ttkbootstrap::_inputChild $w] set 0 }
        proc widget {w}    { return [ttkbootstrap::_inputChild $w] }
    }
    namespace eval SVGSearchBar {
        proc get {w}       { return [[ttkbootstrap::_inputChild $w] get] }
        proc set {w value} {
            ::set e [ttkbootstrap::_inputChild $w]
            $e delete 0 end
            $e insert 0 $value
            ttkbootstrap::_svgsb_updateClear $w
            return $value
        }
        proc clear {w}     {
            ::set e [ttkbootstrap::_inputChild $w]
            $e delete 0 end
            ttkbootstrap::_svgsb_updateClear $w
        }
        proc widget {w}    { return [ttkbootstrap::_inputChild $w] }
    }
    namespace eval SVGFormField {
        proc get {w}       { return [[ttkbootstrap::_inputChild $w] get] }
        proc set {w value} { ::set e [ttkbootstrap::_inputChild $w]; $e delete 0 end; $e insert 0 $value; return $value }
        proc clear {w}     { [ttkbootstrap::_inputChild $w] delete 0 end }
        proc widget {w}    { return [ttkbootstrap::_inputChild $w] }
    }
} ;# end namespace ttkbootstrap
