package require Tk
package require struct::tree
package require quadtree

set count 0

font create nodefnt -family Helvetica -size 8 -weight bold
font create boxfnt -family Helvetica -size 8 -weight normal

wm title . "Quadtree Visualization"
grid [tk::canvas .canvas] -sticky nwes -column 0 -row 0
grid columnconfigure . 0 -weight 1
grid rowconfigure . 0 -weight 1

toplevel .aux
wm title .aux "Quadtree Model"
wm minsize .aux 320 440
grid [ttk::treeview .aux.tree] -sticky nwes -column 0 -row 0
grid columnconfigure .aux 0 -weight 1
grid rowconfigure .aux 0 -weight 1

proc render {canvas t} {
    $canvas delete all
    if {[.aux.tree exists root]} {
        .aux.tree delete root
    }
    set x [$t get root x]
    set y [$t get root y]
    set w [$t get root w]
    set h [$t get root h]
    .aux.tree insert {} end -id root -text "root \[$x,$y,$w,$h\]" -open true
    $t walk root node {
        set empty [catch {$t get $node data} data]
        set x [$t get $node x]
        set y [$t get $node y]
        set w [$t get $node w]
        set h [$t get $node h]
        set p [expr {$x + $w}]
        set q [expr {$y + $h}]
        $canvas create rectangle $x $y $p $q
        $canvas create text [expr {$x + $w / 2}] [expr {$y + $h / 2}] -text $node -font boxfnt
        set parent [$t parent $node]
        if {$parent ne {}} {
            .aux.tree insert $parent end -id $node -text "$node \[$x,$y,$w,$h\]" -open true
        }
        if {!$empty} {
            foreach item $data {
                set ord [dict get $item ord]
                set x [dict get $item x]
                set y [dict get $item y]
                set w [dict get $item w]
                set h [dict get $item h]
                set p [expr {$x + $w}]
                set q [expr {$y + $h}]
                $canvas create oval $x $y $p $q -fill red
                $canvas create text $x $y -text "$ord  " -font nodefnt
                .aux.tree insert $node end -id $ord -text "$ord \[$x,$y,$w,$h\]"
            }
        }
    }
}

bind .canvas <Configure> {
    if {[catch {struct::tree tree}]} {
        set count 0
        tree destroy
        struct::tree tree
    }
    quadtree resize tree root 0 0 "%w" "%h"
    render .canvas tree
}

bind .canvas <1> {
    quadtree limit 4 insert tree root [dict create x "%x" y "%y" w 8 h 8 ord $count]
    incr count
    render .canvas tree
}
