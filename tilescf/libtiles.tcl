# libtiles.tcl - Tiles Common Framework -
# 
#    a microframework implementing commot procedures
#    for geo tile processing. An extention of slippy
#    map library.
#
#
# References and credits:
#
#    [1] https://wiki.tcl.tk/
#    [2] https://msdn.microsoft.com/en-us/library/bb259689.aspx
#    [3] http://wiki.openstreetmap.org/wiki/Slippy_map_tilenames
#    [4] http://wiki.openstreetmap.org/wiki/Zoom_levels
#    [5] https://en.wikipedia.org/wiki/Well-known_text
#    [6] https://en.wikipedia.org/wiki/GeoJSON
#    [7] http://docs.activestate.com/activetcl/8.6/tcllib/math/math_geometry.html
#
# Bugs:
#    it looks that the current implementation of
#    the slippy map library does not take into account 
#    sign of lat/lon (all coordinates are positive only).
#    It is fixed by functions tile2geo

package provide libtiles 0.6
package require math::constants
package require math::geometry
package require n-kov
#package require map::slippy

namespace eval n-kov::tilescf {
    
    math::constants::constants pi radtodeg degtorad    
    variable epsilon 4.030385636344391e-8

    proc tiles {level} {
	return [expr {1 << $level}]
    }
    
    
    #getEpsilon 0 70 21

    
    # tile2quadkey --
    #
    #        Convert tile coordinate (z/x/y) to quadkey. See [2] for details.
    #
    # Arguments:
    #        col    x tile coordinate,
    #        row    y tile coordinate,
    #        zl     zoom level.
    #
    # Results:
    #        quadkey
    #Now, based on  https://msdn.microsoft.com/en-us/library/bb259689.aspx
    proc tile2quadkey {col row zl} {	
	set out ""
	for {set i $zl} {$i > 0} {incr i -1} {
	    set value 0
	    set mask [expr {1 << ( $i - 1 )}]
	    if {[expr {$col & $mask}] != 0} {
		incr value		
	    }		
	    if {[expr {$row & $mask}] != 0} {
		incr value
		incr value
	    }
	    append out $value
	}	
	return $out
    }
    
    
    #  quadkey2tile --
    #
    #        Convert quadkey to tile coordinates (z/x/y). See [2] for details.
    #
    # Arguments:
    #        qkey    quadkey of tile
    #
    # Results:
    #        "x y zl" returns tile coordinate
    # Now, based on  https://msdn.microsoft.com/en-us/library/bb259689.aspx
    proc quadkey2tile {qkey} {
	set tileX  0
	set tileY  0
	set detail [string length $qkey]
	for {set i $detail} {$i > 0} {incr i -1} {
	    set mask [expr {1 << ($i - 1)}]	    
	    switch [string index $qkey [expr {$detail - $i}]] {
		0 {		    
		}
		1 {
		    set tileX [expr {$tileX | $mask}]
		}
		2 {
		    set tileY [expr {$tileY | $mask}]
		}
		3 {
		    set tileX [expr {$tileX | $mask}]
		    set tileY [expr {$tileY | $mask}]
		}
		default {error "${::n-kov::errorHeader} Bad Quadkey"}
	    }
	}
	return "$tileX $tileY $detail"	
    }

    
    #  tile2geo --
    #
    #        Convert tile coordinates (z/x/y) to lat/long. See [2] for details.
    #        Refinement of {::map::slippy tile 2geo} function. Order of input
    #        and output has been changes. 
    #
    # Arguments:
    #        col    x tile coordinate,
    #        row    y tile coordinate,
    #        zl     zoom level.
    #
    # Results:
    #        "x y" lat/long coordinates.
    #
    # See Bugs above.
        
    proc tile2geo {col row zl} {	
	::variable radtodeg
	::variable pi
	set tiles [tiles $zl]
	set y [expr {$radtodeg * (atan(sinh($pi * (1 - 2 * $row / double($tiles)))))}]
	set x [expr {$col / double($tiles) * 360.0 - 180.0}]
	return "$x $y"
    }
    
    
    #  geo2tile --
    #
    #        Convert tile lat/long coordinates to tile coordinates.
    #        See [2] for details. Refinement of {::map::slippy geo 2tile} function.
    #        Order of input and output has been changes.
    #
    # Arguments:
    #        x     longitude,
    #        y     latitude,
    #        zl    zoom level.
    #
    # Results:
    #        "col row" col and row tile coordinates.
    #
    # See Bugs above.
        
    proc geo2tile {x y zl {isfloat 0}} { 
	::variable degtorad
	::variable pi
	set tiles  [tiles $zl]
	set latrad [expr {$degtorad * $y}]
	set row [expr {(1 - (log(tan($latrad) + 1.0/cos($latrad)) / $pi)) / 2 * $tiles}]
	set col [expr {(($x + 180.0) / 360.0) * $tiles}]
	if {!$isfloat} {
	    set row [expr {int($row)}]
	    set col [expr {int($col)}]
	}	
	return "$col $row"
    }
    
    
    #  getPixelSize --
    #
    #        Get tiles' pixel width in meters.
    #
    # Arguments:
    #        y     latitude,
    #        zl    zoom level.
    #
    # Results:
    #        width (or height) in meters.
        

    proc getPixelSize {y zl} {
	return [expr {40075696*cos($::math::constants::degtorad*$y)/2**($zl+8)}]
    }
    
    
    # getEpsilon  --
    #
    #        Get tiles' pixel width in meters.
    #
    # Arguments:
    #        x     longitude,
    #        y     latitude,
    #        zl    zoom level.
    #
    # Results:
    #        width (or height) in meters.
    #
    # See [4].    

    proc getEpsilon {x y zl} {
	lassign [geo2tile $x $y $zl] col row
	lassign [tile2geo [expr {$col+1}] [expr {$row+1}] $zl] nextx nexty
	return ::math::min [expr {($nextx-$x)/256.0}] [expr {($y-$nexty)/256.0}]
    }


    #  tile2geom --
    #
    #        
    #
    # Arguments:
    #        col    x tile coordinate,
    #        row    y tile coordinate,
    #        zl     zoom level,
    #        type   (optional, default 0):
    #                 0 - EXTENT   - extent "Xmin Ymin Xmax Ymax",
    #                 1 - Tcl LIST - tcl polygon and central point (first and last points are same)
    #                     {{Xcent Ycent} {x1 y1 x2 y2 x3 y3 x4 y4 x1 y1}},
    #                 2 - WKT LIST - Tcl list of WKT data (See [5]) - first element is central
    #                     point, second element is polygon (first and last poins are same),
    #                 3 - GEOJSON LIST  - GeoJSON data list (first  is central point, second is polygon).
    #                 4 - GeoJSON central point
    #                 5 - GeoJSON central polygon of tile
    #        epsg   (optional, default is false - omitted) -
    #               for 3,4 and 5 modes only
    #
    # Results:
    #        "x y" lat/long coordinates.
    #
        

    proc tile2geom {col row zl {type 0} {epsg 0}} {
	if {$epsg} {
	    set coortxt ", \"crs\":\{\"type\":\"name\",\"properties\":\{\"name\":\"EPSG:$epsg\"\}\} "
	} else {
	    set coortxt ""
	}
	lassign [tile2geo $col $row $zl] xmin ymax
	incr col
	incr row
	lassign [tile2geo $col $row $zl] xmax ymin
	set xcent [::n-kov::average "$xmin $xmax"]
	set ycent [::n-kov::average "$ymin $ymax"]	
	switch $type {
	    0 {
		return "$xmin $ymin $xmax $ymax"
	    }
	    1 {
		return [list [list $xcent $ycent] [list $xmin $ymin $xmax $ymin $xmax $ymax $xmin $ymax $xmin $ymin]]
	    }
	    2 {
		return [list "POINT ($xcent $ycent)" "POLYGON (($xmin $ymin, $xmax $ymin, $xmax $ymax, $xmin $ymax, $xmin $ymin))"]
	    }
	    3 {
		return [list "\{\"type\": \"Point\", \"coordinates\": \[$xcent, $ycent\]$coortxt\}" "\{\"type\": \"Polygon\", \"coordinates\": \[\[\[$xmin,$ymin\],\[$xmax,$ymin\],\[$xmax,$ymax\],\[$xmin,$ymax\],\[$xmin,$ymin\]\]\]$coortxt\}"]
	    }
	    4 {
		return "\{\"type\": \"Point\", \"coordinates\": \[$xcent, $ycent\]$coortxt\}"
	    }
	    5 {
		return "\{\"type\": \"Polygon\", \"coordinates\": \[\[\[$xmin,$ymin\],\[$xmax,$ymin\],\[$xmax,$ymax\],\[$xmin,$ymax\],\[$xmin,$ymin\]\]\]$coortxt\}"
	    }
	}
    }
    
    
    # isIn  --
    #
    #        Checks if any tile of one tile list is inside of
    #        any tileanother tiles list.
    #        Order of tile lists is not taken into account.
    #
    # Arguments:
    #        list_a     list of tile quadkeys,
    #        list_b     list of tile quadkeys,
    #        order      (optional,bool, default False) if order
    #                   in important. True
    #                   means that right need to be inside
    #                   or equal left.
    #                   
    #    
    # Results:
    #        0 - false, 1 - true. If a and b equal retuns true.
    #
    
    proc isIn {list_a list_b {order 0}} {
	foreach a $list_a {
	    foreach b $list_b {
		if {[string length $a]>[string length $b]} {
		    if {!$order} {
			set c $a
			set a $b
			set b $c
			unset c
		    }
		}
		if {$a eq [string range $b 0 [expr {[string length $a]-1}]]} {
		    return 1
		}
	    }
	}
	return 0
    }
    

    # isTouch  --
    #
    #        Checks if any tile of one tile list touches
    #        any tileanother tiles list.
    #
    # Arguments:
    #        list_a     list of tile quadkeys,
    #        list_b     list of tile quadkeys,
    #    
    # Results:
    #        0 - false, 1 - true. If a and b equal retuns true.
    #
      
    proc isTouch {list_a list_b} {
	foreach a $list_a {
	    foreach b $list_b {
		set valsx ""
		set valsy ""
		foreach {xf yf} [tile2geom {*}[quadkey2tile $a]] {
		    foreach {xs ys} [tile2geom {*}[quadkey2tile $b]] {
			foreach v {x y} {
			    lappend vals$v [expr {abs([subst $${v}f]-[subst $${v}s])}]
			}
		    }
		}
		if {[expr {[::math::min {*}$valsx]+[::math::min {*}$valsy]}]<${::n-kov::tilescf::epsilon}} {
		    return 1
		}
	    }
	}
	return 0
    }
  
    
    # polygonTileIntersect  --
    #
    #        cheks if a polygon and a tile are intersected
    #
    # Arguments:
    #        col row zl  - tile coordinates
    #        pol         - Tcl polygon (see [7]),
    #    
    # Results:
    #        boolean
    #

    proc polygonTileIntersect {col row zl {pol -1}} {
	set pts {}
	lassign [tile2geom $col $row $zl 1] cent rect
	set intersects 0
	foreach {x y} "$cent $rect" {
	    if {!$intersects && [::math::geometry::pointInsidePolygon "$x $y" $pol]} {
		set intersects 1
	    }
	}
	if {!$intersects} {
	    foreach {x y} $pol {
		if {!$intersects && [::math::geometry::pointInsidePolygon "$x $y" $rect]} {
		    set intersects 1
		}
	    }				
	    if {!$intersects && [::math::geometry::polylinesIntersect $rect $pol]} {
		set intersects 1
	    }
	}
	return $intersects
    }

    
    # getTilesOfPolygon  --
    #
    #        returns list of tiles of the intersecting a polygon.
    #
    # Arguments:
    #        pol     - Tcl polygon (see [7]),
    #        from_zl - from zoom level,
    #        to_zl   - (optional) if set, all tiles between defined
    #                  zoom levels will be returned. It has to be
    #                  bigger than from_zl.
    #    
    # Results:
    #        list of tiles
    #

    
    proc getTilesOfPolygon {pol from_zl {to_zl -1}} {
	upvar epsilon epsilon
	if {$to_zl eq -1} {
	    set to_zl $from_zl
	}
	set tiles ""
	for {} {$to_zl>=$from_zl} {incr to_zl -1} {
	    lassign [::math::geometry::bbox $pol] xmin ymin xmax ymax
	    lassign [geo2tile $xmin $ymax $to_zl] colmin rowmin
	    lassign [geo2tile $xmax $ymin $to_zl] colmax rowmax
	    for {set curcol $colmin} {$curcol<=$colmax} {incr curcol} {
		for {set currow $rowmin} {$currow<=$rowmax} {incr currow} {
		    if {[polygonTileIntersect $curcol $currow $to_zl $pol]} {
			lappend tiles [list $curcol $currow $to_zl]
		    }
		}
	    }
	    
	}
	return $tiles
    }

    
}

# For testing/debugging:
#
#  set qkey 12023022311 ;#--> https://t1.ssl.ak.dynamic.tiles.virtualearth.net/comp/ch/12023022311?mkt=en-US&it=G,BX,L,LA&shading=hill&og=88&n=z&c4w=1
# lassign "1095 732 11" col row zl
#  set pol "12.55146 45.65106 12.54358 45.62229 12.57965 45.60649 12.60872 45.62890 12.59541 45.65461"
if {0} {
    for {set z 2} {$z<3} {incr z} {
	for {set x 0} {$x < [expr pow(2,$z)]} {incr x} {
	    for {set y 0} {$y < [expr pow(2,$z)]} {incr y} {
		set q [::n-kov::tilescf::tile2quadkey $x $y $z]
		set xyz [::n-kov::tilescf::quadkey2tile $q]
		puts "XYZo:[string repeat " " $z]$x,$y,$z Q:$q XYZp:[join $xyz ,] XY:[::n-kov::tilescf::tile2geo {*}$xyz]"
	    }
	}
    }
}
