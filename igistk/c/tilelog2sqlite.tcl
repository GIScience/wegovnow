# The application converts OpenStreetMap tiles' access
# logs (http://planet.openstreetmap.org/tile_logs)
# from *.txt.xz to sqlite (spatialite) database.
#   
# Dependencies:
# xz command for file extraction has to be in the PATH

package require n-kov
package require fileutil
package require sqlite3
package require libtiles

set startTime [clock seconds]
set USAGE "
USAGE:
 tclsh tile-logs-to-sqlite.tcl [file join path to log dir] [file join path to new database.sqlite] \"tile1,tile2,...,tileN\"


   [file join path to log dir] - path to directory with *.txt.xz files. They could be downloaded by 
                      this way:  wget -N --no-parent -r http://planet.openstreetmap.org/tile_logs/

   [file join path to new database.sqlite] - path to output sqlite file. The file must not exist!

   \"tile1,tile2,...,tileN\" - tiles of interes. Only tile with zoom level greater than 
                               zoom level of specifyed tiles and insile bbox of specified 
                               tiles will be considered and saved into output database.
                               Tiles are descrided in format \"zoom_level/column/row\".

 Examples:
     tclsh tile-logs-to-sqlite.tcl [file join $env(HOME) projectsdata dq tile_logs] [file join [fileutil::tempdir] out.sqlite] \"10/547/365,10/511/340,10/536/349\" 
   San-Dona:
     tclsh tile-logs-to-sqlite.tcl [file join $env(HOME) projectsdata dq tile_logs] [file join [fileutil::tempdir] out.sqlite] \"12/2190/1462,12/2190/1463,12/2190/1464,12/2191/1462,12/2191/1463,12/2191/1464,12/2192/1462,12/2192/1463\"
     tclsh tile-logs-to-sqlite.tcl [file join $env(HOME) projectsdata dq tile_logs] [file join [fileutil::tempdir] out.sqlite] \"11/1095/731,11/1095/732,11/1096/731\"

     tilelog2sqlite.tcl tile_logs/planet.openstreetmap.org/tile_logs/ wgntilelog.sqlite 12/2190/1462,12/2190/1463,12/2190/1464,12/2191/1462,12/2191/1463,12/2191/1464,12/2192/1462,12/2192/1463,12/2134/1471,12/2134/1472,12/2134/1473,12/2135/1471,12/2135/1472,12/2135/1473,12/2136/1471,12/2136/1472,12/2046/1361,12/2046/1362,12/2046/1363,12/2047/1361,12/2047/1362,12/2047/1363,12/2145/1398,12/2145/1399,12/2145/1400,12/2145/1401,12/2146/1398,12/2146/1399,12/2146/1400,12/2146/1401,12/2147/1398,12/2147/1399,12/2147/1400,12/2147/1401,12/2148/1398,12/2148/1399,12/2148/1400,12/2148/1401

"

if 0 {
    # use ' source /path/to/tile-logs-to-sqlite.tcl ' for interactive mode
    # Samples of required variables for interactive mode
    # (the vars have to be set before calling the 'source' command:
    lassign "$env(HOME)/projectsdata/dq/tile_logs/planet.openstreetmap.org/tile_logs /tmp/sandonatilelog.sqlite 12/2190/1462,12/2190/1463,12/2190/1464,12/2191/1462,12/2191/1463,12/2191/1464,12/2192/1462,12/2192/1463" datdir resdb intiles
    #                                                            ^SanDona   ^London    ^Heidelberg
}

# Checking input arguments:
if {!$::tcl_interactive} {
    if {$::argc!=3} {
	error "[set ::n-kov::errorHeader] Bad argument number $USAGE"
    }
    lassign $argv datdir resdb intiles
} else {
    if {![info exist datdir] || ![info exist resdb] || ![info exist intiles]} {
	error "[set ::n-kov::errorHeader] All the following variables have to be specified: datdir resdb intiles $USAGE"
    }
    catch {file delete $resdb}
}

if {![file isdirectory $datdir] || [set fnum [llength [set files [glob -nocomplain [file join $datdir tiles-*.txt.xz]]]]] < 1} {
    error "[set ::n-kov::errorHeader] $datdir does not exist or does not contain tiles-*.txt.xz files $USAGE"
}

if {[file exist $resdb]} {
    error "[set ::n-kov::errorHeader] $resdb exists. Provide a path to non-existing file. $USAGE"
}




set tiles {}
foreach t [split $intiles ,] {
    lassign [split $t /] zl col row
    lappend tiles [::n-kov::tilescf::tile2quadkey $col $row $zl]
}



#Starting processing:
cd [fileutil::tempdir]
# foreach f [glob *.txt*] {file delete $f}
catch {sdb close}
catch {file delete $resdb}
sqlite3 sdb $resdb
sdb eval {
    CREATE TABLE hits (
			 z INTEGER NOT NULL,
			 x INTEGER NOT NULL,
			 y INTEGER NOT NULL,
			 q TEXT NOT NULL,
			 day TEXT NOT NULL,
			 hits INTEGER NOT NULL,
			 PRIMARY KEY (z,x,y,q,day) );
}


set i 0
set k 0
set sql "BEGIN;\n"
foreach xz $files {
    file copy $xz .
    incr i
    set fn [file tail $xz]
    exec xz -d $fn
    set fn [string map {.xz {}} $fn]
    lassign [lrange [split [lindex [split $fn .] 0] -] 1 end] year month day
    n-kov::fforeach line $fn {
	lassign [split [lindex $line 0] /] z col row
	set curquad [::n-kov::tilescf::tile2quadkey $col $row $z]
	if {[::n-kov::tilescf::isIn $tiles $curquad 1]} {
	    set n [lindex $line end]
	    lappend sql "INSERT INTO hits  VALUES ($z, $col, $row, '$curquad', '$year-$month-$day',$n);"
	    incr k; if {$k%1000==0} {	
		lappend sql "COMMIT;"
		sdb eval [join $sql \n]
		set sql "BEGIN;\n"
	    }
	}
    }
    file delete $fn
    puts "--> [format %.3f [expr {100*$i/double($fnum)}]]% -->"
}
if {[llength $sql]>1} {
    lappend sql "COMMIT;";
    sdb eval [join $sql \n];unset k
    
}


sdb close
set endTime [clock seconds]
puts "The successfully written database could be found in the following file: [file normalize $resdb]"
puts "Started: [clock format $startTime -format {%a %d-%m %H:%M:%S}]"
puts "Ended:   [clock format $endTime   -format {%a %d-%m %H:%M:%S}]\n"
#proc main {} {}


if 0 {

    set shape_polygons /home/fudeb/projectsdata/dq/psi/pilotsites.shp
    set polygons {}
    foreach line [split [exec ogrinfo -al $shape_polygons] \n] {
	if {[lsearch $line POLYGON]>-1} {
	    set pol [string trim $line]
	    lappend polygons [string map {, { }} [string range $pol [expr {1+[string last "(" $pol]}] [expr {[string last ")" $pol]-2}]]]
	}
    }
    set tiles {}
    foreach pol $polygons {
	foreach t [::n-kov::tilescf::getTilesOfPolygon  $pol 12] {
	    lassign $t a b c
	    lappend tiles $c/$a/$b
	}
    }
    foreach t $tiles {
	lassign [split $t /] zl x y
	puts ([lindex [::n-kov::tilescf::tile2geom $x $y $zl 1] 0]),
    }
    join $tiles ,
}


