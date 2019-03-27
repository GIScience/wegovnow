package provide lrs 0.1
package require math::constants
package require n-kov
    
package require math::geometry
#namespace import ::math::geometry::*

namespace eval n-kov::lrs {
    
    

   # lrs::segment --
   #    
   #   A function for getting equidistant points lieing on
   #   a line, point difined by distance from starting of
   #   the line, or vertices until distance from starting.
   #
   # Arguments:
   #
   #   points     points in format "x0 y0 x1 y1 ..."
   #
   #   distance   distance between neighbour equidistant
   #              points in mode 0 or distance from line
   #              starting in mode 1 and 2.
   #
   #   mode       (optional)
   #              0 - return equidistant points, default;
   #              1 - return point  difined by distance
   #                  from starting of line;
   #              2 - return vertices until distance from
   #                  starting.
   #
   # Results:
   #
   #    See the mode argument explanation above.
   #
    
    proc segment {points distance {mode 0}} {	
	namespace import ::math::geometry::*
	set result {}
	set distance [expr double($distance)]
	set prev "[lindex $points 0] [lindex $points 1]"
	lappend result {*}$prev
	set curdist $distance
	foreach {x y} [lrange $points 2 end] {
	    set p "$x $y"
	    set while_continue 1	   
	    while {$while_continue} {
		set interval [distance $prev $p]
		set remainder [expr $interval-$curdist]
		if {$remainder > 0.0} {
		    set prev [between $prev $p [expr $curdist/$interval]]
		    if {$mode == 1} {
			return $prev
		    } elseif {$mode == 2} {
			return $result
		    } else {
			lappend result {*}$prev
		    }

		    set curdist $distance
		} else {
		    set curdist [expr -$remainder]
		    set prev $p
		    set while_continue 0
		}

	    }	   
	    if {$mode == 2} {
		lappend result $x $y
	    }	   	   
	}
	return $result
   }
   

   proc reversePolyline {points} {
       set out {}
       set i [expr [llength $points]-1]
       while {$i>=0} {
	   set x [lindex $points [expr $i-1]]
	   set y [lindex $points $i]
	   lappend out $x $y
	   incr i -2
       }
       return $out
   }


   proc SplitToThree {polyline start end} {
       set l [::math::geometry::lengthOfPolyline $polyline]
       set startP [segment $polyline $start 1]
       set endP [segment $polyline $end 1]
       set first  [segment $polyline $start 2]
       set first "$first $startP"
       set second [segment $polyline $end 2]
       set second "$second $endP"
       set second [reversePolyline [segment [reversePolyline $second] [expr [::math::geometry::lengthOfPolyline $second]-$start] 2]]
       set second "$startP $second" 
       set third  [reversePolyline [segment [reversePolyline $polyline] [expr $l-$end] 2]]
       set third "$endP $third"
       return [list $first $second $third]
   }
       
   
   proc splitPolyline {polyline start length} {
       set l [::math::geometry::lengthOfPolyline $polyline]
       set end [expr $start+$length]
       if {$end > $l} {
	   lassign "$start $end" end start
	   set start [expr $start-$l]
       }
       lassign [SplitToThree $polyline $start $end] first second third
       return [list [list "$third $first"] [list "$second"]]
       #set startP [segment $polyline $start 1]
       #set endP [segment $polyline $end 1]
       #return [list [list {*}$startP {*}$second {*}$endP] [list {*}$endP {*}$third {*}$first {*}$startP]]
       
   }   
}

# proc IGNORE {} {
#     .c delete lrs
#     lassign [lrs::splitPolyline $pts(group_0) 1800 500] left right    
#     .c create line $left -fill yellow -tags lrs
#     .c create line $right -fill green -tags lrs


#     .c delete lrs;.c create line $first -fill yellow -tags lrs
    
#     .c delete delme
#     drawPoint .c {*}$endP 5 blue {} delme

#     lassign [lrs::splitPolyline $pts(group_0) 150 300] left right;.c delete lrs; .c create line $left -fill red -tags lrs; .c create line $right -fill yellow -tags lrs

#     set polyline "$pts(group_0) [lrange $pts(group_0) 0 1]"
#     lassign "1000 300" start length

#     .c delete lrs; .c create line $first -fill yellow -tags lrs


    
	    
# }

# set cur_desc "A place for shape descriptor"
# set seg_length 400
# set point_distance 20
# set isPolygon 1
# set tagId 0


# proc splitAndDraw {polyline start length {left_color red} {right_color yellow}} {
#     global cur_desc
#     global descs
#     global point_distance
#     global pnumber
#     #puts "DEBUG:: $start $length"
#     lassign [lrs::splitPolyline $polyline  $start $length] left right
#     set left {*}$left
#     set right {*}$right
#     .c delete lrs
#     .c create line $left -fill $left_color -tags lrs
#     .c create line $right -fill $right_color -tags lrs
#     if {[::math::geometry::lengthOfPolyline $left] < [::math::geometry::lengthOfPolyline $right]} {
# 	lassign "[list $left] [list $right]" right left
# 	lassign "$left_color $right_color" right_color left_color	
#     }

#     if ![info exists pnumber] {
# 	set pnumber [expr [::math::geometry::lengthOfPolyline $left]/${point_distance}.0]
#     }    
	
#     set dist1 [expr [::math::geometry::lengthOfPolyline $left]/$pnumber]	
#     set edp1 [lrs::segment $left $dist1]	
#     set dist2 [expr [::math::geometry::lengthOfPolyline $right]/$pnumber]
#     set edp2 [lrs::segment $right $dist2]
#     .c delete tmp_edp
#     #puts "edp1::$edp1\n\nedp2::$edp2"
#     set par1 "\["
#     foreach {x y} $edp1 {
# 	set par1 "$par1\[$x,$y\],"
#     }
#     set par1 [string trim $par1 ,]
#     set par1 "$par1\]"
    
#     set par2 "\["
#     foreach {x y} $edp2 {
# 	set par2 "$par2\[$x,$y\],"
#     }
#     set par2 [string trim $par2 ,]
#     set par2 "$par2\]"
#     #puts "edp1::$par1\n\nedp2::$par2"
#     set cur_desc [exec python desc.py $par1 $par2]
#     set descs($start,$length) $cur_desc
#     #puts "Len1=[llength $edp1] ; Len2=[llength $edp2]"
#     foreach {points color} "[list $edp1] $left_color [list $edp2] $right_color" {
# 	foreach {x y} $points {
# 	    drawPoint .c $x $y "tmp_edp $color" 3 $color $color
# 	    .c raise edpts
# 	}
#     }

# }


# proc animate {{delay 1} {index group_0}} {
#     global point_distance
#     global seg_length
#     global pts
#     global cur_desc
#     global descs
#     set pl "$pts($index) [lrange $pts($index) 0 1]"
#     set plLength [::math::geometry::lengthOfPolyline $pl]
#     for {set l $seg_length} {$l<[expr $plLength/2.0]} {incr l $point_distance} {
# 	for {set i 0} {$i<$plLength} {incr i $point_distance} {
# 	    splitAndDraw $pl $i $l
# 	    update
# 	    #after $delay
# 	}
#     }
    
#     catch {unset dmax}
#     foreach n [array names descs] {
# 	if {(![info exists dmax]) || ($dmax<$descs($n))} {
# 	    set dmax $descs($n)
# 	    set dindx $n
# 	}
#     }
#     splitAndDraw "$pts($index) [lrange $pts($index) 0 1]" {*}[split $dindx ,]
#     set cur_desc $dmax
# }

# proc findPoint {x y} {
#     set delta 4
#     global pts
#     global tagId
#     global seg_length
#     global point_distance
#     set CurTagId [expr $tagId-1]
#     set i 0
#     foreach {cx cy} $pts(edp_$CurTagId) {
# 	if {[distance "$cx $cy" "$x $y"] <= $delta} {
# 	    #set start [expr $i/2.0] 
# 	    splitAndDraw "$pts(group_$CurTagId) [lrange $pts(group_$CurTagId) 0 1]" [expr ${i}.0*$point_distance] $seg_length	    
# 	    return OK
# 	}
# 	incr i
#     }    
# }

# proc drawPoint {canv x y tag {delta 2} {outline black} {fill black}} {
#     $canv create oval [expr $x-$delta] [expr $y-$delta] [expr $x+$delta] [expr $y+$delta] -outline $outline -fill $fill -tags $tag
# }

# proc addAndDrawPoint {canv x y} {
#     global tagId
#     global pts
#     if ![info exists pts] {
# 	array set pts {}
#     }
#     if ![info exist pts(group_$tagId)] {
# 	set pts(group_$tagId) "$x $y"
#     } else {
# 	lappend pts(group_$tagId) $x $y
#     }
#     drawPoint $canv $x $y "group_$tagId vertex"
# }
    

# proc finishLine {canv {outline blue} {fill lightblue}} {
#     global isPolygon
#     global tagId    
#     global pts
#     global point_distance

#     set points $pts(group_$tagId)

    
#     if $isPolygon {
# 	$canv create polygon $points -outline $outline -fill $fill -tags "group_$tagId polygon"
#         lappend points {*}[lrange $points 0 1]	
#     } else {
# 	$canv create line $points -fill $outline -tags "group_$tagId line"
#     }

#     set idp 0
#     set eqDist [lrs::segment $points $point_distance]
#     set pts(edp_$tagId) $eqDist
#     foreach {x y} $eqDist {
# 	#.c create oval [expr $x-1] [expr $y-1] [expr $x+1] [expr $y+1] -outline red -fill red -tags "group_$tagId edpts"
# 	drawPoint .c $x $y "group_$tagId edpts $idp" 1 blue blue
# 	incr idp
#     }
#     .c raise vertex
#     .c raise edpts    
#     incr tagId    
# }

# checkbutton .ispol -text "Make polygon" -variable isPolygon -onvalue 1 -offvalue 0
# button .clear -text "Clear canvas" -command ".c delete all;catch {unset pts};set tagId 0;catch {unset pnumber}; catch {unset descs};set cur_desc {A place for shape descriptor}"
# grid .ispol -column 0 -row 0
# grid .clear -column 1 -row 0
# label .dist_label -text "Enter equidistant point interval:"
# grid .dist_label -column 2 -row 0
# entry .ent -textvariable point_distance -background white
# grid .ent -column 3 -row 0
# label .len_label -text "Set segment length here:"
# entry .seglen -textvariable seg_length -background white
# button .animate -text "Start animation"  -command "animate $point_distance"
# label .desc -textvariable cur_desc
# grid .len_label -column 0 -row 1
# grid .seglen -column 1 -row 1
# grid .animate -column 2 -row 1
# grid .desc -column 3 -row 1
# canvas .c -width 800 -height 600 -background lightgreen
# grid .c -column 0 -row 2 -columnspan 5

# bind .c <Double-1> "finishLine .c"
# bind .c <Button-1> "addAndDrawPoint .c %x %y"
# bind .c <Button-3> "findPoint %x %y"
# #bind .c <Button-3> {puts "X=%x Y=%y"}
# wm title . "Shape descriptor"

