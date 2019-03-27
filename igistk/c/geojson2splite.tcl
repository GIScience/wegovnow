package require json
package require n-kov
package require sqlite3




set USAGE "
USAGE:
 tclsh [info script] '/path/to/files/*.json,/path/to/file.json,/path/to/fileN*.shp result_database.sqlite' \['ogr2ogr extra parameters'\]

   
  \"/path/to/files/*.json,/path/to/file.json,/path/to/fileN*.shp\] - paths to spatial data
                                               separated by comma \",\" - each one will be
                                               evaluated by the \"glob\" command (USE single
                                               quotes ' to prevent the subtitution by shell!)

   result_database.sqlite - path to an output database. It will be created if the file does not exist

   (OPTIONAL) ogr2ogr extra parameters - additional parameters for the ogr2ogr commant (ignored for *.json input files), e.g. '-s_srs EPSG:3003 -t_srs EPSG:4326'.

   

 
 Example (note quotes!):
   tclsh [info script] '$::env(HOME)/projectsdata/dq/SanDona.OSM.json,$::env(HOME)/projectsdata/dq/psi/ontomap_renamed/*.json,$::env(HOME)/projectsdata/dq/psi/sandonashp_renamed/*.shp $::env(HOME)/projectsdata/dq/wgn.sqlite' '-s_srs EPSG:3003 -t_srs EPSG:4326'

"
if {$argc == 2} {
    lassign $argv paths outdb
    set ogr2ogr_pars {}
} elseif {$argc == 3} {
    lassign $argv paths outdb ogr2ogr_pars    
} else {    
    error "${::n-kov::errorHeader} Wrong number of arguments: $argc ($argv). It should be 2 or 3. $USAGE"
}

if 0 {
    lassign "$::env(HOME)/projectsdata/dq/SanDona.OSM.json,$::env(HOME)/projectsdata/dq/psi/ontomap_renamed/*.json,$::env(HOME)/projectsdata/dq/psi/sandonashp_renamed/*.shp $::env(HOME)/projectsdata/dq/wgn.sqlite" paths outdb
    catch {file delete $outdb}
    catch {sdb close}
}

if {[file exists $outdb]} {
    set initsql false
} else {
    set initsql true
}

#
#      INITIALIZATION
#

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



#
#       LIBRARY (geojson2sqlite)
#



proc geojson2sqlite {jsonpath {epsg EPSG:4326}} {

    set datasrc [file rootname [file tail $jsonpath]]

    # set fsql1 [open /tmp/fsql1.sql w]
    # set fsql2 [open /tmp/fsql2.sql w]
    
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
	if {[info exists timestamp] && $timestamp ne {}} {
	    #set tsold $timestamp	    
	    if {![string is wideinteger $timestamp]} {
		set timestamp [sdb eval "SELECT strftime('%s','$timestamp')"]
	    }
	    #eval ${::n-kov::breakpoint}
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

	    # puts $fsql1 [join $sql1 \n]
	    # puts $fsql2 [join $sql2 \n]
	    # close $fsql1
	    # close $fsql2 


	    sdb eval [join $sql1 \n];set _ {}
	    sdb eval [join $sql2 \n];set _ {}

	    # set fsql1 [open /tmp/fsql1.sql w]
	    # set fsql2 [open /tmp/fsql2.sql w]

	    
	    set sql1 "BEGIN;\n"
	    set sql2 "BEGIN;\n"
	    puts  -nonewline stderr "\r$curnum lines DONE of $datasrc ...%"
	    flush stderr
	}
    }


    # puts $fsql1 [join $sql1 \n]
    # puts $fsql2 [join $sql2 \n]
    # close $fsql1
    # close $fsql2

    
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
		exec ogr2ogr {*}$::ogr2ogr_pars -f "GeoJSON" $tmpdir/$fileroot.json $p
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

