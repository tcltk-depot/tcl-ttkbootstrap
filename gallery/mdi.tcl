# mdi.tcl — ttkbootstrap MDI Desktop (single-interp, namespace isolation)
#
# ARCHITECTURE
# ────────────────────────────────────────────────────────────────────────────
# Each MDI window is ONE real Tk frame on a canvas — no floating toplevels,
# no child interpreters, no two-window Z-order problem.
#
# Structure of each MDI window (canvas item → frame $desktop.w$id):
#
#   $desktop.w$id           outer frame (border)
#   $desktop.w$id.tb        title bar  (drag, min/max/close)
#   $desktop.w$id.body      content frame  ← app widgets live here
#   $desktop.w$id.grip      resize grip (SE corner)
#
# Each app script is sourced directly into namespace ::app$id:: via
# [namespace eval ::app$id:: [list source $file]].
#
# Shims installed before sourcing:
#   ttkbootstrap::Window   → no-op (we supply the window)
#   wm                     → title forwarded; resizable/protocol ignored
#   pack / grid / place    → widget paths starting with "." rewritten to body
#   exit / _close_gallery  → closes the MDI window
#   tk_messageBox          → pure-Tk themed dialog
#   tk_getOpenFile         → ttkbootstrap::GetOpenFile
#   tk_chooseDirectory     → ttkbootstrap::ChooseDirectory
#   vwait                  → no-op (event loop already running)
#   All Tk widget-creation commands (frame, ttk::frame, label, etc.)
#                          → first arg (widget path) rewritten if child of "."
#
# Pack/grid/widget-creation redirection strategy:
#   Every gallery app follows the pattern:
#       set f [ttk::frame .shortname ...]
#       pack $f -fill both -expand 1
#   The root frame is always a direct child of ".".
#   We intercept ttk::frame/frame/etc so ".shortname" becomes
#   "$body.shortname", and pack/grid/place so those paths are also rewritten.
#   Everything ends up in ONE toplevel with no Z-order issues.
#
# Run standalone:  tclkit mdi.tcl
# Or launched from showcase.tcl Gallery page.
# ────────────────────────────────────────────────────────────────────────────

package require Tk
lappend auto_path [file join [file dirname [info script]] ..]
package require ttkbootstrap

# ── Global MDI state ──────────────────────────────────────────────────────────
namespace eval mdi {
    variable wins         {}   ;# list of window ids (open + min)
    variable next_id      0    ;# monotone counter
    variable win_data     {}   ;# dict: id → {x y w h cw ch state title key}
    variable active       {}   ;# currently focused id
    variable drag_state   {}   ;# {id start_rx start_ry orig_x orig_y}
    variable resize_state {}   ;# {id start_rx start_ry orig_w orig_h}
    variable desktop      .mdi.desktop
    variable taskbar      .mdi.taskbar
    variable z_order      {}   ;# ids back→front
    variable cascade_x    60
    variable cascade_y    40
}

# ── Theme colours ─────────────────────────────────────────────────────────────
proc mdi::colours {} {
    return [dict create \
        ac        [ttkbootstrap::getColor primary] \
        ac_dark   [ttkbootstrap::_darken [ttkbootstrap::getColor primary] 15] \
        fg        [ttkbootstrap::_contrastFg [ttkbootstrap::getColor primary]] \
        bg        [ttkbootstrap::getColor bg] \
        bdr       [ttkbootstrap::getColor border] \
        inact     [ttkbootstrap::getColor secondary] \
        inact_fg  [ttkbootstrap::_contrastFg [ttkbootstrap::getColor secondary]] \
        desktop_bg [ttkbootstrap::_darken [ttkbootstrap::getColor bg] 8]]
}

# ── Build the desktop shell ───────────────────────────────────────────────────
proc mdi::build {} {
    variable desktop
    variable taskbar

    set c   [mdi::colours]
    set ac  [dict get $c ac]
    set fg  [dict get $c fg]
    set dbg [dict get $c desktop_bg]
    set fnm [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs  [ttkbootstrap::_sf 11]

    # ── Menu bar ──────────────────────────────────────────────────────────────
    frame .mdi.menubar -bg $ac -padx 8 -pady 3
    pack  .mdi.menubar -fill x -side top

    label .mdi.menubar.title \
        -text "ttkbootstrap MDI" -bg $ac -fg $fg \
        -font [list $fnm $fs bold] -padx 8
    pack .mdi.menubar.title -side left

    set mi 0
    foreach {lbl items} {
        "Apps \u25be" {
            calculator         "Calculator"
            stopwatch          "Stopwatch"
            data_entry         "Data Entry"
            equalizer          "Equalizer"
            text_reader        "Text Reader"
            file_search_engine "File Search"
            media_player       "Media Player"
            pc_cleaner         "PC Cleaner"
            back_me_up         "Back Me Up"
        }
        "Arrange \u25be" {
            cascade      "Cascade"
            tile_h       "Tile Horizontal"
            tile_v       "Tile Vertical"
            min_all      "Minimise All"
            restore_all  "Restore All"
            close_all    "Close All"
        }
    } {
        set btn [menubutton .mdi.menubar.mb[incr mi] \
            -text $lbl -bg $ac -fg $fg \
            -font [list $fnm $fs] -padx 10 -cursor hand2 \
            -relief flat -direction below]
        pack $btn -side left

        set m [menu $btn.m -tearoff 0 \
            -bg [dict get $c bg] \
            -fg [ttkbootstrap::getColor fg] \
            -font [list $fnm $fs] \
            -activebackground $ac -activeforeground $fg]

        set gdir [file dirname [info script]]
        if {[string match "*Apps*" $lbl]} {
            foreach {key name} $items {
                $m add command -label $name \
                    -command [list mdi::launch_app $key $name $gdir]
            }
        } else {
            foreach {key name} $items {
                $m add command -label $name \
                    -command [list mdi::arrange $key]
            }
        }
        $btn configure -menu $m

        set ac_dark [dict get $c ac_dark]
        bind $btn <Enter> [list $btn configure -bg $ac_dark]
        bind $btn <Leave> [list $btn configure -bg $ac]
    }

    # Close button — packed first so it sits at far right
    set ac_dark [dict get $c ac_dark]
    label .mdi.menubar.close \
        -text " × " -bg $ac -fg $fg -cursor hand2 \
        -font [list $fnm [ttkbootstrap::_sf 13] bold] -padx 6
    pack .mdi.menubar.close -side right
    bind .mdi.menubar.close <Enter> [list .mdi.menubar.close configure -bg $ac_dark]
    bind .mdi.menubar.close <Leave> [list .mdi.menubar.close configure -bg $ac]
    bind .mdi.menubar.close <Button-1> {
        mdi::arrange close_all
        after 100 mdi::_close_mdi
    }

    # Theme selector — packed after close so it sits left of ×
    set themes [ttkbootstrap::themeNames]
    ttk::combobox .mdi.menubar.theme \
        -values $themes -width 12 -state readonly \
        -style "primary.TCombobox" \
        -font [list $fnm [ttkbootstrap::_sf 10]]
    .mdi.menubar.theme set [ttkbootstrap::currentTheme]
    bind .mdi.menubar.theme <<ComboboxSelected>> {
        ttkbootstrap::setTheme [.mdi.menubar.theme get]
        mdi::restyle
    }
    pack .mdi.menubar.theme -side right -padx 4 -pady 1

    # ── Desktop canvas ────────────────────────────────────────────────────────
    canvas $desktop \
        -bg $dbg \
        -highlightthickness 0 \
        -relief flat
    pack $desktop -fill both -expand 1 -side top

    bind $desktop <Configure> mdi::draw_grid

    # ── Taskbar ───────────────────────────────────────────────────────────────
    frame $taskbar \
        -bg $ac \
        -height [ttkbootstrap::_sp 32] \
        -padx 4
    pack $taskbar -fill x -side bottom

    label $taskbar.clk \
        -textvariable ::mdi_clock \
        -bg $ac -fg $fg \
        -font [list $fnm $fs]
    pack $taskbar.clk -side right -padx 8

    mdi::tick_clock
}

proc mdi::draw_grid {} {
    variable desktop
    variable z_order
    set c  [mdi::colours]
    set gc [ttkbootstrap::_darken [dict get $c desktop_bg] 5]
    $desktop delete grid
    set W [winfo width  $desktop]
    set H [winfo height $desktop]
    for {set x 0} {$x < $W} {incr x 40} {
        $desktop create line $x 0 $x $H -fill $gc -tags grid
    }
    for {set y 0} {$y < $H} {incr y 40} {
        $desktop create line 0 $y $W $y -fill $gc -tags grid
    }
    catch { $desktop lower grid }
}

proc mdi::tick_clock {} {
    set ::mdi_clock [clock format [clock seconds] -format "%H:%M:%S"]
    after 1000 mdi::tick_clock
}

# ── App sizing table ──────────────────────────────────────────────────────────
proc mdi::app_size {key} {
    # Returns {content_width content_height}
    switch $key {
        calculator          { return {350 450} }
        stopwatch           { return {380 180} }
        data_entry          { return {460 260} }
        equalizer           { return {860 290} }
        text_reader         { return {760 480} }
        file_search_engine  { return {680 510} }
        media_player        { return {700 580} }
        pc_cleaner          { return {860 610} }
        back_me_up          { return {860 640} }
        collapsing_frame    { return {380 320} }
        magic_mouse         { return {700 500} }
        default             { return {600 400} }
    }
}

# ── Launch an app ─────────────────────────────────────────────────────────────
proc mdi::launch_app {key title gallery_dir} {
    variable next_id
    variable wins
    variable win_data
    variable z_order
    variable cascade_x
    variable cascade_y
    variable desktop

    set id [incr next_id]
    lappend wins $id
    lappend z_order $id

    lassign [mdi::app_size $key] cw ch
    set tb_h [ttkbootstrap::_sp 28]

    # Cascade position within desktop
    update idletasks
    set dw [winfo width  $desktop]
    set dh [winfo height $desktop]
    set x  $cascade_x
    set y  $cascade_y
    set cascade_x [expr {($cascade_x + 30) % 280}]
    set cascade_y [expr {($cascade_y + 30) % 200}]
    set x [expr {max(0, min($x, $dw - $cw - 4))}]
    set y [expr {max(0, min($y, $dh - $tb_h - 40))}]

    dict set win_data $id x     $x
    dict set win_data $id y     $y
    dict set win_data $id cw    $cw
    dict set win_data $id ch    $ch
    dict set win_data $id state normal
    dict set win_data $id title $title
    dict set win_data $id key   $key

    mdi::create_win_frame $id $x $y $cw $ch $tb_h $title
    mdi::load_app         $id $key $gallery_dir
    mdi::activate         $id
    mdi::update_taskbar
}

# ── Create the MDI window frame ───────────────────────────────────────────────
proc mdi::create_win_frame {id x y cw ch tb_h title} {
    variable desktop
    set c       [mdi::colours]
    set ac      [dict get $c ac]
    set fg      [dict get $c fg]
    set ac_dark [dict get $c ac_dark]
    set bg      [dict get $c bg]
    set bdr     [dict get $c bdr]
    set fnm     [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs      [ttkbootstrap::_sf 10]

    # Outer container (acts as 1px border)
    set f [frame $desktop.w$id -bg $bdr -relief solid -borderwidth 1]

    # ── Title bar ─────────────────────────────────────────────────────────────
    set tb [frame $f.tb -bg $ac -height $tb_h]
    pack $tb -fill x -side top

    label $tb.t \
        -text $title -bg $ac -fg $fg \
        -font [list $fnm $fs bold] -padx 6 -anchor w
    pack $tb.t -side left -fill y

    # Buttons right-to-left → displayed ─ □ × left-to-right
    foreach {sym tag cmd} [list \
        " \xd7 " cls_$id [list mdi::close_win $id] \
        " \u25a1 " max_$id [list mdi::maximise  $id] \
        " \u2015 " min_$id [list mdi::minimise  $id] \
    ] {
        set b [label $tb.$tag \
            -text $sym -bg $ac -fg $fg \
            -font [list $fnm [ttkbootstrap::_sf 12] bold] \
            -padx 4 -cursor hand2]
        pack $b -side right
        bind $b <Enter>    [list $b configure -bg $ac_dark]
        bind $b <Leave>    [list $b configure -bg $ac]
        bind $b <Button-1> $cmd
    }

    # Drag to move
    foreach w [list $tb $tb.t] {
        bind $w <Button-1>        [list mdi::drag_start  $id %X %Y]
        bind $w <B1-Motion>       [list mdi::drag_move   $id %X %Y]
        bind $w <ButtonRelease-1> { set mdi::drag_state {} }
        bind $w <Double-Button-1> [list mdi::maximise $id]
    }

    # ── Content body ──────────────────────────────────────────────────────────
    set body [frame $f.body -bg $bg -width $cw -height $ch]
    pack propagate $body 0
    pack $body -fill both -expand 1 -side top

    # ── Resize grip ───────────────────────────────────────────────────────────
    set grip [frame $f.grip \
        -width  [ttkbootstrap::_sp 12] \
        -height [ttkbootstrap::_sp 12] \
        -bg $bdr -cursor sizing]
    place $grip -relx 1.0 -rely 1.0 -anchor se

    bind $grip <Button-1>        [list mdi::resize_start $id %X %Y]
    bind $grip <B1-Motion>       [list mdi::resize_move  $id %X %Y]
    bind $grip <ButtonRelease-1> { set mdi::resize_state {} }

    # Raise on click anywhere in the window frame
    bind $f  <Button-1> [list mdi::activate $id]
    bind $tb <Button-1> "+[list mdi::activate $id]"

    # Body clicks: add a binding tag so any click inside the content area
    # (even on app child widgets) raises this MDI window.
    # We use a named tag rather than binding directly on $body children
    # (which would need re-binding after the app loads its widgets).
    set raise_tag "MDIRaise_$id"
    bind $raise_tag <Button-1> [list mdi::activate $id]
    # Prepend tag to body so it fires before the widget's own bindings
    bindtags $body [linsert [bindtags $body] 0 $raise_tag]

    $desktop create window $x $y -window $f -anchor nw -tags win_$id
    update idletasks
}

# ── Rewrite bare .widget paths in app proc bodies ────────────────────────────
proc mdi::rewrite_proc_bodies {ns body} {
    foreach p [info procs ${ns}::*] {
        set short [namespace tail $p]
        if {$short in {wm pack grid place winfo exit _close_gallery
                        tk_messageBox tk_getOpenFile tk_chooseDirectory
                        vwait _rw _qualify_cmd_opts}} continue
        if {[string match ttkbootstrap::* $short]} continue

        set oldbody [info body $p]
        set newbody [mdi::_rewrite_body $body $oldbody]
        if {$newbody eq $oldbody} continue

        set arglist {}
        foreach a [info args $p] {
            if {[info default $p $a dv]} {
                lappend arglist [list $a $dv]
            } else {
                lappend arglist $a
            }
        }
        namespace eval $ns [list proc $short $arglist $newbody]
    }
}

proc mdi::_rewrite_body {body script} {
    # Rewrite bare .widget paths token by token.
    # Handles tokens like ".fse.tv" and "[.fse.tv" by stripping leading punctuation.
    set trimchars "\[\{\"("
    set out {}
    foreach token [split $script " "] {
        set lines {}
        foreach line [split $token \n] {
            set tabs {}
            foreach tab [split $line \t] {
                set stripped [string trimleft $tab $trimchars]
                if {[string match {.[a-zA-Z_]*} $stripped] \
                        && ![string match ${body}* $stripped]} {
                    set plen [expr {[string length $tab] - [string length $stripped]}]
                    set prefix [string range $tab 0 [expr {$plen - 1}]]
                    lappend tabs ${prefix}${body}${stripped}
                } else {
                    lappend tabs $tab
                }
            }
            lappend lines [join $tabs \t]
        }
        lappend out [join $lines \n]
    }
    return [join $out " "]
}

# ── Command qualifier ─────────────────────────────────────────────────────────
# Rewrites a -command value so bare proc names defined in $ns get qualified.
# Examples (ns = ::app2):
#   "fse_search"              -> "::app2::fse_search"
#   "sw_toggle"               -> "::app2::sw_toggle"
#   [list calc_on_press $txt] -> [list ::app2::calc_on_press $txt]
#   "$widget yview"           -> unchanged (not a proc in ns)
#   "{ ... _close_gallery }"  -> unchanged (handled by global override)
proc mdi::_qualify_command {ns script} {
    set s [string trim $script]
    if {$s eq {}} { return $script }
    if {[catch {set words [list {*}$s]}]} { return $script }
    if {[llength $words] == 0} { return $script }
    set cmd [lindex $words 0]
    if {[string match "\{*" $script]} { return $script }
    if {[string match ::* $cmd]} { return $script }
    if {[string match .* $cmd]} { return $script }
    if {[string match {\[list *} $s] || [string match {[list *} $s]} {
        if {[regexp {\[list\s+(\S+)(.*)\]} $s -> inner_cmd inner_rest]} {
            if {![string match ::* $inner_cmd] &&
                [namespace eval $ns [list info procs $inner_cmd]] ne {}} {
                return "\[list ${ns}::${inner_cmd}${inner_rest}\]"
            }
        }
        return $script
    }
    if {[namespace eval $ns [list info procs $cmd]] ne {}} {
        set words [lreplace $words 0 0 ${ns}::${cmd}]
        return $words
    }
    return $script
}

# Dispatch a global proc call to the correct app namespace.
proc mdi::_dispatch_proc {short ns args} {
    if {[info procs ${ns}::${short}] ne {}} {
        return [${ns}::${short} {*}$args]
    }
    if {[info exists ::mdi::_proc_dispatch($short)]} {
        foreach dns $::mdi::_proc_dispatch($short) {
            if {[info procs ${dns}::${short}] ne {}} {
                return [${dns}::${short} {*}$args]
            }
        }
    }
    error "invalid command name \"$short\""
}

# ── Path rewriter helper ──────────────────────────────────────────────────────
# Rewrites a widget path that is a child of "." to be under $body instead.
# ".foo" → "$body.foo",  ".foo.bar" → "$body.foo.bar"
# Paths already under $body, or non-widget arguments, pass through unchanged.
proc mdi::_rw_path {body path} {
    # Must start with "." and have at least one more char, but not be "."
    if {[string length $path] < 2} { return $path }
    if {[string index $path 0] ne "."} { return $path }
    # Already under body?
    if {[string match ${body}.* $path] || $path eq $body} { return $path }
    # Is it a child of . (i.e. .something, not .something.deeper-already-abs)?
    # All children of . start with exactly one leading dot then a non-dot char.
    # (widget paths are always absolute: .foo, .foo.bar, etc.)
    return ${body}${path}
}

# ── Load app into its namespace ───────────────────────────────────────────────
proc mdi::load_app {id key gallery_dir} {
    set file [file join $gallery_dir ${key}.tcl]
    set body $::mdi::desktop.w${id}.body

    if {![file exists $file]} {
        label $body.err \
            -text "App not found:\n$file" \
            -foreground red -justify center -anchor center
        pack $body.err -fill both -expand 1
        return
    }

    set ns ::app${id}
    namespace eval $ns {}
    set ${ns}::_body $body
    set ${ns}::_id   $id

    # ── Shim: ttkbootstrap::Window → extract -themename only ─────────────────
    # Must create the child namespace before defining a proc inside it.
    namespace eval ${ns}::ttkbootstrap {}
    namespace eval $ns [list proc ttkbootstrap::Window {args} {
        array set o {-themename {}}
        catch { array set o $args }
        if {$o(-themename) ne {}} {
            catch { ::ttkbootstrap::setTheme $o(-themename) }
        }
    }]

    # ── Shim: vwait → no-op ──────────────────────────────────────────────────
    namespace eval $ns { proc vwait {args} {} }

    # ── Shim: wm → forward title, drop resizable/protocol/geometry ───────────
    namespace eval $ns [string map [list NS $ns] {
        proc wm {subcmd win args} {
            set body ${::NS::_body}
            # parent of body is the outer frame; tb.t is the title label
            set dec [winfo parent $body]
            if {$subcmd eq "title" && ($win eq "." || $win eq $dec)} {
                if {[llength $args] == 1} {
                    catch { $dec.tb.t configure -text [lindex $args 0] }
                }
                return
            }
            if {$subcmd in {resizable protocol geometry}} { return }
            catch { ::wm $subcmd $win {*}$args }
        }
    }]

    # ── Shim: exit / _close_gallery ──────────────────────────────────────────
    # Use 'after idle' so the close is never called from inside the app's
    # namespace call stack — the button command finishes, Tk processes button
    # state cleanup (instate, state !active), THEN the namespace is deleted.
    namespace eval $ns [list proc exit {args} \
        "after idle \[list ::mdi::close_win \${::${ns}::_id}\]"]
    namespace eval $ns [list proc _close_gallery {args} \
        "after idle \[list ::mdi::close_win \${::${ns}::_id}\]"]

    # ── Shim: tk_messageBox ───────────────────────────────────────────────────
    namespace eval $ns [list proc tk_messageBox {args} \
        "::mdi::themed_msgbox \${::${ns}::_body} {*}\$args"]

    # ── Shim: tk_getOpenFile / tk_chooseDirectory ─────────────────────────────
    namespace eval $ns {
        proc tk_getOpenFile {args} {
            ::ttkbootstrap::GetOpenFile {*}$args
        }
        proc tk_chooseDirectory {args} {
            ::ttkbootstrap::ChooseDirectory {*}$args
        }
    }

    # ── Widget-creation shims: rewrite first arg if child of "." ─────────────
    # We override every Tk/ttk widget-creation command so that a path like
    # ".calc" becomes "$body.calc".  All other arguments pass through as-is.
    # Must create the ::app<id>::ttk namespace before defining ttk::* procs.
    namespace eval ${ns}::ttk {}
    foreach cmd {
        frame  labelframe  canvas  text  listbox  entry  spinbox
        scrollbar  scale  button  checkbutton  radiobutton  label
        message  menu  menubutton  panedwindow
        ttk::frame  ttk::labelframe  ttk::notebook  ttk::panedwindow
        ttk::treeview
        ttk::label  ttk::entry  ttk::spinbox  ttk::combobox
        ttk::button  ttk::checkbutton  ttk::radiobutton  ttk::scale
        ttk::scrollbar  ttk::progressbar  ttk::separator  ttk::sizegrip
        ttk::menubutton
    } {
        namespace eval $ns [list proc $cmd {path args} \
            "set path \[::mdi::_rw_path \${::${ns}::_body} \$path\]
             ::$cmd \$path {*}\$args"]
    }

    # ttk::scale fires -command immediately on creation before procs are defined.
    # Override to strip -command during creation and restore it after.
    namespace eval $ns [list proc ttk::scale {path args} "
        set path \[::mdi::_rw_path \${::${ns}::_body} \$path\]
        set cmd {}
        set rest {}
        foreach {k v} \$args {
            if {\$k eq {-command}} { set cmd \$v } else { lappend rest \$k \$v }
        }
        ::ttk::scale \$path {*}\$rest
        if {\$cmd ne {}} { after idle \[list \$path configure -command \$cmd\] }
    "]

    # ── pack / grid / place: rewrite every argument that is a widget path ─────
    foreach geom {pack grid place} {
        namespace eval $ns [list proc $geom {args} \
            "set body \${::${ns}::_body}
             set out {}
             foreach a \$args { lappend out \[::mdi::_rw_path \$body \$a\] }
             ::$geom {*}\$out"]
    }

    # ── winfo: rewrite path argument ─────────────────────────────────────────
    namespace eval $ns [list proc winfo {subcmd args} \
        "set body \${::${ns}::_body}
         set out {}
         foreach a \$args { lappend out \[::mdi::_rw_path \$body \$a\] }
         ::winfo \$subcmd {*}\$out"]

    # ── Source the app ────────────────────────────────────────────────────────
    set rc [catch {
        namespace eval $ns [list source $file]
    } err opts]

    if {$rc != 0} {
        foreach w [winfo children $body] { catch {destroy $w} }
        label $body.err \
            -text "Error in $key:\n$err" \
            -foreground red -justify left -anchor nw -wraplength 350
        pack $body.err -fill both -expand 1 -padx 8 -pady 8
    }

    # ── Rewrite bare .widget paths in all app proc bodies ─────────────────────
    # App procs use paths like ".fse.tv delete ..." which worked when . was the
    # app root. Now the widgets live at $body.fse.tv. We rewrite every proc
    # body in the namespace, replacing bare .word paths with $body.word.
    mdi::rewrite_proc_bodies $ns $body
    # Tk button -command scripts run at GLOBAL scope, so "fse_search" on a
    # button resolves to ::fse_search, not ::app2::fse_search.
    # Solution: after the app is sourced, create a global proc for every
    # proc the app defined, that forwards to the namespaced version.
    # We skip procs that are already overridden globally (_close_gallery etc.)
    # and our own shim procs (wm, pack, grid, etc.).
    set skip {wm pack grid place winfo exit _close_gallery
              tk_messageBox tk_getOpenFile tk_chooseDirectory
              vwait ttkbootstrap::Window _qualify_cmd_opts _rw}
    foreach p [info procs ${ns}::*] {
        set short [namespace tail $p]
        # Skip shims and already-defined globals
        if {$short in $skip} continue
        if {[string match _* $short]} continue
        # Don't clobber existing global commands (built-ins OR other app procs)
        if {[info commands ::$short] ne {}} {
            # Already exists — append this ns to its dispatch list if it's ours
            if {[info exists ::mdi::_proc_dispatch($short)]} {
                lappend ::mdi::_proc_dispatch($short) $ns
            }
            continue
        }
        # Create a global forwarding proc
        set fqn $p
        proc ::$short {args} "::mdi::_dispatch_proc [list $short] [list $ns] {*}\$args"
        set ::mdi::_proc_dispatch($short) [list $ns]
    }

    # Propagate the raise-on-click bindtag to every widget the app created,
    # so clicking anywhere inside the MDI window raises it to the front.
    mdi::propagate_raise_tag $body "MDIRaise_$id"
}

# ── Propagate MDI raise bindtag to all descendants ───────────────────────────
# Inserts the named tag at position 0 of every widget under $root so that
# a Button-1 click anywhere in the content area raises the MDI window.
proc mdi::propagate_raise_tag {root tag} {
    foreach w [winfo children $root] {
        set tags [bindtags $w]
        if {$tag ni $tags} {
            bindtags $w [linsert $tags 0 $tag]
        }
        mdi::propagate_raise_tag $w $tag
    }
}

# ── Themed message box ────────────────────────────────────────────────────────
proc mdi::themed_msgbox {parent_body args} {
    array set o {-title "Message" -message "" -type ok -icon info}
    catch { array set o $args }

    set c   [mdi::colours]
    set ac  [dict get $c ac]
    set fg  [dict get $c fg]
    set bg  [dict get $c bg]
    set fgn [ttkbootstrap::getColor fg]
    set fnm [ttkbootstrap::_safeFont $fgn]
    set fs  [ttkbootstrap::_sf 11]

    set parent [winfo toplevel $parent_body]
    set d [toplevel .__mdi_dlg[clock milliseconds] \
        -relief solid -borderwidth 1]
    wm withdraw $d
    wm overrideredirect $d 1
    wm transient $d $parent

    frame $d.tb -bg $ac; pack $d.tb -fill x
    label $d.tb.t -text $o(-title) -bg $ac -fg $fg \
        -font [list $fnm $fs bold] -padx 8 -pady 4
    pack $d.tb.t -side left

    frame $d.body -bg $bg -padx 20 -pady 14; pack $d.body -fill x
    label $d.body.msg -text $o(-message) -bg $bg -fg $fgn \
        -font [list $fnm $fs] -wraplength 340 -justify left
    pack $d.body.msg

    frame $d.foot -bg $bg -padx 12 -pady 10; pack $d.foot -fill x
    set ::__mdi_dlg_result ok

    foreach {btext bval} {OK ok Cancel cancel Yes yes No no} {
        if {$o(-type) eq "ok"          && $btext ni {OK}}              continue
        if {$o(-type) eq "okcancel"    && $btext ni {OK Cancel}}       continue
        if {$o(-type) eq "yesno"       && $btext ni {Yes No}}          continue
        if {$o(-type) eq "yesnocancel" && $btext ni {Yes No Cancel}}   continue
        ttk::button $d.foot.[string tolower $btext] \
            -text $btext -style "primary.TButton" -padding {12 4} \
            -command [list set ::__mdi_dlg_result $bval]
        pack $d.foot.[string tolower $btext] -side right -padx 4
    }

    update idletasks
    set pw [winfo width  $parent]
    set ph [winfo height $parent]
    set px [winfo rootx  $parent]
    set py [winfo rooty  $parent]
    set dw [winfo reqwidth  $d]
    set dh [winfo reqheight $d]
    wm geometry $d +[expr {$px + ($pw-$dw)/2}]+[expr {$py + ($ph-$dh)/2}]
    wm deiconify $d
    raise $d; grab $d
    tkwait variable ::__mdi_dlg_result
    grab release $d; destroy $d
    return $::__mdi_dlg_result
}

# ── Window operations ─────────────────────────────────────────────────────────
proc mdi::activate {id} {
    variable active
    variable z_order
    variable desktop
    variable win_data

    # Guard: ignore if this window has already been closed
    if {![dict exists $win_data $id]} return
    if {![winfo exists $desktop.w$id]} return

    set z_order [lsearch -inline -all -not -exact $z_order $id]
    lappend z_order $id
    catch { $desktop raise win_$id }
    catch { raise $desktop.w$id }

    if {$id eq $active} return

    if {$active ne {}} {
        set c [mdi::colours]
        mdi::style_titlebar $active [dict get $c inact] [dict get $c inact_fg]
    }
    set active $id
    set c [mdi::colours]
    mdi::style_titlebar $id [dict get $c ac] [dict get $c fg]
}

proc mdi::style_titlebar {id bg fg} {
    variable desktop
    set tb $desktop.w$id.tb
    catch { $tb   configure -bg $bg }
    catch { $tb.t configure -bg $bg -fg $fg }
    foreach tag {cls max min} {
        catch { $tb.${tag}_$id configure -bg $bg -fg $fg }
    }
}

proc mdi::drag_start {id rx ry} {
    variable win_data
    mdi::activate $id
    set ::mdi::drag_state [list $id $rx $ry \
        [dict get $win_data $id x] [dict get $win_data $id y]]
}

proc mdi::drag_move {id rx ry} {
    variable drag_state
    variable win_data
    variable desktop
    if {$drag_state eq {}} return
    lassign $drag_state did sx sy ox oy
    if {$did != $id} return
    set nx [expr {$ox + $rx - $sx}]
    set ny [expr {$oy + $ry - $sy}]
    set dw [winfo width  $desktop]
    set dh [winfo height $desktop]
    set nx [expr {max(-[dict get $win_data $id cw]+40, min($nx, $dw-40))}]
    set ny [expr {max(0, min($ny, $dh-40))}]
    dict set win_data $id x $nx
    dict set win_data $id y $ny
    $desktop coords win_$id $nx $ny
    catch { $desktop raise win_$id }
    catch { raise $desktop.w$id }
}

proc mdi::resize_start {id rx ry} {
    variable win_data
    mdi::activate $id
    set ::mdi::resize_state [list $id $rx $ry \
        [dict get $win_data $id cw] [dict get $win_data $id ch]]
}

proc mdi::resize_move {id rx ry} {
    variable resize_state
    variable win_data
    variable desktop
    if {$resize_state eq {}} return
    lassign $resize_state did sx sy ow oh
    if {$did != $id} return
    set nw [expr {max(200, $ow + $rx - $sx)}]
    set nh [expr {max(80,  $oh + $ry - $sy)}]
    dict set win_data $id cw $nw
    dict set win_data $id ch $nh
    catch { $desktop.w$id.body configure -width $nw -height $nh }
}

proc mdi::minimise {id} {
    variable win_data
    variable desktop
    variable active
    if {[dict get $win_data $id state] eq "min"} {
        mdi::restore $id; return
    }
    dict set win_data $id state min
    $desktop itemconfigure win_$id -state hidden
    if {$active eq $id} { set active {} }
    mdi::update_taskbar
}

proc mdi::restore {id} {
    variable win_data
    variable desktop
    dict set win_data $id state normal
    $desktop itemconfigure win_$id -state normal
    mdi::activate $id
    mdi::update_taskbar
}

proc mdi::maximise {id} {
    variable win_data
    variable desktop
    set state [dict get $win_data $id state]
    if {$state eq "max"} {
        lassign [dict get $win_data $id prev_geom] x y cw ch
        dict set win_data $id x $x
        dict set win_data $id y $y
        dict set win_data $id cw $cw
        dict set win_data $id ch $ch
        dict set win_data $id state normal
        $desktop coords win_$id $x $y
        catch { $desktop.w$id.body configure -width $cw -height $ch }
    } else {
        set x  [dict get $win_data $id x]
        set y  [dict get $win_data $id y]
        set cw [dict get $win_data $id cw]
        set ch [dict get $win_data $id ch]
        dict set win_data $id prev_geom [list $x $y $cw $ch]
        set dw [winfo width  $desktop]
        set dh [winfo height $desktop]
        set tb_h [ttkbootstrap::_sp 28]
        set ncw $dw
        set nch [expr {$dh - $tb_h - 6}]
        dict set win_data $id cw $ncw
        dict set win_data $id ch $nch
        dict set win_data $id state max
        $desktop coords win_$id 0 0
        catch { $desktop.w$id.body configure -width $ncw -height $nch }
        mdi::activate $id
    }
}

proc mdi::close_win {id} {
    variable wins
    variable win_data
    variable z_order
    variable active
    variable desktop

    # Guard against double-close
    if {![dict exists $win_data $id]} return

    # Remove from tracking immediately so no further events try to use it
    set wins    [lsearch -inline -all -not -exact $wins    $id]
    set z_order [lsearch -inline -all -not -exact $z_order $id]
    catch { dict unset win_data $id }

    if {$active eq $id} {
        set active [lindex $z_order end]
    }

    # Cancel after callbacks registered by the app namespace
    set ns ::app${id}
    foreach aid [after info] {
        catch {
            if {[string match "*${ns}*" [after info $aid]]} {
                after cancel $aid
            }
        }
    }

    # Remove global proc aliases that were created for this app
    if {[info exists ::mdi::_proc_dispatch]} {
        foreach short [array names ::mdi::_proc_dispatch] {
            set ::mdi::_proc_dispatch($short) \
                [lsearch -inline -all -not -exact \
                    $::mdi::_proc_dispatch($short) $ns]
            # If no more apps own this proc, remove the global forwarder
            if {$::mdi::_proc_dispatch($short) eq {}} {
                catch { rename ::$short {} }
                unset -nocomplain ::mdi::_proc_dispatch($short)
            }
        }
    }

    # Unbind the MDIRaise tag BEFORE destroying widgets.
    set raise_tag "MDIRaise_$id"
    catch { bind $raise_tag <Button-1> {} }
    catch { bind $desktop.w$id    <Button-1> {} }
    catch { bind $desktop.w$id.tb <Button-1> {} }

    # Drain all pending Tk events (button state-machine transitions like
    # 'instate pressed', 'state !active') WHILE the widgets still exist
    # and the interp is valid. Without this, destroy triggers those
    # callbacks mid-teardown causing "deleted interpreter" in Tk 9.
    catch { update }

    # Now safe to destroy cleanly
    catch { $desktop delete win_$id }
    catch { destroy $desktop.w$id }
    catch { unset -nocomplain ${ns}::_body ${ns}::_id }

    # Activate next window and refresh taskbar now (tracking already updated)
    if {$active ne {}} { mdi::activate $active }
    mdi::update_taskbar
}

# ── Arrange ───────────────────────────────────────────────────────────────────
proc mdi::arrange {cmd} {
    variable wins
    variable win_data
    variable desktop

    set visible {}
    foreach id $wins {
        if {[dict get $win_data $id state] ne "min"} {
            lappend visible $id
        }
    }

    set dw [winfo width  $desktop]
    set dh [winfo height $desktop]
    set tb_h [ttkbootstrap::_sp 28]

    switch $cmd {
        cascade {
            set cx 30; set cy 30
            foreach id $visible {
                dict set win_data $id x $cx
                dict set win_data $id y $cy
                $desktop coords win_$id $cx $cy
                incr cx 30; incr cy 30
                if {$cx > $dw - 80} { set cx 30 }
                if {$cy > $dh - 80} { set cy 30 }
            }
        }
        tile_h {
            set n [llength $visible]
            if {$n == 0} return
            set each_h [expr {$dh / $n}]
            set y 0
            foreach id $visible {
                set ncw $dw
                set nch [expr {$each_h - $tb_h - 6}]
                dict set win_data $id x 0
                dict set win_data $id y $y
                dict set win_data $id cw $ncw
                dict set win_data $id ch $nch
                dict set win_data $id state normal
                $desktop coords win_$id 0 $y
                catch { $desktop.w$id.body configure -width $ncw -height $nch }
                incr y $each_h
            }
        }
        tile_v {
            set n [llength $visible]
            if {$n == 0} return
            set each_w [expr {$dw / $n}]
            set x 0
            foreach id $visible {
                set ncw [expr {$each_w - 4}]
                set nch [expr {$dh - $tb_h - 6}]
                dict set win_data $id x $x
                dict set win_data $id y 0
                dict set win_data $id cw $ncw
                dict set win_data $id ch $nch
                dict set win_data $id state normal
                $desktop coords win_$id $x 0
                catch { $desktop.w$id.body configure -width $ncw -height $nch }
                incr x $each_w
            }
        }
        min_all     { foreach id $visible         { mdi::minimise $id } }
        restore_all { foreach id $wins            { mdi::restore  $id } }
        close_all   { foreach id [lreverse $wins] { mdi::close_win $id } }
    }
}

# ── Taskbar ───────────────────────────────────────────────────────────────────
proc mdi::update_taskbar {} {
    variable wins
    variable win_data
    variable taskbar
    variable active

    foreach w [winfo children $taskbar] {
        if {$w ne "$taskbar.clk"} { destroy $w }
    }

    set c       [mdi::colours]
    set ac      [dict get $c ac]
    set fg      [dict get $c fg]
    set ac_dark [dict get $c ac_dark]
    set fnm     [ttkbootstrap::_safeFont [ttkbootstrap::getColor font]]
    set fs      [ttkbootstrap::_sf 10]

    foreach id $wins {
        set title  [dict get $win_data $id title]
        set state  [dict get $win_data $id state]
        set relief [expr {$state eq "min" ? "sunken" : "flat"}]
        set is_act [expr {$id eq $active}]
        set tbg    [expr {$is_act ? $ac : $ac_dark}]

        set b [label $taskbar.tb$id \
            -text " $title " -bg $tbg -fg $fg \
            -font [list $fnm $fs] \
            -relief $relief -borderwidth 1 \
            -padx 6 -pady 2 -cursor hand2]
        pack $b -side left -padx 2 -pady 3

        bind $b <Button-1> [list mdi::taskbar_click $id]
        bind $b <Enter>    [list $b configure -bg $ac]
        bind $b <Leave>    [list $b configure -bg $tbg]
    }
}

proc mdi::taskbar_click {id} {
    variable win_data
    if {[dict get $win_data $id state] eq "min"} {
        mdi::restore $id
    } else {
        mdi::activate $id
    }
}

# ── Theme restyle ─────────────────────────────────────────────────────────────
proc mdi::restyle {} {
    variable wins
    variable win_data
    variable desktop
    variable taskbar
    variable active

    set c       [mdi::colours]
    set ac      [dict get $c ac]
    set fg      [dict get $c fg]
    set bg      [dict get $c bg]
    set bdr     [dict get $c bdr]

    $desktop configure -bg [dict get $c desktop_bg]
    mdi::draw_grid

    .mdi.menubar configure -bg $ac
    foreach w [winfo children .mdi.menubar] {
        catch { $w configure -bg $ac -fg $fg }
    }
    $taskbar configure -bg $ac
    catch { $taskbar.clk configure -bg $ac -fg $fg }

    foreach id $wins {
        set is_act [expr {$id eq $active}]
        set tbc [expr {$is_act ? $ac : [dict get $c inact]}]
        set tff [expr {$is_act ? $fg : [dict get $c inact_fg]}]
        catch { $desktop.w$id      configure -bg $bdr }
        mdi::style_titlebar $id $tbc $tff
        catch { $desktop.w$id.body configure -bg $bg }
        catch { $desktop.w$id.grip configure -bg $bdr }
    }
    mdi::update_taskbar
}

# ── Main window ───────────────────────────────────────────────────────────────
ttkbootstrap::Window -themename flatly -title "ttkbootstrap MDI Desktop" -size {1200 780}
proc mdi::_close_mdi {} {
    mdi::arrange close_all
    wm protocol . WM_DELETE_WINDOW {}
    after 50 { catch { destroy . } }
}

wm protocol . WM_DELETE_WINDOW { mdi::_close_mdi }

# Save the showcase-provided _close_gallery alias BEFORE we override it,
# so we can call it to properly close the whole MDI (interp delete).
proc mdi::_close_mdi {} {
    mdi::arrange close_all
    after 50 { catch { destroy . } }
}

# Override the global ::_close_gallery that showcase.tcl may have aliased to
# 'interp delete'. Tk button -command scripts run at GLOBAL scope, so when
# an embedded app's quit/cancel button fires "_close_gallery" it resolves to
# THIS proc, not the per-app ::appN::_close_gallery shim.
# We identify which MDI window triggered the call by checking which body
# frame the currently focused widget belongs to, then close that window.
proc ::_close_gallery {args} {
    set fw [focus]
    if {$fw eq {}} return
    # Walk up the widget hierarchy to find .mdi.desktop.wN.body
    set w $fw
    while {$w ne {}} {
        if {[regexp {^\.mdi\.desktop\.(w\d+)\.body} $w -> wid]} {
            # Extract the numeric id
            set id [string range $wid 1 end]
            after idle [list ::mdi::close_win $id]
            return
        }
        set w [winfo parent $w]
    }
}

# Override global file dialog procs so button -command scripts (which run at
# global scope) use the ttkbootstrap pure-Tk dialogs, not the WM ones.
proc ::tk_getOpenFile {args} {
    ::ttkbootstrap::GetOpenFile {*}$args
}
proc ::tk_chooseDirectory {args} {
    ::ttkbootstrap::ChooseDirectory {*}$args
}
proc ::tk_messageBox {args} {
    # Find the active MDI window to use as parent
    set parent .
    if {$::mdi::active ne {}} {
        set parent $::mdi::desktop.w${::mdi::active}.body
    }
    ::mdi::themed_msgbox $parent {*}$args
}

# Save the original unknown handler then replace it.
# App procs use bare .widget paths like ".fse.tv delete ..." which need
# rewriting to $body.fse.tv. We catch those in ::unknown before falling
# through to the saved original (avoiding the ::tcl::unknown recursion trap).
rename ::unknown ::mdi::_orig_unknown
proc ::unknown {args} {
    set cmd [lindex $args 0]
    if {[string match .* $cmd]} {
        foreach id $::mdi::wins {
            set body $::mdi::desktop.w${id}.body
            set candidate ${body}${cmd}
            if {[info commands $candidate] ne {}} {
                return [$candidate {*}[lrange $args 1 end]]
            }
        }
        error "invalid command name \"$cmd\""
    }
    ::mdi::_orig_unknown {*}$args
}

frame .mdi -bg [ttkbootstrap::getColor bg]
pack  .mdi -fill both -expand 1
mdi::build

# ── Welcome panel ─────────────────────────────────────────────────────────────
after 300 {
    update idletasks
    set dw  [winfo width  $mdi::desktop]
    set dh  [winfo height $mdi::desktop]
    set c   [mdi::colours]
    set bg  [dict get $c bg]
    set fgn [ttkbootstrap::getColor fg]
    set fnm [ttkbootstrap::_safeFont $fgn]
    set fs  [ttkbootstrap::_sf 11]
    set tb_h [ttkbootstrap::_sp 28]

    set id [incr mdi::next_id]
    set cw 420
    set ch 240
    set x  [expr {($dw - $cw) / 2}]
    set y  [expr {($dh - $ch - $tb_h) / 2}]

    lappend mdi::wins    $id
    lappend mdi::z_order $id
    dict set mdi::win_data $id x     $x
    dict set mdi::win_data $id y     $y
    dict set mdi::win_data $id cw    $cw
    dict set mdi::win_data $id ch    $ch
    dict set mdi::win_data $id state normal
    dict set mdi::win_data $id title "Welcome"
    dict set mdi::win_data $id key   welcome

    mdi::create_win_frame $id $x $y $cw $ch $tb_h \
        "Welcome to ttkbootstrap MDI"

    set body $mdi::desktop.w${id}.body

    label $body.h \
        -text "ttkbootstrap MDI Desktop" \
        -bg $bg -fg [ttkbootstrap::getColor primary] \
        -font [list $fnm [ttkbootstrap::_sf 15] bold]
    pack $body.h -pady {8 6}

    set i 0
    foreach txt {
        "Use the Apps menu to open gallery applications."
        "Use Arrange to tile or cascade open windows."
        "Drag title bars to move \u00b7 drag corner grip to resize."
        "Change theme with the dropdown in the menu bar."
    } {
        label $body.t[incr i] \
            -text $txt -bg $bg -fg $fgn \
            -font [list $fnm $fs] -justify left
        pack $body.t$i -anchor w -padx 16 -pady 1
    }

    ttk::button $body.ok \
        -text "Get Started" -style "primary.TButton" -padding {20 6} \
        -command [list mdi::close_win $id]
    pack $body.ok -pady {10 0}

    mdi::activate $id
    mdi::update_taskbar
}

if {![info exists ::tcl_interactive] || !$::tcl_interactive} {
    vwait forever
}
