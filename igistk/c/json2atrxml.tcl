package require json
package require n-kov
package require sqlite3

set USAGE "
USAGE:
 tclsh [info script] /path/to/input/file.json /path/to/output/file.xml [/path/to/output/file.sqlite]
   /path/to/output/file.sqlite (optional) - applicable only for a logger data model of OnToMap.eu
 
 Example:
   tclsh [info script] ~/projectsdata/dq/ontomap/data/logger.sandona.json /tmp/logger.sandona.xml

"
# lassign "~/projectsdata/dq/ontomap/data/logger.southwark.json /tmp/logger.southwark.xml /tmp/db.sqlite" jsonpath xmlpath outdb
# lassign "~/data/ontomapdata/logger.southwark.json /tmp/logger.southwark.xml /tmp/db.sqlite" paths xmlpath outdb

if {$argc == 2} {
    lassign $argv paths xmlpath
} elseif {$argc == 3} {
    lassign $argv paths xmlpath outdb
} else {
    error "${::n-kov::errorHeader} Wrong number of arguments: $argc. It should be 2. $USAGE"
}

if {[file exists $outdb]} {
    set initsql false
} else {
    set initsql true
}



#
#       LIBRARY (geojson2sqlite)
#

proc recjs {key cur} {
    set retdata  {}
    if {[string first <<-- $cur] eq 0} {
	set curlist [list $cur]
    } else {
	set curlist $cur
    }
    foreach curel $curlist {	
	set isnest 0	
	set data {}
	set attrs {}
	foreach k [dict keys $curel <<--*] {
	    set v [dict get $curel $k]
	    if {[string first <<-- $v]>-1} {
		set isnest 1
		append data [recjs $k $v]
	    } else {
		append attrs " $k=\"[string map {\" &quot; ' &apos; < &lt; > &gt;} $v]\""
	    }
	}
	if {$isnest} {
	    append retdata "\n<$key $attrs >\n$data\n</$key>"
	} else {
	    append retdata "\n<$key $attrs />"
	}
    }
    return $retdata
}


#set jsonpath $paths
set f0 [open $jsonpath r]
set js [read $f0]; set _ {}
set jsref [string map {{\n} {-:NL:-}} [regsub -all {"([[:alnum:]_-]+)":} $js {"<<--\1":}]]; set _ {}
set jsdict [::json::json2dict $jsref]; set _ {}
set of [open $xmlpath w]

puts -nonewline $of "<event_list>"
puts $of [string map {{<<--} {} "\n\n" "\n" {-:NL:-} {\n} & &amp;} [recjs event [dict get $jsdict <<--event_list]]]
puts -nonewline $of "</event_list>"
close $f0
close $of


#
#      INITIALIZATION
#

if {[info exists outdb]} {
    if {[file exists $outdb]} {
	set initsql false
    } else {
	set initsql true
    }

    sqlite3 sdb $outdb
    sdb enable_load_extension true
    sdb eval "SELECT load_extension('mod_spatialite.so');"

    if {$initsql} {
	sdb eval {BEGIN;SELECT InitSpatialMetaData();COMMIT;}
	sdb eval {
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

	    CREATE INDEX keys_index on keys(txt);
	    CREATE INDEX vals_index on vals(txt);
	    CREATE INDEX tags_key_index on tags(key);
	    CREATE INDEX tags_val_index on tags(val);
	    CREATE INDEX elements_version_index on elements(version);
	    CREATE INDEX elements_type_index on elements(type);
	    CREATE INDEX elements_uid_index on elements(uid);
	    CREATE INDEX elements_timestamp_index on elements(timestamp);
	    CREATE INDEX elements_changeset_index on elements(changeset);
	    CREATE INDEX elements_datasrc_index on elements(datasrc);

	    SELECT AddGeometryColumn('elements', 'geom', 4326, 'GEOMETRY', 'XY');
	}
    }
}

set cur [lindex [dict get $jsdict <<--event_list] 0]
set cur {<<--type Point <<--coordinates {-0.093770027160645 51.496941653677}}
sdb eval "SELECT AsText(GeomFromGeoJSON('[::json::dict2json [string map {{<<--} {} \{ \[ \} \]} $cur]]'))"




#set cur [lindex [dict get $jsdict <<--event_list] 0]
set sql1 "BEGIN;\n"
set sql2 "BEGIN;\n"
set el_id [sdb eval {select max(id) from elements}]
if {$el_id eq "{}"} {
    set $el_id  0
} else {
    set el_id [expr {$el_id+1}]
}
set el_dataid 0
#set el_version  NULL
set el_type {}
set el_uid  {}
#set el_timestamp {} 
#set el_changeset  NULL
set el_datasrc  [file rootname [file tail $jsonpath]]
set el_geom {}
set el_tags {}
#sdb eval "SELECT AsText(GeomFromGeoJSON('$el_geom'))"


proc recjs2sql {key cur prev} {
    global sql1 sql2 el_id el_dataid el_type el_uid el_tags  
    if {$key eq "<<--event"} {
	gagaga
	set el_tags {}
    } else {
	set prev "$prev__$key"
    }
    if {$key eq "<<--geometry"} {
	set gtype [dict get $cur <<--type]
	set coords [string map {{ } , \{ \[ \} \]} [dict get $cur <<--coordinates]]
	set el_geom "{\"type\":\"$gtype\",\"coordinates\":\[$coords\]}"
	switch -glob [string tolower $gtype] {
	    *point* {set el_type 0}
	    *line* {set el_type 1}
	    *polygon* {set el_type 2}
	}
	return
    }    
    if {[string first <<-- $cur] eq 0} {
	set curlist [list $cur]
    } else {
	set curlist $cur
    }
    foreach curel $curlist {
	foreach k [dict keys $curel <<--*] {	    
	    if {[lsearch "actor timestamp" $k] eq -1} {
		set v [dict get $curel $k]		
		if {[string first <<-- $v]>-1} {
		    recjs2sql $k $v prev
		} else {
		    lappend el_tags [list [string map {{<<--} {}} ${prev}__k] $v]
		}
	    }
	}
    }    
    if {$key eq "<<--event"} {
	set curid [dict get $cur <<--actor]
	set curtimestamp [dict get $cur <<--timestamp]
    	lappend sql1 "INSERT INTO elements VALUES ($el_id,\"$el_dataid\",NULL,$el_type,$curid,$timestamp,NULL,'$el_datasrc',GeomFromGeoJSON('$el_geom'));"
	foreach curel $el_tags {
	    lassing $curel k v
	    if {$v ne "null" && $v ne {}} {
		lappend sql1 "INSERT INTO keys VALUES (\"$k\");"
		lappend sql1 "INSERT INTO vals VALUES (\"$v\");"
		lappend sql2 "INSERT INTO tags VALUES ($el_id, (SELECT rowid FROM keys WHERE txt=\"$k\"),(SELECT rowid FROM vals WHERE txt=\"$v\"));"
	    }
	}	
	set el_id [incr el_id]	
	set el_dataid [incr el_dataid]
    }    
}


recjs2sql event [dict get $jsdict <<--event_list];set _ {}


dict get $jsdict <<--event_list





	
    return $retdata


    set geomstr [string tolower [dict get $geomdict type]]
    switch -glob $geomstr {
	*point* {set gtype 0}
	*line* {set gtype 1}
	*polygon* {set gtype 2}
	default {error "${::n-kov::errorHeader} An ERROR occured executing `[dict get [info frame 0] proc] $jsonpath $epsg' -> cannot define geometry type `$geomstr' curnum=$curnum geometry:`[dict get $cur geometry]'"}
    }
    	lappend sql1 "INSERT INTO elements VALUES ($curnum,\"$dataid\",$version,$gtype,$uid,$timestamp,$changeset,'$datasrc',GeomFromGeoJSON('$gjson'));"
	foreach {k v} $kv {
	    if {$v ne "null" && $v ne {}} {
		lappend sql1 "INSERT INTO keys VALUES (\"$k\");"
		lappend sql1 "INSERT INTO vals VALUES (\"$v\");"
		lappend sql2 "INSERT INTO tags VALUES ($curnum, (SELECT rowid FROM keys WHERE txt=\"$k\"),(SELECT rowid FROM vals WHERE txt=\"$v\"));"
	    }
	}

	unset timestamp version changeset uid dataid

	incr curnum
	if {$curnum%10000 == 0} {
	    lappend sql1 "COMMIT;"
	    lappend sql2 "COMMIT;"
	    sdb eval [join $sql1 \n];set _ {}
	    sdb eval [join $sql2 \n];set _ {}
	    set sql1 "BEGIN;\n"
	    set sql2 "BEGIN;\n"
	    puts  -nonewline stderr "\r$curnum lines DONE of $datasrc ...%"
	    flush stderr
	}
    }


    lappend sql1 "COMMIT;";set _ {}
    lappend sql2 "COMMIT;";set _ {}
    sdb eval [join $sql1 \n]
    sdb eval [join $sql2 \n]
    puts "$datasrc imported."











    
}










    
}




















































    




if {0 && [catch {
}]} {eval ${::n-kov::breakpoint}}






    
    set isnest 0
    foreach {k v} $cur {
	if {[llendth $v]>1} {
	    set isnest 1
	}
    }
    if {$isnest} {
    } else {
    }
}
    
    






proc lencomp {el_a el_b} {
    set a [lindex $el_a 1]
    set b [lindex $el_b 1]
    set a0 [llength $a]
    set b0 [llength $b]
    if {$a0 > $b0} {
        return -1
    } elseif {$a0 < $b0} {
        return 1
    } else {
	set a1 [string length $a]
	set b1 [string length $b]
	if {$a1 > $b1} {
	    return -1
	} elseif {$a1 < $b1} {
	    return 1
	}	
    }
    return [expr {-1*[string compare [lindex $a 1] [lindex $b 1]]}]
}


set tag {}
proc recjs {cur} {
    set gcur $cur
    foreach {k v} $cur {
	lappend gcur [list $k $v]
    }
    global gevent
    if {[llength $v] eq 1} {	
    } else {
    }
}

proc json2xml {jsonpath} {
    set of [open $xmlpath w]
    set datasrc [file rootname [file tail $jsonpath]]
    set f0 [open $jsonpath r]
    puts $of {<?xml version="1.0" encoding="UTF-8" standalone="no" ?>}
    puts $of {<ontomap>}
    foreach cur [dict get [::json::json2dict [read $f0]] event_list] {
	foreach {k2 v2} $cur {
	    set attrs2 {}
	    set level2 {}
	    if {[lsearch "activity_objects references visibility_details details" $k2]>-1} {
		set attrs3 {}
		set level3 {}
		foreach {k3 v3} $v2 {
		    if {$k3 eq "geometry"} {
			
		    }
		}
	    } else {
		lappend attrs2 "$k2=\"$v2\""
	    }
		
	}	
    }
    puts $of {</ontomap>}
    
}


proc geojson2sqlite {jsonpath {epsg EPSG:4326}} {

    set datasrc [file rootname [file tail $jsonpath]]
    
    set sql1 "BEGIN;\n"
    set sql2 "BEGIN;\n"
    set f0 [open $jsonpath r]
    
    #set data [dict get [::json::json2dict [read $f0]] features];puts ok
    #set cur [lindex $data 16]
    set maxcurnum [sdb eval {select max(id) from elements}]
    if {$maxcurnum eq "{}"} {
	set curnum 0
    } else {
	set curnum [expr {$maxcurnum+1}]
    }
    foreach cur [dict get [::json::json2dict [read $f0]] features] {
	set cur [string map {\" \' ' \'} $cur]
	set kv {}
	if {[lsearch [dict keys $cur] id]>-1} {
	    set dataid [file tail [dict get $cur id]]
	}
	foreach {k v} [dict get $cur properties] {
	    if {[lsearch {timestamp version changeset user uid} $k]>-1} {
		set $k $v
	    } elseif {$k eq {type}} {
	    } elseif {$k eq {id}} {		
		lassign [split $v /] l r
		if {[info exists l] && [info exists r] && [string is digit $r]} {		#set id $r
		    switch $l {
			node {
			    set gtype 0
			}
			way {
			    set gtype 1
			}
			relation {
			    set gtype 2
			}
		    }
		}
		if 0 {else {
		    set id [file tail $v]
		}}
		
	    } else {
		lappend kv $k $v
	    }
	}
	if {[info exists timestamp]} {
	    set timestamp [sdb eval "SELECT strftime('%s','$timestamp')"]
	} else {
	    set timestamp [clock seconds]
	}
	set geomdict [dict create type [dict get $cur geometry type] crs [dict create type name properties [dict create name EPSG:4326]] coordinates {__ins__}]
	set coords [string map {{ } , \{ \[ \} \]} [dict get $cur geometry coordinates]]
	set gjson [string map [list \"__ins__\" \[$coords\]] [::n-kov::tcl2json $geomdict]]

	if {![info exists gtype]} {
	    set geomstr [string tolower [dict get $geomdict type]]
	    switch -glob $geomstr {
		*point* {set gtype 0}
		*line* {set gtype 1}
		*polygon* {set gtype 2}
		default {error "${::n-kov::errorHeader} An ERROR occured executing `[dict get [info frame 0] proc] $jsonpath $epsg' -> cannot define geometry type `$geomstr' curnum=$curnum geometry:`[dict get $cur geometry]'"}
	    }
	}
	
	foreach v {version changeset uid dataid} {
	    if {![info exists $v]} {
		set $v -1
	    }
	}
	
	lappend sql1 "INSERT INTO elements VALUES ($curnum,\"$dataid\",$version,$gtype,$uid,$timestamp,$changeset,'$datasrc',GeomFromGeoJSON('$gjson'));"
	foreach {k v} $kv {
	    if {$v ne "null" && $v ne {}} {
		lappend sql1 "INSERT INTO keys VALUES (\"$k\");"
		lappend sql1 "INSERT INTO vals VALUES (\"$v\");"
		lappend sql2 "INSERT INTO tags VALUES ($curnum, (SELECT rowid FROM keys WHERE txt=\"$k\"),(SELECT rowid FROM vals WHERE txt=\"$v\"));"
	    }
	}

	unset timestamp version changeset uid dataid

	incr curnum
	if {$curnum%10000 == 0} {
	    lappend sql1 "COMMIT;"
	    lappend sql2 "COMMIT;"
	    sdb eval [join $sql1 \n];set _ {}
	    sdb eval [join $sql2 \n];set _ {}
	    set sql1 "BEGIN;\n"
	    set sql2 "BEGIN;\n"
	    puts  -nonewline stderr "\r$curnum lines DONE of $datasrc ...%"
	    flush stderr
	}
    }


    lappend sql1 "COMMIT;";set _ {}
    lappend sql2 "COMMIT;";set _ {}
    sdb eval [join $sql1 \n]
    sdb eval [join $sql2 \n]
    puts "$datasrc imported."


    close $f0
}


#
#       MAIN
#


proc main {paths} {
    foreach el [split $paths ,] {
	foreach p [glob $el] {
	    if {[string first .json [string tolower $p]] == -1} {
		set tmpdir [::n-kov::getRandFileName]
		file mkdir $tmpdir
		set fileroot [file tail [file rootname $p]]
		exec ogr2ogr -t_srs EPSG:4326 -f "GeoJSON" $tmpdir/$fileroot.json $p
		set p $tmpdir/$fileroot.json
	    }

	    geojson2sqlite $p
	    
	    if {[info exists tmpdir]} {
		file delete -force $tmpdir
		unset tmpdir
	    }
	}
    }
    
}

main $paths


if 0 {<<<<

gtype column should be added to the element
sdb eval {ALTER TABLE elements ADD COLUMN gtype INTEGER;}
set sql {begin;}
set gtypes "POINT MULTIPOINT LINESTRING MULTILINESTRING POLYGON MULTIPOLYGON"
sdb eval {SELECT id,GeometryType(geom) as gtype FROM elements} vals {
    lappend sql "UPDATE elements SET gtype = [expr {1+[lsearch $gtypes $vals(gtype)]}] WHERE id=$vals(id);"
}
lappend sql {commit;}; set _ {}
sdb eval [join $sql \n]
unset sql
>>>>

}
