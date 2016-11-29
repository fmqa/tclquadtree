# quadtree.tcl --
#
#   Tcl implementation of basic quadtree operators.
#
# License: Tcl/BSD style.

package provide quadtree 1.0

namespace eval ::quadtree {
    namespace export *
    namespace ensemble create
}

# quadtree::resize --
#
#   Sets the bounding box for the given quadtree node.
#
# resize tree node x y w h

proc ::quadtree::resize {t node x y w h} {
    $t set $node x $x
    $t set $node y $y
    $t set $node w $w
    $t set $node h $h
}

# quadtree::contains --
#
#   Returns 1 if a quadtree node contains the given rectangle, 0 otherwise.
#
# contains tree node x y w h

proc ::quadtree::contains {t node x y w h} {
    set xn [$t get $node x]
    set yn [$t get $node y]
    set wn [$t get $node w]
    set hn [$t get $node h]
    expr {
        ($x >= $xn) && 
        ($y >= $yn) && 
        ($x + $w <= $xn + $wn) && 
        ($y + $h <= $yn + $hn)
    }
}

# quadtree::quarter --
#
#   Given a quadtree node, attach four child nodes to it covering
#   its four quadrants.
#
# quarter tree node

proc ::quadtree::quarter {t node} {
    set x [$t get $node x]
    set y [$t get $node y]
    set w [$t get $node w]
    set h [$t get $node h]
    # ne quadrant
    set ne [$t insert $node 0]
    $t set $ne x [expr {$x + $w / 2}]
    $t set $ne y [expr {$y + $h / 2}]
    $t set $ne w [expr {$w / 2}]
    $t set $ne h [expr {$h / 2}]
    # nw quadrant
    set nw [$t insert $node 1]
    $t set $nw x $x
    $t set $nw y [expr {$y + $h / 2}]
    $t set $nw w [expr {$w / 2}]
    $t set $nw h [expr {$h / 2}]
    # sw quadrant
    set sw [$t insert $node 2]
    $t set $sw x $x
    $t set $sw y $y
    $t set $sw w [expr {$w / 2}]
    $t set $sw h [expr {$h / 2}]
    # se quadrant
    set se [$t insert $node 3]
    $t set $se x [expr {$x + $w / 2}]
    $t set $se y $y
    $t set $se w [expr {$w / 2}]
    $t set $se h [expr {$h / 2}]
    list $ne $nw $sw $se
}

# quadtree::bestfit --
#
#   Return the most minimal node containing the given rectangle.
#
# bestfit tree node x y w h

proc ::quadtree::bestfit {t node x y w h} {
    foreach child [$t children $node] {
        if {[::quadtree::contains $t $child $x $y $w $h]} {
            return [::quadtree::bestfit $t $child $x $y $w $h]
        }
    }
    return $node
}

# quadtree::insert --
#
#   Insert a rectangular object into the given quadtree.
#
# insert tree node rect

proc ::quadtree::insert {t node a} {
    set x [dict get $a x]
    set y [dict get $a y]
    set w [dict get $a w]
    set h [dict get $a h]
    set target [::quadtree::bestfit $t $node $x $y $w $h]
    $t lappend $target data $a
    return $target
}

# quadtree::dist --
#
#   Distribute objects held by a given quadtree node to that
#   node's children.
#
# dist tree node

proc ::quadtree::dist {t node} {
    set empty [catch {$t get $node data} data]
    set data [expr {$empty ? [list] : $data}]
    $t unset $node data
    foreach element $data {
        ::quadtree::insert $t $node $element
    }
}

# quadtree::proximate --
#
#   Given a quadtree node, iterate over lists representing
#   clusters of objects contained within it or in close proximity to it.
#
# proximate tree node dataVar script

proc ::quadtree::proximate {t node datavar script} {
    upvar $datavar data
    while {$node ne {}} {
        if {![catch {$t get $node data} data]} {
            set code [catch {uplevel 1 $script} message options]
            switch -- $code {
                0 {}
                1 -
                2 {return -options $options $message}
                3 {return}
                4 {}
                default {return -options $options $message}
            }
        }
        set node [$t parent $node]
    }
}

# quadtree::near --
#
#   Given a rectangle, iterate over lists representing
#   clusters of objects within it or in close proximity to it.
#
# near tree node x y w h dataVar script

proc ::quadtree::near {t node x y w h datavar script} {
    uplevel 1 [list ::quadtree::proximate $t [::quadtree::bestfit $t $node $x $y $w $h] $datavar $script]
}

namespace eval ::quadtree::limit {
    namespace export *
    namespace ensemble create -parameters n
}

# quadtree::limit::insert --
#
#   Insert a rectangular object into the given quadtree, ensuring
#   that the containing quadtree node contains N objects at most.
#
# limit N insert tree node rect

proc ::quadtree::limit::insert {n t node a} {
    set target [::quadtree::insert $t $node $a]
    set data [$t get $target data]
    set count [llength $data]
    if {$count >= $n && [$t isleaf $target]} {
        ::quadtree::quarter $t $target
        ::quadtree::dist $t $target
    }
    return $target
}

