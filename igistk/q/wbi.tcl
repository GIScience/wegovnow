package require json
package require n-kov
package require libtiles
package require sqlite3
package require Thread
set USAGE "
USAGE:
 tclsh [info script] /path/to/database.sqlite 

   
   /path/to/database.sqlite  - paths to spatial data
                               separated by comma \",\" - each one will be
                               evaluated by the \"glob\" command,

   /path/to/tilelog.sqtiles  - path to tilelog database prepared
                               by tilelog2sqlite.tcl

 
 Example:
   tclsh [info script] $::env(HOME)/projectsdata/dq/wgn.sqlite

"
if {$argc != 2 || ![file exists [lindex $argv 0]] || ![file exists [lindex $argv 1]]} {
    error "${::n-kov::errorHeader} Wrong number of arguments or the provided argiment is not a file path. $USAGE"
}
set sdbpath [lindex $argv 0]
set tilelog [lindex $argv 1]

if 0 {lassign "../data/sandonadata.sqlite ../data/sandonatilelog.sqlite" sdbpath tilelog}

set sdbpath [file normalize $sdbpath]
set tilelog [file normalize $tilelog]


#
#      INITIALIZATION OF A DATABASE
#



sqlite3 sdb $sdbpath
sdb enable_load_extension true
sdb eval "SELECT load_extension('mod_spatialite.so');"
sdb eval "SELECT load_extension('libsqlitefunctions.so');"


foreach f [info commands ::n-kov::tilescf::*] {
    set fname [string range $f [expr {[string last : $f]+1}] end]
    sdb function $fname $f
    lappend funcs $fname
}



catch {sdb eval "DROP TABLE wbisrc"}
set initsql "CREATE TABLE wbisrc (\ncol INTEGER NOT NULL,\nrow INTEGER NOT NULL,\nzl INTEGER NOT NULL,\nq TEXT NOT NULL"




set names ""
set bnames ""
set agrnames ""


set wbi_names [dict create D {Ge {Npt {} Lin {Numb {} Leng {}} Are {Numb {} Ling {} Area {}}} At {}} M {Uh {} Co {Nco {} Ncs {}} Tl {Ave {} Ati {}}}]
proc recurnames {d k agr} {
    global names bnames agrnames
    set curdict [dict get $d $k]
    if {[lsearch $names "$agr$k"] < 0} {
	lappend names "$agr$k"
    }
    if {$curdict ne {}} {
	foreach cur [dict keys $curdict] {
	    if {[lsearch $agrnames "$agr$k"] < 0} {
		lappend agrnames "$agr$k"
	    }
	    recurnames $curdict $cur "$agr$k"
	}
    } else {
	if {[lsearch $bnames "$agr$k"] < 0} {
	    lappend bnames "$agr$k"
	}
	return
    }    
}

foreach key [dict keys $wbi_names] {
    recurnames $wbi_names $key ""
}

foreach n $bnames {
    append initsql ",\n $n INTEGER"
}
append initsql ",\n PRIMARY KEY (col,row,zl,q));"
sdb eval $initsql


#
#      INITIALIZATION OF A PILOTSITES' POLYGONS
#



# set shape_polygons $::env(HOME)/projectsdata/dq/psi/pilotsites.shp
# set polygons ""
# foreach line [split [exec ogrinfo -al $shape_polygons] \n] {
#     if {[lsearch $line POLYGON]>-1} {
# 	lappend polygons [string trim $line]
#     }
# }


#
#      MAIN
#


sdb eval "ATTACH '$tilelog' AS tls"


# #lassign {15 17523 11705 19 280373 187287} zl1 col1 row1 zl2 col2 row2
# proc tileContains {zl1 col1 row1 zl2 col2 row2} {
#     lassign [::map::slippy tile 2geo [list $zl1 $row1 $col1]] _ y1l x1l
#     lassign [::map::slippy tile 2geo [list $zl1 [expr $row1+1] [expr {$col1+1}]]] _ y1r x1r
#     lassign [::map::slippy tile 2geo [list $zl2 $row2 $col2]] _ y2l x2l
#     lassign [::map::slippy tile 2geo [list $zl2 [expr $row2+1] [expr {$col2+1}]]] _ y2r x2r
#     set x2 [::n-kov::average "$x2l $x2r"]
#     set y2 [::n-kov::average "$y2l $y2r"]
#     if {$x2>$x1l && $x2<$x1r && $y2<$y1l && $y2>$y1r} {
# 	return 1
#     } else {
# 	return 0
#     }    
# }


sdb function isIn ::n-kov::tilescf::isIn


set poltcl {12.576143863342834 45.699032569420567 12.599089743024305 45.684566688751815 12.599089743024305 45.684566688751815 12.595930527705841 45.675754140758208 12.601251311400095 45.666609043783708 12.604576801209005 45.663616102955686 12.613223074712167 45.668936886649945 12.623365818629338 45.676585513210433 12.62768895538092 45.675089042796422 12.626857582928693 45.669435710121277 12.628354053342703 45.660456887637224 12.638330522769429 45.660124338656331 12.644648953406355 45.663117279484354 12.658283461622881 45.652808261076736 12.663105421845799 45.642000419197778 12.660278755508227 45.637843556936645 12.647974443215265 45.632522773242393 12.621370524743993 45.635848263051301 12.622866995158002 45.628698459962145 12.636002679903193 45.618555716044973 12.630681896208939 45.609244344580027 12.642819934011456 45.60259336496221 12.636168954393638 45.590954150631028 12.620206603310876 45.578151014866734 12.61422072165484 45.574326701586486 12.602248958342768 45.575656897510051 12.594267782801387 45.576488269962276 12.58977837155936 45.578816112828513 12.585787783788669 45.580146308752077 12.581630921527532 45.577652191395394 12.576808961304614 45.577153367924055 12.574148569457488 45.58047885773297 12.564005825540315 45.578816112828513 12.564670923502097 45.573827878115146 12.568994060253679 45.567509447478223 12.577474059266397 45.56235493827441 12.581797196017979 45.55803180152283 12.576143863342834 45.552877292319025 12.562343080635861 45.566511800535551 12.55835249286517 45.572830231172475 12.551867787737798 45.574825525057825 12.549207395890672 45.58047885773297 12.548376023438443 45.584136896522764 12.558685041846061 45.589125131236131 12.567663864330116 45.596607483306173 12.570157981686798 45.605420031299786 12.571321903119916 45.614232579293393 12.570989354139025 45.621382382382549 12.56201053165497 45.624541597701011 12.556689747960716 45.628532185471698 12.548043474457554 45.630693753847488 12.530917201941673 45.632522773242393 12.526760339680537 45.634850616108629 12.5226034774194 45.647487477382484 12.520109360062719 45.649316496777381 12.528921908056327 45.652974535567182 12.532081123374791 45.650147869229606 12.536071711145482 45.650812967191392 12.537900730540381 45.653307084548068 12.55402935611359 45.663782377446132 12.56201053165497 45.662452181522568 12.560846610221853 45.672761199930186 12.565834844935216 45.677749434643552 12.570823079648578 45.687393355089384 12.570157981686798 45.69454315817854 12.576143863342834 45.699032569420567}
set pol "POLYGON (("
set coors {}
foreach {x y} $poltcl {
    lappend coors "$x $y"
}
append pol [join $coors ,]
append pol "))"
		      
    

set zl 19
set maxnum 0
set curnum 0
set bounds {}
#foreach {pol} $polygons {}
#set pol [lindex $polygons 0]


lassign [sdb eval "SELECT MbrMinX(t.g),MbrMaxY(t.g),MbrMaxX(t.g),MbrMinY(t.g) FROM (SELECT Extent(GeomFromText('$pol')) as g) as t"] x1 y1 x2 y2
lassign [::n-kov::tilescf::geo2tile $x1 $y1 $zl] tx1 ty1
lassign [::n-kov::tilescf::geo2tile $x2 $y2 $zl] tx2 ty2

for {set i $tx1} {$i <= $tx2} {incr i} {
    for {set j $ty1} {$j <= $ty2} {incr j} {
	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,]));"]} {
	    incr maxnum
	}
    }
}
lappend bounds $maxnum



set curnum 0
set sql1 "BEGIN;\n"
#foreach {pol} $polygons {}
#set pol [lindex $polygons 0]
#if {1} {}

lassign [sdb eval "SELECT MbrMinX(t.g),MbrMaxY(t.g),MbrMaxX(t.g),MbrMinY(t.g) FROM (SELECT Extent(GeomFromText('$pol')) as g) as t"] x1 y1 x2 y2
lassign [::n-kov::tilescf::geo2tile $x1 $y1 $zl] tx1 ty1
lassign [::n-kov::tilescf::geo2tile $x2 $y2 $zl] tx2 ty2

for {set i $tx1} {$i <= $tx2} {incr i} {
    for {set j $ty1} {$j <= $ty2} {incr j} {
	if {[file exists /tmp/break]} gagaga		
	#debug (a tile with pnt-ln-pgn: lassign [::map::slippy geo 2tile {19 45.63365 12.56405}] _ j i
	set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,])"
	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),$mbr);"]} {
	    set intsec "Intersection(geom,$mbr)"
	    set intsebo "Intersection(Boundary(geom),$mbr)"
	    set quadkey [::n-kov::tilescf::tile2quadkey $i $j $zl]
	    lappend sql1 "INSERT INTO wbisrc VALUES ($i,$j,$zl,'$quadkey',( SELECT Ifnull(SUM(NumGeometries(geom)),0) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND GeometryType(geom) LIKE '%POINT%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr)  AND IsValid(geom) ),( SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) FROM elements as e JOIN tags as t ON t.id=e.id WHERE datasrc LIKE 'SanDona.OSM' AND Intersects(geom,$mbr) GROUP BY t.key,t.val) ),( SELECT sum(h.hits) FROM tls.hits as h  WHERE isIn(h.q,$quadkey) ),( SELECT COUNT(DISTINCT uid) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND Intersects(geom,$mbr) ),( SELECT COUNT(DISTINCT changeset) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND Intersects(geom,$mbr) ),( SELECT Ifnull(CastToInteger(Round(AVG(version))),0) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND Intersects(geom,$mbr) ),( SELECT Ifnull(CastToInteger(Round(AVG(timestamp))),0) FROM elements  WHERE  datasrc LIKE 'SanDona.OSM' AND Intersects(geom,$mbr)));"
	    incr curnum
	    if {$curnum%100 == 0} {
		lappend sql1 "COMMIT;"
		sdb eval [join $sql1 \n];set _ {}
		set sql1 "BEGIN;\n"
		puts  -nonewline stderr "\r[format %.5f [expr {100*(double($curnum)/double($maxnum))}]]%"
		flush stderr
	    }
	}
    }
}
lappend sql1 "COMMIT;"
sdb eval [join $sql1 \n];set _ {}
sdb eval {DETACH tls;}
sdb eval {ALTER TABLE wbisrc ADD COLUMN wbi INTEGER;}



set selects {}
foreach n $bnames {
    set min [sdb eval "select min($n) from wbisrc"]
    set range [sdb eval "select (max($n)-min($n))/10.0 from wbisrc"]
    lappend selects "($n-$min)/(1.0*$range)"
}
set min [sdb eval "SELECT min(([join $selects +])/[llength $bnames].0) from wbisrc"]
set max [sdb eval "SELECT max(([join $selects +])/[llength $bnames].0) from wbisrc"]
set range [expr {($max-$min)/10.0}]
set sql "UPDATE wbisrc SET wbi=CAST(ROUND(   ((([join $selects +])/[llength $bnames])-$min)/($range*1.0)   ) AS INTEGER)"
sdb eval $sql




set sql "[string range $sql 0 end-1]) SELECT wbisrc.q, tmp[join $bnames {.cls, tmp}].cls from wbisrc $joins"
sdb eval $sql



if 0 {
    set colnams {col row zl q DGeNpt DGeLinNumb DGeLinLeng DGeAreNumb DGeLinLeng DGeAreArea DAt MUh MCoNco MCoNcs MTlAve MTlAti}
    set f [open /tmp/out.csv w]
    puts $f "x y [lrange $colnams 4 end]"
    foreach $colnams [sdb eval "select [join $colnams ,] from wbisrc"] {puts $f "[::n-kov::tilescf::tile2geo $col $row $zl] $DGeNpt $DGeLinNumb $DGeLinLeng $DGeAreNumb $DGeLinLeng $DGeAreArea $DAt $MUh $MCoNco $MCoNcs $MTlAve $MTlAti"}
    close $f
}


#Fixme
#sdb eval {UPDATE btiles SET MUh = 0 WHERE Muh is NULL}

set f1 [open /tmp/sandona_mockwbi.json w]
puts $f1 "{ \"type\": \"FeatureCollection\", \"crs\": \{\"type\":\"name\",\"properties\":\{\"name\":\"EPSG:4326\"\}\},
\"features\": \["
foreach "col row zl q $bnames wbi" [sdb eval {SELECT * FROM wbisrc}] {
    #lassign [string range [sdb eval "SELECT AsText(Transform(GeomFromText('POINT ([::n-kov::tilescf::tile2geo $col $row $zl])',4326),3857))"] 7 end-2] x y
    puts -nonewline  $f1 "{ \"type\": \"Feature\",\"geometry\": {\"type\": \"Point\", \"coordinates\": \[[join [::n-kov::tilescf::tile2geo $col $row $zl] ,]\]}, \"properties\": {"
    set props {}
    foreach n "q wbi $bnames" {
	append props "\"$n\": [subst $$n] ,"
    }
    puts  $f1 "[string range $props 0 end-1]}},"    
}
puts $f1 "\]}"
close $f1


sdb eval {CREATE TABLE tiles (q TEXT, col INTEGER, row INTEGER);}
sdb eval {SELECT AddGeometryColumn('tiles', 'geomcent', 4326, 'POINT', 'XY');}
sdb eval {SELECT AddGeometryColumn('tiles', 'geompol', 4326, 'POLYGON', 'XY');}
sdb eval {INSERT INTO tiles SELECT q,col,row,GeomFromGeoJSON(tile2geom(col,row,19,4,4326)),GeomFromGeoJSON(tile2geom(col,row,19,5,4326)) FROM wbisrc}



sdb eval {CREATE TABLE wbidata (tile INTEGER, name TEXT, DGeNpt INTEGER, DGeLinNumb INTEGER, DGeLinLeng INTEGER, DGeAreNumb INTEGER, DGeAreLing INTEGER, DGeAreArea INTEGER, DAt INTEGER, MUh INTEGER, MCoNco INTEGER, MCoNcs INTEGER, MTlAve INTEGER, MTlAti INTEGER, wbi INTEGER, FOREIGN KEY (tile) REFERENCES tiles(rowid));}
sdb eval {INSERT INTO wbidata SELECT tiles.rowid,'SanDona.OSM.Current',DGeNpt,DGeLinNumb,DGeLinLeng,DGeAreNumb,DGeAreLing,DGeAreArea,DAt,MUh,MCoNco,MCoNcs,MTlAve,MTlAti,wbi FROM wbisrc JOIN tiles ON wbisrc.q=tiles.q}


sdb eval {CREATE TABLE eltile (element INTEGER, tile INTEGER, FOREIGN KEY (element) REFERENCES elements(id), FOREIGN KEY (tile) REFERENCES tiles(rowid));}
# Warning! Slow! 1090365822
sdb eval {INSERT INTO eltile SELECT elements.id,tiles.rowid FROM elements JOIN tiles ON MbrIntersects(elements.geom,tiles.geompol) AND Intersects(elements.geom,tiles.geompol);}













set slist {}
foreach n $bnames {
    foreach func "min max" {
	lappend slist "'sd_${n}_$func': [sdb eval [list select ${func}($n) from wbisrc]]"
    }
}
puts "\{[join $slist ,]\}"


#sdb eval {INSERT INTO wbidata (name,zl,x,y) SELECT 'SanDona.OSM',zl,x,y FROM btiles}

foreach n $bnames {
    set maxval [sdb eval "SELECT max((SELECT count(t2.val2)-1 FROM (SELECT $n AS val2 FROM wbisrc GROUP BY $n) AS t2 WHERE t2.val2<=t1.val1)) FROM (SELECT $n as val1 FROM wbisrc GROUP BY $n) AS t1"]
    sdb eval "CREATE TABLE tmp$n (cls INTEGER, cval INTEGER, PRIMARY KEY (cls,cval));"
    sdb eval "INSERT INTO tmp$n SELECT CastToInteger(Round(100.0*((SELECT count(t2.val2)-1 FROM (SELECT $n AS val2 FROM wbisrc GROUP BY $n) AS t2 WHERE t2.val2<=t1.val1))/$maxval)) as cls,t1.val1 as cval FROM (SELECT $n as val1 FROM wbisrc GROUP BY $n) AS t1"
}


catch {sdb eval "DROP TABLE tmpwbi"}
set sql "CREATE TABLE tmpwbi (\nq TEXT"
foreach n $bnames {
    append sql ",\n $n INTEGER"
}
append sql ",\n PRIMARY KEY (q));"
sdb eval $sql


set sql "INSERT INTO tmpwbi (q,"
set joins {}
foreach n $bnames {
    append sql "$n,"
    append joins "JOIN tmp$n ON wbisrc.$n=tmp$n.cval "
}
set sql "[string range $sql 0 end-1]) SELECT wbisrc.q, tmp[join $bnames {.cls, tmp}].cls from wbisrc $joins"
sdb eval $sql





set sql "INSERT INTO tmpwbi (q,"
set joins {}







catch {sdb eval "DROP TABLE wbibase"}
set sql "CREATE TABLE wbibase (\nname TEXT, zl INTEGER,\nx INTEGER,\ny INTEGER"
foreach n $bnames {
    append sql ",\n $n INTEGER"
}
append sql ",\n PRIMARY KEY (name,zl,x,y));"
sdb eval $sql
set sql "INSERT INTO wbibase (name,zl,x,y,"
set joins {}
foreach n $bnames {
    append sql "$n,"
    append joins "JOIN tmp$n ON btiles.$n=tmp$n.cval "
}
set sql "[string range $sql 0 end-1]) SELECT 'SanDona.OSM',btiles.zl, btiles.x, btiles.y, tmp[join $bnames {.cls, tmp}].cls from btiles $joins"
sdb eval $sql
    










































# PSI processing
set names ""
set bnames ""
set agrnames ""
set wbi_names [dict create D {Ge {Npt {} Lin {Numb {} Leng {}} Are {Numb {} Ling {} Area {}}} At {}}]
proc recurnames {d k agr} {
    global names bnames agrnames
    set curdict [dict get $d $k]
    if {[lsearch $names "$agr$k"] < 0} {
	lappend names "$agr$k"
    }
    if {$curdict ne {}} {
	foreach cur [dict keys $curdict] {
	    if {[lsearch $agrnames "$agr$k"] < 0} {
		lappend agrnames "$agr$k"
	    }
	    recurnames $curdict $cur "$agr$k"
	}
    } else {
	if {[lsearch $bnames "$agr$k"] < 0} {
	    lappend bnames "$agr$k"
	}
	return
    }    
}

foreach key [dict keys $wbi_names] {
    recurnames $wbi_names $key ""
}
sdb function isIn ::n-kov::tilescf::isIn
set poltcl {12.576143863342834 45.699032569420567 12.599089743024305 45.684566688751815 12.599089743024305 45.684566688751815 12.595930527705841 45.675754140758208 12.601251311400095 45.666609043783708 12.604576801209005 45.663616102955686 12.613223074712167 45.668936886649945 12.623365818629338 45.676585513210433 12.62768895538092 45.675089042796422 12.626857582928693 45.669435710121277 12.628354053342703 45.660456887637224 12.638330522769429 45.660124338656331 12.644648953406355 45.663117279484354 12.658283461622881 45.652808261076736 12.663105421845799 45.642000419197778 12.660278755508227 45.637843556936645 12.647974443215265 45.632522773242393 12.621370524743993 45.635848263051301 12.622866995158002 45.628698459962145 12.636002679903193 45.618555716044973 12.630681896208939 45.609244344580027 12.642819934011456 45.60259336496221 12.636168954393638 45.590954150631028 12.620206603310876 45.578151014866734 12.61422072165484 45.574326701586486 12.602248958342768 45.575656897510051 12.594267782801387 45.576488269962276 12.58977837155936 45.578816112828513 12.585787783788669 45.580146308752077 12.581630921527532 45.577652191395394 12.576808961304614 45.577153367924055 12.574148569457488 45.58047885773297 12.564005825540315 45.578816112828513 12.564670923502097 45.573827878115146 12.568994060253679 45.567509447478223 12.577474059266397 45.56235493827441 12.581797196017979 45.55803180152283 12.576143863342834 45.552877292319025 12.562343080635861 45.566511800535551 12.55835249286517 45.572830231172475 12.551867787737798 45.574825525057825 12.549207395890672 45.58047885773297 12.548376023438443 45.584136896522764 12.558685041846061 45.589125131236131 12.567663864330116 45.596607483306173 12.570157981686798 45.605420031299786 12.571321903119916 45.614232579293393 12.570989354139025 45.621382382382549 12.56201053165497 45.624541597701011 12.556689747960716 45.628532185471698 12.548043474457554 45.630693753847488 12.530917201941673 45.632522773242393 12.526760339680537 45.634850616108629 12.5226034774194 45.647487477382484 12.520109360062719 45.649316496777381 12.528921908056327 45.652974535567182 12.532081123374791 45.650147869229606 12.536071711145482 45.650812967191392 12.537900730540381 45.653307084548068 12.55402935611359 45.663782377446132 12.56201053165497 45.662452181522568 12.560846610221853 45.672761199930186 12.565834844935216 45.677749434643552 12.570823079648578 45.687393355089384 12.570157981686798 45.69454315817854 12.576143863342834 45.699032569420567}
set pol "POLYGON (("
set coors {}
foreach {x y} $poltcl {
    lappend coors "$x $y"
}
append pol [join $coors ,]
append pol "))"
		      
    

set zl 19
set maxnum 0
set curnum 0
set bounds {}
#foreach {pol} $polygons {}
#set pol [lindex $polygons 0]


lassign [sdb eval "SELECT MbrMinX(t.g),MbrMaxY(t.g),MbrMaxX(t.g),MbrMinY(t.g) FROM (SELECT Extent(GeomFromText('$pol')) as g) as t"] x1 y1 x2 y2
lassign [::n-kov::tilescf::geo2tile $x1 $y1 $zl] tx1 ty1
lassign [::n-kov::tilescf::geo2tile $x2 $y2 $zl] tx2 ty2

for {set i $tx1} {$i <= $tx2} {incr i} {
    for {set j $ty1} {$j <= $ty2} {incr j} {
	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,]));"]} {
	    incr maxnum
	}
    }
}
lappend bounds $maxnum



set curnum 0
set sql1 "BEGIN;\n"
#foreach {pol} $polygons {}
#set pol [lindex $polygons 0]
#if {1} {}

lassign [sdb eval "SELECT MbrMinX(t.g),MbrMaxY(t.g),MbrMaxX(t.g),MbrMinY(t.g) FROM (SELECT Extent(GeomFromText('$pol')) as g) as t"] x1 y1 x2 y2
lassign [::n-kov::tilescf::geo2tile $x1 $y1 $zl] tx1 ty1
lassign [::n-kov::tilescf::geo2tile $x2 $y2 $zl] tx2 ty2




set wheresql ""
foreach k {amenity cycleway bicycle tourism leisure office historic shop wholesale} {
    lappend wheresql "keys.txt LIKE '%$k%'"	
}
foreach v {bicycle hotel retail kiosk bakehouse cathedral chapel church kindergarten  mosque temple synagogue shrine civic hospital school stadium train_station transportation university stands public parking} {
    lappend wheresql "vals.txt LIKE '%$v%'"	
}


set f1 [open /tmp/minwbipols.json w]
puts $f1 "{ \"type\": \"FeatureCollection\", \"features\": \["
set features {}
set i 0
foreach id {SD TR HD SW} minwbi {4 4 2 2} {
    incr i
    set g [sdb eval "SELECT AsGeoJSON(GUnion(geompol)) FROM wbidata JOIN tiles ON wbidata.tile=tiles.rowid WHERE name='OSM.CUR.$id' AND wbi>=$minwbi"]
    lappend features "{\"type\": \"Feature\",\"id\":\"$i\",\"geometry\": [string range $g 1 end-1], \"properties\": {\"num\":\"$id\"}}"
}
puts -nonewline  $f1 [join $features ,] 
puts $f1 "\]}"
close $f1
unset features






set curnum 0
set sql1 "BEGIN;\n"
set sq "FROM elements AS e JOIN tags AS t ON e.id=t.id JOIN keys ON t.key=keys.rowid JOIN vals ON t.val=vals.rowid WHERE e.datasrc = 'SanDona.OSM'"
for {set i $tx1} {$i <= $tx2} {incr i} {
    for {set j $ty1} {$j <= $ty2} {incr j} {
	if {[file exists /tmp/break]} gagaga		
	#debug (a tile with pnt-ln-pgn: lassign [::map::slippy geo 2tile {19 45.63365 12.56405}] _ j i
	set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,])"
	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),$mbr);"]} {
	    set intsec "Intersection(geom,$mbr)"
	    set intsebo "Intersection(Boundary(geom),$mbr)"
	    set quadkey [::n-kov::tilescf::tile2quadkey $i $j $zl]
	    lappend sql1 "INSERT INTO wbidata VALUES ((SELECT tiles.rowid FROM tiles WHERE col=$i AND row=$j),'SanDona.OSM.PSI',( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POINT%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr)  AND IsValid(geom) ),( SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) $sq AND Intersects(geom,$mbr) GROUP BY t.key,t.val) ),-1,-1,-1,-1,-1,-1);"
	    incr curnum
	    if {$curnum%100 == 0} {
		lappend sql1 "COMMIT;"
		sdb eval [join $sql1 \n];set _ {}
		set sql1 "BEGIN;\n"
		puts  -nonewline stderr "\r[format %.5f [expr {100*(double($curnum)/double($maxnum))}]]%"
		flush stderr
	    }
	}
    }
}
lappend sql1 "COMMIT;";set _ {}
sdb eval [join $sql1 \n];set _ {}




set curnum 0
set sql1 "BEGIN;\n"
set sq "FROM elements AS e JOIN tags AS t ON e.id=t.id JOIN keys ON t.key=keys.rowid JOIN vals ON t.val=vals.rowid WHERE e.datasrc LIKE '%.ONM'"
for {set i $tx1} {$i <= $tx2} {incr i} {
    for {set j $ty1} {$j <= $ty2} {incr j} {
	if {[file exists /tmp/break]} gagaga		
	#debug (a tile with pnt-ln-pgn: lassign [::map::slippy geo 2tile {19 45.63365 12.56405}] _ j i
	set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,])"
	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),$mbr);"]} {
	    set intsec "Intersection(geom,$mbr)"
	    set intsebo "Intersection(Boundary(geom),$mbr)"
	    set quadkey [::n-kov::tilescf::tile2quadkey $i $j $zl]
	    lappend sql1 "INSERT INTO wbidata VALUES ((SELECT tiles.rowid FROM tiles WHERE col=$i AND row=$j),'SanDona.ONM.PSI',( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POINT%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr)  AND IsValid(geom) ),( SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) $sq AND Intersects(geom,$mbr) GROUP BY t.key,t.val) ),-1,-1,-1,-1,-1,-1);"
	    incr curnum
	    if {$curnum%100 == 0} {
		lappend sql1 "COMMIT;"
		sdb eval [join $sql1 \n];set _ {}
		set sql1 "BEGIN;\n"
		puts  -nonewline stderr "\r[format %.5f [expr {100*(double($curnum)/double($maxnum))}]]%"
		flush stderr
	    }
	}
    }
}
lappend sql1 "COMMIT;";set _ {}
sdb eval [join $sql1 \n];set _ {}




set curnum 0
set sql1 "BEGIN;\n"
set sq "FROM elements AS e JOIN tags AS t ON e.id=t.id JOIN keys ON t.key=keys.rowid JOIN vals ON t.val=vals.rowid WHERE e.datasrc LIKE '%.Municipality'"
for {set i $tx1} {$i <= $tx2} {incr i} {
    for {set j $ty1} {$j <= $ty2} {incr j} {
	if {[file exists /tmp/break]} gagaga
	set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,])"
	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),$mbr);"]} {
	    set intsec "Intersection(geom,$mbr)"
	    set intsebo "Intersection(Boundary(geom),$mbr)"
	    set quadkey [::n-kov::tilescf::tile2quadkey $i $j $zl]
	    lappend sql1 "INSERT INTO wbidata VALUES ((SELECT tiles.rowid FROM tiles WHERE col=$i AND row=$j),'SanDona.OD.PSI',( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POINT%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr)  AND IsValid(geom) ),( SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) $sq AND Intersects(geom,$mbr) GROUP BY t.key,t.val) ),-1,-1,-1,-1,-1,-1);"
	    incr curnum
	    if {$curnum%100 == 0} {
		lappend sql1 "COMMIT;"
		sdb eval [join $sql1 \n];set _ {}
		set sql1 "BEGIN;\n"
		puts  -nonewline stderr "\r[format %.5f [expr {100*(double($curnum)/double($maxnum))}]]%"
		flush stderr
	    }
	}
    }
}
lappend sql1 "COMMIT;";set _ {}
sdb eval [join $sql1 \n];set _ {}

















sdb eval {INSERT INTO wbidata VALUES ()}

#set v DGeLinLeng
# list SELECT f.tile,CASE WHEN f.$v>s.$v THEN f.$v ELSE -1*s.$v END AS first, CASE WHEN f.$v>s.$v THEN CastToInteger(100*(1-s.$v/f.$v)) ELSE CastToInteger(100*(f.$v/(s.$v+0.01))) END AS secont,f.$v,s.$v FROM wbidata as f JOIN wbidata as s ON f.tile=s.tile WHERE f.name='SanDona.OSM.PSI' AND s.name='SanDona.ONM.PSI'

# puts api.tcl?SELECT=f.tile__c__&CASE&WHEN=f.${v}&__g__=s.${v}&THEN=f.${v}&ELSE=__r__1__m__s.${v}&END&AS=first__c__&CASE&WHEN=f.${v}&__g__=s.${v}&THEN=__CastToInteger,100__m__&___=1__r__s.${v}&__d__=f.${v},___,___&ELSE=__CastToInteger,100__m__&___=f.${v}&__d__&___=s.${v}&__a__=0.01,___,___,___&END&AS=second&FROM=wbidata&AS=f&JOIN=wbidata&AS=s&ON=f.tile&__e__=s.tile&WHERE=f.name&__e__=__q__SanDona.OSM.PSI__q__&AND=s.name&__e__=__q__SanDona.ONM.PSI__q__





set curnames [lsearch -inline -all -glob -not $bnames "M*"]
set selects {}
foreach n $curnames {
    set min [sdb eval "SELECT min($n) FROM wbidata WHERE name LIKE '%.PSI'"]
    set range [sdb eval "SELECT (max($n)-min($n))/10.0 FROM wbidata WHERE name LIKE '%.PSI'"]
    lappend selects "($n-$min)/(1.0*$range)"
}
set min [sdb eval "SELECT min(([join $selects +])/[llength $curnames].0) FROM wbidata"]
set max [sdb eval "SELECT max(([join $selects +])/[llength $curnames].0) FROM wbidata"]
set range [expr {($max-$min)/10.0}]
set sql "UPDATE wbidata SET wbi=CAST(ROUND(   ((([join $selects +])/[llength $curnames])-$min)/($range*1.0)   ) AS INTEGER) WHERE name LIKE '%.PSI'"
sdb eval $sql




























 
package require Thread

set initdb {    
    package require libtiles    
    package require n-kov    
    package require sqlite3
    
    set tid [thread::id]
    sqlite3 db$tid :memory:
    db$tid enable_load_extension true
    db$tid eval "SELECT load_extension('mod_spatialite.so');"
    db$tid eval "SELECT load_extension('libsqlitefunctions.so');"
    foreach f [info commands ::n-kov::tilescf::*] {
	set fname [string range $f [expr {[string last : $f]+1}] end]
	db$tid function $fname $f
	lappend funcs $fname
    }
    db$tid eval {BEGIN;SELECT InitSpatialMetaData();COMMIT}
    db$tid eval {
	CREATE TABLE keys (
			   txt TEXT,
			   UNIQUE (txt) ON CONFLICT IGNORE);

	CREATE TABLE vals (
			     txt TEXT,
			     UNIQUE (txt) ON CONFLICT IGNORE);

	CREATE TABLE elements (
			id INTEGER PRIMARY KEY,
			dataid TEXT,
			version INTEGER,
			type INTEGER,
			uid INTEGER,
			timestamp INTEGER,
			changeset INTEGER,
			datasrc TEXT);

	CREATE TABLE tags (
			id INTEGER,
			key INTEGER,
			val INTEGER,
			PRIMARY KEY (id, key, val) ON CONFLICT IGNORE,
			FOREIGN KEY (id) REFERENCES elements(id),
			FOREIGN KEY (key) REFERENCES keys(rowid),
			FOREIGN KEY (val) REFERENCES vals(rowid));
	SELECT AddGeometryColumn('elements', 'geom', 4326, 'GEOMETRY', 'XY');
    }
    db$tid eval "ATTACH '[tsv::get sdata sdbpath]' AS qd"    
}

set getdata {
    #set qtile 0313131311122133113
    #tsv::set sdata status_$t on
    set tid [thread::id]
    set qtile [tsv::get sdata tile_$tid]
    set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom [::n-kov::tilescf::quadkey2tile $qtile]] ,])"
    set intsec "Intersection(geom,$mbr)"
    set intsebo "Intersection(Boundary(geom),$mbr)"


    set inclsql ""
    foreach k {amenity cycleway bicycle tourism leisure office historic shop wholesale} {
	lappend inclsql "keys.txt LIKE '%$k%'"	
    }
    foreach v {bicycle hotel retail kiosk bakehouse cathedral chapel church kindergarten  mosque temple synagogue shrine civic hospital school stadium train_station transportation university stands public parking} {
	lappend inclsql "vals.txt LIKE '%$v%'"	
    }

    
    set ids0 [db$tid eval "SELECT DISTINCT e.id FROM qd.elements AS e WHERE Intersects(e.geom,$mbr)"]
    set ids [db$tid eval "SELECT DISTINCT e.id FROM qd.elements AS e JOIN qd.tags AS t ON e.id=t.id JOIN qd.keys ON t.key=keys.rowid JOIN qd.vals ON t.val=vals.rowid  WHERE e.id IN ([join $ids0 ,]) AND ((e.datasrc NOT LIKE 'OSM.CUR.%' AND keys.txt = 'lname' AND lower(vals.txt) NOT LIKE '%high%') OR (e.datasrc LIKE 'OSM.CUR.%' AND ([join $inclsql { OR }])))"]  
    set sqselect "FROM qd.elements AS e JOIN qd.tags AS t ON e.id=t.id JOIN qd.keys ON t.key=keys.rowid JOIN qd.vals ON t.val=vals.rowid WHERE e.id IN ([join $ids ,])"

    db$tid eval "INSERT INTO elements (id,dataid,version,type,uid,timestamp,changeset,datasrc,geom) SELECT DISTINCT e.id,e.dataid,e.version,e.type,e.uid,e.timestamp,e.changeset,e.datasrc,e.geom $sqselect"
    db$tid eval "INSERT INTO keys (rowid,txt) SELECT DISTINCT qd.keys.rowid,qd.keys.txt $sqselect"
    db$tid eval "INSERT INTO vals (rowid,txt) SELECT DISTINCT qd.vals.rowid,qd.vals.txt $sqselect"
    db$tid eval "INSERT INTO tags (id,key,val) SELECT DISTINCT t.id,t.key,t.val $sqselect"

    tsv::set sdata data_$tid "$qtile"
    foreach req {OSM.CUR PSI.ODT PSI.OTM} {
	set sq "FROM elements WHERE datasrc LIKE '$req%'"

	set pnum [db$tid eval "SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POINT%'"]
	set lnum [db$tid eval "SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%LINE%'"]
	set llen [db$tid eval "SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%LINE%'"]
	set pgnum [db$tid eval "SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq  AND GeometryType(geom) LIKE '%POLYGON%'"]
	set pglen [db$tid eval "SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) $sq  AND GeometryType(geom) LIKE '%POLYGON%'"] 
	set pgarea [db$tid eval "SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%'"]
	set atr [db$tid eval "SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) FROM elements AS e JOIN tags AS t ON e.id=t.id JOIN keys ON t.key=keys.rowid JOIN vals ON t.val=vals.rowid WHERE e.datasrc LIKE '$req%' GROUP BY t.key,t.val)"]    
	tsv::lappend sdata data_$tid "$pnum $lnum $llen $pgnum $pglen $pgarea $atr"
    }
    db$tid eval {DELETE FROM keys;DELETE FROM vals;DELETE FROM tags;DELETE FROM elements;}
    tsv::set sdata status_$tid off
}

# Duplicated values problem (every tnum times)

cd ~/Desktop/asmbl
tsv::set sdata sdbpath qwgnsdata.sqlite
set tnum 4
set trs {}
for {set i 0} {$i<$tnum} {incr i} {
    lappend trs [thread::create]
}
foreach t $trs {
    tsv::set sdata tile_$t {}
    tsv::set sdata status_$t off
    tsv::set sdata data_$t {}
    thread::send $t $initdb
}


eval $initdb
set tlist [db$tid eval {SELECT q FROM qd.tiles WHERE substr(q,1,8) != '12020332' AND substr(q,1,8) != '12020323'}];set _ _
set rf [open /tmp/results.csv w];#results
#set ef [open /tmp/errors.csv w];#errors

for {set i 0; set j 0} {$i < [llength $tlist] && $j < [llength $tlist]} {incr j} {   
    foreach t $trs {
	if {![tsv::get sdata status_$t]} {
	    if {[llength [set cur [tsv::get sdata data_$t]]] eq 4} {		
		set curtile [tsv::get sdata tile_$t]
		tsv::set sdata data_$t {}
		if {$curtile ne [lindex $cur 0]} {
		    error "${::n-kov::errorHeader} Shared and result tiles has to be equal (given $curtile and [lindex $cur 0])"
		}
		foreach curlist [lrange $cur 1 end] desc {OSM.CUR PSI.ODT PSI.OTM} {
		    puts $rf "$curtile,$desc,[join $curlist ,]"
		}				
	    }	    
	    tsv::set sdata tile_$t [lindex $tlist $i]	    
	    tsv::set sdata status_$t on
	    incr i
	    thread::send -async $t $getdata result	    
	}
    }
    
    vwait result
    if {$result ne {off}} {
    	error "${::n-kov::errorHeader} An error in a thread - result is $result"
    }
    if {$j%100 == 0} {
    		puts  -nonewline stderr "\r[format %.7f [expr {100*(double($i)/double([llength $tlist]))}]]%"
    		flush stderr
    }
}

foreach t $trs {
    if {![tsv::get sdata status_$t]} {
	if {[llength [set cur [tsv::get sdata data_$t]]] eq 4} {		
	    set curtile [tsv::get sdata tile_$t]
	    tsv::set sdata data_$t {}
	    if {$curtile ne [lindex $cur 0]} {
		error "${::n-kov::errorHeader} Shared and result tiles has to be equal (given $curtile and [lindex $cur 0])"
	    }
	    foreach curlist [lrange $cur 1 end] desc {OSM.CUR PSI.ODT PSI.OTM} {
		puts $rf "$curtile,$desc,[join $curlist ,]"
	    }				
	}
    }
}
close $rf

foreach t $trs {
    thread::release $t
}

db$tid close


exec sqlite3 qwgnsdata.sqlite << "create table tmp_tilepsi (tile text, lname text, a integer, b integer, c integer, d integer,e integer,f integer,g integer);\n.mode csv\n.import /tmp/results.cvs tmp_tilepsi\n.exit"
sqlite3 db qwgnsdata.sqlite


db eval {INSERT INTO wbidata
SELECT DISTINCT min(rid),newname,a,b,c,d,e,f,g,-1,-1,-1,-1,-1,-1 FROM (SELECT 
   tiles.rowid AS rid,
   tile AS qt,
   CASE
    WHEN substr(q,1,8) IN ('03131313', '03131311', '12020202') THEN lname || '.SW'
    WHEN substr(q,1,8) IN ('12022123', '12022301') THEN lname || '.TR'
    WHEN substr(q,1,8) IN ('12023022', '12023200') THEN lname || '.SD'
    ELSE lname || '.HD'
END AS newname,a,b,c,d,e,f,g
FROM 
   (SELECT tile,CASE WHEN lname = 'OSM.CUR' THEN 'PSI.OSM' ELSE lname END AS lname,a,b,c,d,e,f,g FROM tmp_tilepsi)
JOIN tiles 
    on tile = tiles.q)
GROUP BY qt,newname}





set curnames [lsearch -inline -all -glob -not $bnames "M*"]
set sqls {}
foreach area {SD TR SW} {
    set selects {}
    foreach n $curnames {
	set min [sdb eval "SELECT min($n) FROM wbidata WHERE name LIKE 'PSI.%.$area'"]
	set range [sdb eval "SELECT (max($n)-min($n))/10.0 FROM wbidata WHERE name LIKE 'PSI.%.$area'"]
	lappend selects "($n-$min)/(1.0*$range)"
    }
    set min [sdb eval "SELECT min(([join $selects +])/[llength $curnames].0) FROM wbidata WHERE name LIKE 'PSI.%.$area'"]
    set max [sdb eval "SELECT max(([join $selects +])/[llength $curnames].0) FROM wbidata WHERE name LIKE 'PSI.%.$area'"]
    set range [expr {($max-$min)/10.0}]
    lappend sqls "UPDATE wbidata SET wbi=CAST(ROUND(   ((([join $selects +])/[llength $curnames])-$min)/($range*1.0)   ) AS INTEGER) WHERE name LIKE 'PSI.%.$area'"
}
sdb eval [join $sqls \;\n]





# set curnum 0
# set sql1 "BEGIN;\n"
# set sq "FROM elements AS e JOIN tags AS t ON e.id=t.id JOIN keys ON t.key=keys.rowid JOIN vals ON t.val=vals.rowid WHERE e.datasrc = 'SanDona.OSM'"
# for {set i $tx1} {$i <= $tx2} {incr i} {
#     for {set j $ty1} {$j <= $ty2} {incr j} {
# 	if {[file exists /tmp/break]} gagaga		
# 	#debug (a tile with pnt-ln-pgn: lassign [::map::slippy geo 2tile {19 45.63365 12.56405}] _ j i
# 	set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,])"
# 	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),$mbr);"]} {
# 	    set intsec "Intersection(geom,$mbr)"
# 	    set intsebo "Intersection(Boundary(geom),$mbr)"
# 	    set quadkey [::n-kov::tilescf::tile2quadkey $i $j $zl]
# 	    lappend sql1 "INSERT INTO wbidata VALUES ((SELECT tiles.rowid FROM tiles WHERE col=$i AND row=$j),'SanDona.OSM.PSI',( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POINT%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr)  AND IsValid(geom) ),( SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) $sq AND Intersects(geom,$mbr) GROUP BY t.key,t.val) ),-1,-1,-1,-1,-1,-1);"
# 	    incr curnum
# 	    if {$curnum%100 == 0} {
# 		lappend sql1 "COMMIT;"
# 		sdb eval [join $sql1 \n];set _ {}
# 		set sql1 "BEGIN;\n"
# 		puts  -nonewline stderr "\r[format %.5f [expr {100*(double($curnum)/double($maxnum))}]]%"
# 		flush stderr
# 	    }
# 	}
#     }
# }
# lappend sql1 "COMMIT;";set _ {}
# sdb eval [join $sql1 \n];set _ {}




# set curnum 0
# set sql1 "BEGIN;\n"
# set sq "FROM elements AS e JOIN tags AS t ON e.id=t.id JOIN keys ON t.key=keys.rowid JOIN vals ON t.val=vals.rowid WHERE e.datasrc LIKE '%.ONM'"
# for {set i $tx1} {$i <= $tx2} {incr i} {
#     for {set j $ty1} {$j <= $ty2} {incr j} {
# 	if {[file exists /tmp/break]} gagaga		
# 	#debug (a tile with pnt-ln-pgn: lassign [::map::slippy geo 2tile {19 45.63365 12.56405}] _ j i
# 	set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,])"
# 	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),$mbr);"]} {
# 	    set intsec "Intersection(geom,$mbr)"
# 	    set intsebo "Intersection(Boundary(geom),$mbr)"
# 	    set quadkey [::n-kov::tilescf::tile2quadkey $i $j $zl]
# 	    lappend sql1 "INSERT INTO wbidata VALUES ((SELECT tiles.rowid FROM tiles WHERE col=$i AND row=$j),'SanDona.ONM.PSI',( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POINT%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr)  AND IsValid(geom) ),( SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) $sq AND Intersects(geom,$mbr) GROUP BY t.key,t.val) ),-1,-1,-1,-1,-1,-1);"
# 	    incr curnum
# 	    if {$curnum%100 == 0} {
# 		lappend sql1 "COMMIT;"
# 		sdb eval [join $sql1 \n];set _ {}
# 		set sql1 "BEGIN;\n"
# 		puts  -nonewline stderr "\r[format %.5f [expr {100*(double($curnum)/double($maxnum))}]]%"
# 		flush stderr
# 	    }
# 	}
#     }
# }
# lappend sql1 "COMMIT;";set _ {}
# sdb eval [join $sql1 \n];set _ {}




# set curnum 0
# set sql1 "BEGIN;\n"
# set sq "FROM elements AS e JOIN tags AS t ON e.id=t.id JOIN keys ON t.key=keys.rowid JOIN vals ON t.val=vals.rowid WHERE e.datasrc LIKE '%.Municipality'"
# for {set i $tx1} {$i <= $tx2} {incr i} {
#     for {set j $ty1} {$j <= $ty2} {incr j} {
# 	if {[file exists /tmp/break]} gagaga
# 	set mbr "BuildMbr([join [::n-kov::tilescf::tile2geom $i $j $zl] ,])"
# 	if {[sdb eval "SELECT Intersects(GeomFromText('$pol'),$mbr);"]} {
# 	    set intsec "Intersection(geom,$mbr)"
# 	    set intsebo "Intersection(Boundary(geom),$mbr)"
# 	    set quadkey [::n-kov::tilescf::tile2quadkey $i $j $zl]
# 	    lappend sql1 "INSERT INTO wbidata VALUES ((SELECT tiles.rowid FROM tiles WHERE col=$i AND row=$j),'SanDona.OD.PSI',( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POINT%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%LINE%' AND Intersects(geom,$mbr) ),( SELECT Ifnull(SUM(NumGeometries(geom)),0) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(ST_Length($intsebo,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr) ),( SELECT CastToInteger(Round(Ifnull(SUM(Area($intsec,1)),0))) $sq AND GeometryType(geom) LIKE '%POLYGON%' AND Intersects(geom,$mbr)  AND IsValid(geom) ),( SELECT count(*) FROM (SELECT DISTINCT group_concat(DISTINCT e.id) $sq AND Intersects(geom,$mbr) GROUP BY t.key,t.val) ),-1,-1,-1,-1,-1,-1);"
# 	    incr curnum
# 	    if {$curnum%100 == 0} {
# 		lappend sql1 "COMMIT;"
# 		sdb eval [join $sql1 \n];set _ {}
# 		set sql1 "BEGIN;\n"
# 		puts  -nonewline stderr "\r[format %.5f [expr {100*(double($curnum)/double($maxnum))}]]%"
# 		flush stderr
# 	    }
# 	}
#     }
# }
# lappend sql1 "COMMIT;";set _ {}
# sdb eval [join $sql1 \n];set _ {}
