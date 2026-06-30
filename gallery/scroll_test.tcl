# scroll_test.tcl — pure Tk mousewheel diagnostic
# Run: ./tclkit gallery/scroll_test.tcl
# Scroll the mousewheel anywhere over this window.
# Something MUST change if Tk is receiving events.

package require Tk

wm title . "Scroll Test"
wm geometry . 500x400

# ── Status display ────────────────────────────────────────────────────────────
set ::count 0
set ::last  "(none yet — scroll the mousewheel!)"

label .title -text "MOUSEWHEEL DIAGNOSTIC" -font {TkDefaultFont 14 bold} -fg blue
label .count -textvariable ::count -font {TkDefaultFont 24 bold} -fg red \
    -text "0"
label .label1 -text "↑ This number must change when you scroll ↑" -fg gray
label .last  -textvariable ::last -wraplength 480 -justify left
label .ws    -text "Windowing: [tk windowingsystem]   Tk: [package version Tk]" -fg gray

pack .title  -pady 10
pack .count  -pady 5
pack .label1
pack .last   -pady 10 -padx 20
pack .ws     -pady 5

frame .sep -height 2 -bg gray
pack .sep -fill x

# ── Scrollable content ────────────────────────────────────────────────────────
canvas .c -yscrollcommand {.sb set} -bg #f0f0f0 -relief sunken -bd 1
scrollbar .sb -orient vertical -command {.c yview}
pack .sb -side right -fill y
pack .c  -fill both -expand 1 -padx 4 -pady 4

frame .c.f -bg #f0f0f0
.c create window 0 0 -anchor nw -window .c.f

for {set i 1} {$i <= 40} {incr i} {
    set bg [expr {$i % 2 ? "#e8e8ff" : "#f0f0f0"}]
    frame .c.f.r$i -bg $bg -padx 4 -pady 3
    label .c.f.r$i.l -text "Row $i — scroll the mousewheel here" \
        -width 45 -anchor w -bg $bg -font {TkDefaultFont 11}
    button .c.f.r$i.b -text "Button $i" -relief raised
    pack .c.f.r$i.l .c.f.r$i.b -side left -padx 4
    pack .c.f.r$i -fill x
}

bind .c.f <Configure> {
    update idletasks
    .c configure -scrollregion [.c bbox all]
}
update
# Force scrollregion now
.c configure -scrollregion [.c bbox all]

# ── Bindings — try EVERY possible approach ────────────────────────────────────

proc got_event {source W X Y {D 0}} {
    incr ::count
    # D=-120 = scroll down through content (+3 units), D=+120 = scroll up (-3 units)
    # Button-4 = scroll up (-3), Button-5 = scroll down (+3)
    if {$D < 0} {
        set delta [expr {int($D / -40)}]  ;# -120 → +3
    } elseif {$D > 0} {
        set delta [expr {int($D / -40)}]  ;# +120 → -3
    } elseif {$source eq "B4"} {
        set delta -3
    } else {
        set delta 3
    }
    set before [lindex [.c yview] 0]
    .c yview scroll $delta units
    set after [lindex [.c yview] 0]
    set ::last "W=$W  D=$D  delta=$delta  yview: $before → $after"
    puts "SCROLL: $::last"
}

set ws [tk windowingsystem]

# 1. Directly on canvas
bind .c <Button-4>   { got_event B4/canvas %W %X %Y }
bind .c <Button-5>   { got_event B5/canvas %W %X %Y }
bind .c <MouseWheel> { got_event MW/canvas %W %X %Y %D }

# 2. On the inner frame
bind .c.f <Button-4>   { got_event B4/frame %W %X %Y }
bind .c.f <Button-5>   { got_event B5/frame %W %X %Y }
bind .c.f <MouseWheel> { got_event MW/frame %W %X %Y %D }

# 3. On toplevel .
bind . <Button-4>   { got_event B4/toplevel %W %X %Y }
bind . <Button-5>   { got_event B5/toplevel %W %X %Y }
bind . <MouseWheel> { got_event MW/toplevel %W %X %Y %D }

# 4. On "all"
bind all <Button-4>   { got_event B4/all %W %X %Y }
bind all <Button-5>   { got_event B5/all %W %X %Y }
bind all <MouseWheel> { got_event MW/all %W %X %Y %D }

# 5. Print to terminal as well
puts "Waiting. Windowing system: $ws"
puts "Scroll the mousewheel over the window..."
puts "(events will print here too)"

# Also trace via terminal
bind all <Button-4>   {+ puts "TERM: Button-4 W=%W X=%X Y=%Y"}
bind all <Button-5>   {+ puts "TERM: Button-5 W=%W"}
bind all <MouseWheel> {+ puts "TERM: MouseWheel W=%W D=%D"}

wm protocol . WM_DELETE_WINDOW { exit }
vwait forever
