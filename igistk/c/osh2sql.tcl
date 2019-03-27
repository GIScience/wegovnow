#/bin/sh
#\
exec tclsh "$0" "$@"

# Calculates general stats of OSM data including history dump
# (c) Alexey Noskov 2017 http://n-kov.com

package require n-kov
package require tdom
package require sqlite3

#set anyfile [open /tmp/anychars.txt w+]

package require critcl
critcl::config keepsrc 1
namespace eval libc {
        critcl::ccommand clock_scan {cd interp objc objv} {
                TCL_DECLARE_MUTEX(scanMutex);
                Tcl_Obj *resObj;
                char timedate[30];
                #include <time.h>
                //struct tm zz;  //->factor 2, very slow
                static struct tm zz; // factor >20 , mutex added
                size_t n, len1, len2;
                char *pdatetime;
                char *pformat;

                if (objc != 3) { 
                        Tcl_WrongNumArgs(interp, 3, objv, NULL);
                        return(TCL_ERROR);
                }
                pdatetime=Tcl_GetStringFromObj(objv[1],&len1);
                //printf("datestring is %s\n", pdatetime);
                pformat=Tcl_GetStringFromObj(objv[2],&len2);
                //printf("formatstring is %s\n", pformat);

                Tcl_MutexLock(&scanMutex);
                (void) strptime(pdatetime, pformat, &zz);
                //printf ("year %d\n", zz.tm_year);
                n=strftime(&timedate[0], 30, "%s", &zz);
                Tcl_MutexUnlock(&scanMutex);

                resObj=Tcl_NewByteArrayObj(&timedate[0], n);
                Tcl_SetObjResult(interp, resObj);
                return(TCL_OK);
        }
}


set shape_to_poly {
    set shape_polygons /home/fudeb/projectsdata/dq/psi/pilotsites.shp
    set polygons ""
    set i 0
    foreach line [split [exec ogrinfo -al $shape_polygons] \n] {
	incr i
	if {[lsearch $line POLYGON]>-1} {
	    lappend polygons [string trim $line]
	}
    }
    foreach p $polygons name {sandona.poly turin.poly southwark.poly} {
	set out {{none} {1}}
	foreach {coord} [regexp -all -inline {[[:digit:].-]+ [[:digit:].-]+} $p] {
	    lset coord 0 [format {%e} [lindex $coord 0]]
	    lset coord 1 [format {%e} [lindex $coord 1]]
	    lappend out $coord	
	}
	lappend out {END} {END}
	set fn [open /tmp/$name w]
	puts $fn [join $out \n]
	close $fn
    }
}

#eval [set ::n-kov::breakpoint]

set USAGE "
 usage(1): [info script] -i incommand \[-s out.sqlite\] \[-l path_to_out_line_stat_file\] \[-t path_to_out_tags_stat_file\] 
    
       (!) at least one of the following commands has to be defined: -s, -l, -t
    
    -i incommand   -  path to OSM/OSH XML file or command (see Examples(2));

    -s out.sqlite  -  (output) path to output .sqlite file,
                      extension required;

    -l path_to_out_line_stat_file (output text file)
    -t path_to_out_tags_stat_file (output text file)

 Examples(2):

     [info script] -i map_heu.osm -s map.sqlite -l linestats.txt -t tagstats.txt
      
     [info script] -i \"| bunzip2 -c /home/fudeb/projectsdata/dq/history-170206.osm.bz2\" -t tagstats.txt

"



#    set ::t $tag
#    set ::a $atrs
if {0 && [catch {}]} {eval [set ::n-kov::breakpoint]}


proc get_str_type {v} {
    if {$v eq {}} {return [lsearch $::types BLANK]}
    if {[string is ascii $v]} {
	if {[string first " " $v]==-1} {	    
	    if {[string is alpha $v]} {
		return [lsearch $::types ALPHA]
	    } else {
		return [lsearch $::types ASCIIANY]
	    }
	} else {
	    return [lsearch $::types ASCIILIST]
	}
    } else {
	if {[string first " " $v]==-1} {
	    if {[string is alpha $v]} {
		return [lsearch $::types NOASCIIALPHA]
	    } else {
		return [lsearch $::types NOASCIIANY]
	    }
	} else {	    
	    return [lsearch $::types NOASCIILIST]
	}
    }
    error "[set ::n-kov::errorHeader] undefined string type '$v' in get_str_type"
}

#maintype - num, bool, member, str
proc get_measures {v maintype} {
    set len [string length $v]
    if {$maintype eq "num"} {
	set sum [expr {0+$v}]
	return "$len 1 $sum $sum"
    } elseif {$maintype eq "str"} {
	return "$len 1 $len $len"
    } elseif {$maintype eq "bool"} {
	if {$v} {
	    #set sum 1
	    set a 0
	    set b 1
	} else {
	    #set sum -1
	    set a 1
	    set b 0
	}
	return "$len 1 $a $b"
    } elseif {$maintype eq "member"} {
	switch $v {
	    "node" {
		return "$len 1 0 0"
	    }
	    "way" {
		return "$len 0 1 0"
	    }
	    "relation" {
		return "$len 0 0 1"
	    }
	    default {
		error "[set ::n-kov::errorHeader] wrong maintype member '$v' in set_types"
	    }
	}
	    
    } else {
	error "[set ::n-kov::errorHeader] wrong maintype '$maintype' in set_types"
    }
}



proc handledata {tag atrs} {
    array set atrar $atrs	
    if {[lsearch "node way relation changeset" $tag]>=0} {
	if {$tag eq "changeset"} {
	    set atrar(timestamp) $atrar(closed_at)
	} else {
	    switch $tag {
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
	    set ::mainid "$atrar(id)[format %0.3i $atrar(version)]$gtype"
	}
	set ::maintag $tag
	catch {array unset ::mainatrs}
	array set ::mainatrs [array get atrar]
	#regexp {timestamp="([^\"]*)"} $atrs _ curts
        set ::maints [mdb eval "SELECT strftime('%s','$atrar(timestamp)')"]
	#set ::maints [libc::clock_scan [lindex $atrs [expr {[lsearch $atrs timestamp]+1}]] {%Y-%m-%dT%H:%M:%SZ}]
	#set ::maints [clock scan [lindex $atrs [expr {[lsearch $atrs timestamp]+1}]] -format {%Y-%m-%dT%H:%M:%SZ} -timezone $::tz]
    }

    #::n-kov::profiler sql1
         
    if {[info exists ::outsql]} {

	if {[info exist atrar(user)]} {
	    lappend ::sql1 "INSERT INTO users VALUES ($atrar(uid),\"$atrar(user)\");"
	}

	    switch $tag {
		changeset {
		    lappend ::sql1 "INSERT INTO xys VALUES ($atrar(min_lon),$atrar(min_lat));"
		    lappend ::sql1 "INSERT INTO xys VALUES ($atrar(max_lon),$atrar(max_lat));"
		    set opendat [sdb eval "SELECT strftime('%s','$atrar(created_at)')"]
		    set closedat [sdb eval "SELECT strftime('%s','$atrar(closed_at)')"]
		    if {$atrar(open)} {
			set isopen 1
		    } else {
			set isopen 0
		    }

		    lappend ::sql2 "INSERT INTO changesets VALUES ($atrar(id),$opendat,$closedat,$isopen,$atrar(uid),(SELECT rowid FROM xys WHERE x=$atrar(min_lon) AND y=$atrar(min_lat)),(SELECT rowid FROM xys WHERE x=$atrar(max_lon) AND y=$atrar(max_lat)),$atrar(num_changes),$atrar(comments_count));"		
		}
		node -
		way -
		relation {		
		    if {![info exists atrar(visible)]} {
			set atrar(visible) true
		    }		
		    if {$atrar(visible)} {
			set visible 1
		    } else {
			set visible 0
		    }
		    if {![info exists atrar(uid)]} {
			set atrar(uid) NULL
		    }

		    lappend ::sql1 "INSERT INTO elements VALUES ($::mainid,$atrar(id),$atrar(version),$gtype,$atrar(uid),$visible,$::maints,$atrar(changeset));"

		    if {[info exists atrar(lat)] && [info exists atrar(lon)]} {
			lappend ::sql1 "INSERT INTO xys VALUES ($atrar(lon),$atrar(lat));"
			lappend ::sql2 "INSERT INTO elidxy VALUES ($::mainid,(SELECT rowid FROM xys WHERE x=$atrar(lon) AND y=$atrar(lat)));"
		    }
		}
		tag {
		    lappend ::sql1 "INSERT INTO keys VALUES (\"$atrar(k)\");"
		    lappend ::sql1 "INSERT INTO vals VALUES (\"$atrar(v)\");"
		    lappend ::sql1 "INSERT INTO tags VALUES ($::mainid,(SELECT rowid FROM keys WHERE txt = \"$atrar(k)\"),(SELECT rowid FROM vals WHERE txt = \"$atrar(v)\"));"
		}
		nd -
		member {
		    if {$tag eq "nd"} {
			set gtype 0
		    } else {
			switch $atrar(type) {
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
		    lappend ::sql1 "INSERT INTO relations VALUES ($::mainid,$atrar(ref));"

		    if {[info exists atrar(role)] && [string length $atrar(role)]>0} {
			lappend ::sql1 "INSERT INTO roles VALUES (\"$atrar(role)\");"
			lappend ::sql2 "INSERT INTO relrols VALUES ( (SELECT rowid FROM relations WHERE root=$::mainid AND member=$atrar(ref)),(SELECT rowid FROM roles WHERE txt=\"$atrar(role)\"));"
		    }
		}
	    }
    }
    #::n-kov::profiler sql2
    #::n-kov::profiler before

    if {[info exists ::outtagstat]} {    
	foreach {n v} $atrs {
	    set type [lsearch $::types UNDEFINED]
	    if {[set tn [lsearch {node way relaton changeset} $tag]]>-1} {	    
		if {$n eq "id" || $n eq "uid"} {
		    lassign [get_measures $v num] len sum a b
		    set type [lsearch $::types INTEGER]		
		} elseif {$n eq "user"} {
		    lassign [get_measures $v str] len sum a b
		    set type [get_str_type $v]
		} else {
		    if {$tn<3} {
			if {$n eq "visible"} {
			    lassign [get_measures $v bool] len sum a b
			    set type [lsearch $::types BOOL]
			} elseif {$n eq "version" || $n eq "changeset"} {
			    lassign [get_measures $v num] len sum a b
			    set type [lsearch $::types INTEGER]
			} elseif {$n eq "timestamp"} {
			    lassign [get_measures $::maints num] len sum a b
			    set type [lsearch $::types INTEGER]
			} elseif {$n eq "lat" || $n eq "lon"} {
			    lassign [get_measures $v num] len sum a b
			    set type [lsearch $::types DOUBLE]
			} 
		    } else {
			if {$n eq "open"} {
			    lassign [get_measures $v bool] len sum a b
			    set type [lsearch $::types BOOL]
			} elseif {$n eq "created_at"||$n eq "closed_at"} {
			    lassign [get_measures [sdb eval "SELECT strftime('%s','$v')"] num] len sum a b
			    set type [lsearch $::types INTEGER]
			} elseif {$n eq "num_changes" || $n eq "comments_count"} {
			    lassign [get_measures $v num] len sum a b
			    set type [lsearch $::types INTEGER]
			} elseif {$n eq "min_lat" || $n eq "min_lon" || $n eq "max_lat" || $n eq "max_lon"} {
			    lassign [get_measures $v num] len sum a b
			    set type [lsearch $::types DOUBLE]
			} 
		    }
		}		
	    } else {
		if {$n eq "k" || $n eq "v" || $n eq "role"} {
		    lassign [get_measures $v str] len sum a b
		    set type [get_str_type $v]		
		} elseif {$n eq "ref"} {
		    lassign [get_measures $v num] len sum a b
		    set type [lsearch $::types INTEGER]
		} elseif {$n eq "member"} {
		    set len [string length $v]
		    set type [lsearch $::types MEMBER]
		    switch $v {
			"node" {
			    lassign "$len 1 0 0" len sum a b
			}
			"way" {
			    lassign "$len 0 1 0" len sum a b
			}
			"relation" {
			    lassign "$len 0 0 1" len sum a b
			}
			default {
			    set type [lsearch $::types UNDEFINED]
			}
		    }
		}		
	    }

	    if {$type eq [lsearch $::types UNDEFINED]} {
		lassign [get_measures $v str] len sum a b
	    }

	    set ticks_length [llength $::ticks]
	    for {set i 0} {$i<$ticks_length} {incr i} {
		if {$i eq "[expr {$ticks_length-1}]"} {
		    set endtick $::curtime
		} else {
		    set endtick [lindex $::ticks [expr {$i+1}]]
		}
		if {[lindex $::ticks $i] <= $::maints && $::maints < $endtick} {
		    if {![info exists ::res(${i}::${::maintag}::${tag}::${n}::${type})]} {
			set ::res(${i}::${::maintag}::${tag}::${n}::${type}) "0 0 -0 -0"
		    }
		    lset ::res(${i}::${::maintag}::${tag}::${n}::${type}) 0 [expr {[lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 0]+$len}]
		    lset ::res(${i}::${::maintag}::${tag}::${n}::${type}) 1 [expr {[lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 1]+$sum}]	
		    if {$type < 10} {
			if {[lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 2] eq "-0" || [lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 2]>$a} {
			    lset ::res(${i}::${::maintag}::${tag}::${n}::${type}) 2 $a
			}
			if {[lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 3] eq "-0" || [lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 3]<$b} {
			    lset ::res(${i}::${::maintag}::${tag}::${n}::${type}) 3 $b
			}
		    } elseif {$type == 10 || $type == 11} {
			lset ::res(${i}::${::maintag}::${tag}::${n}::${type}) 2 [expr {[lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 2]+$a}]
			lset ::res(${i}::${::maintag}::${tag}::${n}::${type}) 3 [expr {[lindex $::res(${i}::${::maintag}::${tag}::${n}::${type}) 3]+$b}]
		    } else {
			error "[set ::n-kov::errorHeader] wrong type '$type' --> info exists ::res(${::maintag}::${tag}::${n}::${type})"
		    }
		}
	    }
	}
    }
}

# Fixme! The "MEMBER" element should be deleted
set types "BLANK UNDEFINED NOASCIILIST NOASCIIANY NOASCIIALPHA ASCIILIST ALPHA ASCIIANY DOUBLE INTEGER BOOL MEMBER"
#           0       1        2           3          4            5         6      7       8     9       10   11
#  set i 0;foreach t $types {puts -nonewline " $i:$t";incr i}

set tz :Etc/UCT
set burth [clock scan "01-10-2004 00:00:00" -format {%d-%m-%Y %H:%M:%S} -timezone $tz]
set curtime [clock seconds]
set ticks {}
for {set i $burth} {$i<$curtime} {set i [clock add $i 3 months]} {
    lappend ticks $i
}
lappend ticks $curtime


catch {array unset stats {}}
array set stats {lines 0 chars 0 atrs 0 noatrs 0 sblank 0 fblank 0 stags 0 ctags 0 less 0 slashmore 0 more 0 equals 0 mblanks1 0 mblanksmore 0 noatrs09 0 noatrsaz 0 noatrsAZ 0 noatrsascii 0 noatrsany 0 dquotes 0 atrsblanks 0 atrs09 0 atrsaz 0 atrsAZ 0 atrsup 0 atrslow 0 atrsalpha 0 atrsdigit 0 atrspunct 0 atrsgraph 0 atrsany 0}
catch {array unset res {}}
array set res {}

proc rawstringstat {line} {
    #set line {   <bound bjjox="-90,-180,90,180" origin="http://www.openstreetmap.org/api/0.6"/> }
    #set line {  <node id="14551102" version="1" timestamp="2006-08-31T11:21:21Z" uid="573" user="J&#xF6;rg Ostertag" changeset="99137" visible="true" lat="45.5704667" lon="12.5078150">}
     incr ::stats(lines)
     set lnum [string length $line]
     set ::stats(chars) [expr {$lnum+$::stats(chars)}]
     
     set ltrim [string trimleft $line]
     set ltrimnum [string length $ltrim]
     set numsblank [expr {$lnum-$ltrimnum+$::stats(sblank)}]
     if {$numsblank>0} {
	 set ::stats(sblank) $numsblank
     }

     set rtrim [string trimright $ltrim]
     set rtrimnum [string length $rtrim]
     set numfblank [expr {$rtrimnum-$ltrimnum+$::stats(fblank)}]
     if {$numfblank>0} {
	 set ::stats(fblank) $numfblank
     }

     set atrs [join [regexp -all -inline {\"[^\"]*\"} $rtrim] {}]
     set noatrs [regsub -all {\"[^\"]*\"} $rtrim {}]

     set ::stats(atrs) [expr {$::stats(atrs)+[string length $atrs]}]
     set ::stats(noatrs) [expr {$::stats(noatrs)+[string length $noatrs]}]

     if {[regexp {<[\w]+} $noatrs stag]} {
	 set noatrs [string map [list $stag {}] $noatrs]
	 set ::stats(stags) [expr {$::stats(stags)+[string length $stag]}]
     } elseif {[string first "</" $noatrs]>-1} {
	 set noatrs [string map {{</} {}} $noatrs]
	 incr ::stats(ctags) 2
     } elseif {[string first "<" $noatrs]>-1} {
	 set noatrs [string map {{<} {}} $noatrs]
	 incr ::stats(less)
     }

     if {[string first "/>" $noatrs]>-1} {
	 set noatrs [string map {{/>} {}} $noatrs]
	 incr ::stats(slashmore) 2
     } elseif {[string first ">" $noatrs]>-1} {
	 set noatrs [string map {{>} {}} $noatrs]
	 incr ::stats(more)
     }

     set ::stats(equals) [expr {$::stats(equals)+[llength [regexp -all -inline {=} $noatrs]]}]
     set noatrs [string map {{=} {}} $noatrs]

     set blanks [regexp  -all -inline {\s+} $noatrs]
     if {[llength $blanks]>0} {
	 foreach b $blanks {
	     set blen [string length $b]
	     if {$blen eq 1} {
		 incr ::stats(mblanks1)
	     } else {
		 set ::stats(mblanksmore) [expr {$::stats(mblanksmore)+$blen}]
	     }
	 }
     }
     
     set noatrs [regsub -all {\s+} $noatrs {}]
     foreach s [split $noatrs {}] {
	 if {[regexp {[0-9]} $s]} {
	     incr ::stats(noatrs09)
	 } elseif {[regexp {[a-z]} $s]} {
	     incr ::stats(noatrsaz)
	 } elseif {[regexp {[A-Z]} $s]} {
	     incr ::stats(noatrsAZ)
	 } elseif {[string is ascii $s]} {
	     incr ::stats(atrsascii)
	 } else {
	     incr ::stats(noatrsany)
	 }
     }

     
     set ::stats(dquotes) [expr {$::stats(dquotes)+[llength [regexp -all -inline {\"} $atrs]]}]
     set atrs [string map {\" {}} $atrs]
     foreach s [split $atrs {}] {
	 if {[string is space $s]} {
	     incr ::stats(atrsblanks)
	 } elseif {[regexp {[0-9]} $s]} {
	     incr ::stats(atrs09)
	 } elseif {[regexp {[a-z]} $s]} {
	     incr ::stats(atrsaz)
	 } elseif {[regexp {[A-Z]} $s]} {
	     incr ::stats(atrsAZ)
	 } elseif {[string is upper $s]} {
	     incr ::stats(atrsup)
	 } elseif {[string is lower $s]} {
	     incr ::stats(atrslow)
	 } elseif {[string is alpha $s]} {
	     incr ::stats(atrsalpha)
	 } elseif {[string is digit $s]} {
	     incr ::stats(atrsdigit)
	 } elseif {[string is punct $s]} {
	     incr ::stats(atrspunct)
	 } elseif {[string is graph $s]} {
	     incr ::stats(atrsgraph)
	 } else {
	     # puts FOUND_LINE:$line
	     # puts S:$s
	     # exit
	     #puts $::anyfile $s
	     incr ::stats(atrsany)
	 }
     }
 }



proc main {} {
    
    foreach arg $::argv {
	if {[string index $arg 0] eq "-"} {
	    set curcom $arg
	    continue
	}
	switch $curcom {
	    "-i" {
		set ::incom $arg
	    }
	    "-s" {
		set ::outsql $arg
	    }
	    "-l" {
		set ::outlinestat $arg
	    }
	    "-t" {
		set ::outtagstat $arg
	    }
	}	
    }

    if 0 {
	set ::incom
	set ::outsql 
	set ::outlinestat
	set ::outlinestat 	
    }
    
    if {![info exists ::incom]} {
	error "[set ::n-kov::errorHeader] -i incommand has to be set \n$::USAGE"
    }    
    if {![info exists ::outsql] && ![info exists ::outlinestat] && ![info exists ::outtagstat]} {
	error "[set ::n-kov::errorHeader] one of the following parameters has to be set: -s, -l, or -t \n$::USAGE"
    }
    set numlines 0
    puts "Calculating number of lines:\n\n"
    foreach curcmd [split $::incom \;] {
	set fn [open $curcmd]	
	while {[gets $fn line]>=0} {
	    incr numlines
	    if {$numlines%1000000 == 0} {
		puts -nonewline "\rLN:$numlines"
		flush stdout
	    }
	}
	close $fn
    }

    set path_to_mod_spatialite_so /home/local/lib/mod_spatialite.so    
    sqlite3 mdb :memory:
    mdb enable_load_extension true
    mdb eval "SELECT load_extension('$path_to_mod_spatialite_so');"

    if {[info exists ::outsql]} {
	set ::sql1 "BEGIN;"
	set ::sql2 "BEGIN;"	
	set resdb $::outsql
	
	catch {sdb close}
	catch {file delete $resdb}
	sqlite3 sdb $resdb
	sdb enable_load_extension true
	sdb eval "SELECT load_extension('$path_to_mod_spatialite_so');"
	#sdb eval {BEGIN;SELECT InitSpatialMetaData();COMMIT;}
	sdb eval {
	    CREATE TABLE users (
				id INTEGER,
				name TEXT,
				PRIMARY KEY (id,name) ON CONFLICT IGNORE);

	    CREATE TABLE xys (
			      x REAL,
			      y REAL,
			      UNIQUE (x,y) ON CONFLICT IGNORE);

	    CREATE TABLE keys (
			       txt TEXT,
			       UNIQUE (txt) ON CONFLICT IGNORE);

	    CREATE TABLE vals (
				 txt TEXT,
				 UNIQUE (txt) ON CONFLICT IGNORE);

	    CREATE TABLE elements (
				   id INTEGER PRIMARY KEY ,
				   xmlid INTEGER,
				   version INTEGER,
				   type INTEGER,
				   uid INTEGER,
				   visible INTEGER,
				   timestamp INTEGER,
				   changeset INTEGER,
				   UNIQUE (xmlid,version,type),
				   FOREIGN KEY (uid) REFERENCES users(id));
	    CREATE TABLE roles (
				 txt TEXT,
				 UNIQUE (txt) ON CONFLICT IGNORE);
	    CREATE TABLE relrols (
				 relid INTEGER,
				 rol INTEGER,
				 FOREIGN KEY (relid) REFERENCES relations(rowid),
				 FOREIGN KEY (rol) REFERENCES roles(rowid));

	    CREATE TABLE relations (
			    root INTEGER,
			    member INTEGER,
			    FOREIGN KEY (root) REFERENCES elements(id),
			    FOREIGN KEY (member) REFERENCES elements(xmlid));

	    CREATE TABLE elidxy (
			    id INTEGER PRIMARY KEY,
			    xy INTEGER,
			    FOREIGN KEY (id) REFERENCES elements(id),
			    FOREIGN KEY (xy) REFERENCES xys(rowid));

	    CREATE TABLE tags (
			    id INTEGER,
			    key INTEGER,
			    val INTEGER,
			    PRIMARY KEY (id, key, val),
			    FOREIGN KEY (id) REFERENCES elements(id),
			    FOREIGN KEY (key) REFERENCES keys(rowid),
			    FOREIGN KEY (val) REFERENCES vals(rowid));

	    CREATE TABLE changesets (
			    id INTEGER PRIMARY KEY,
			    openedat INTEGER,
			    closedat INTEGER,
			    isopen INTEGER,
			    uid INTEGER,
			    mincoord INTEGER,
			    maxcoord INTEGER,
			    numchanges INTEGER,
			    numcomments INTEGER,
			    FOREIGN KEY (uid) REFERENCES users(id),		    
			    FOREIGN KEY (mincoord) REFERENCES xys(rowid),
			    FOREIGN KEY (maxcoord) REFERENCES xys(rowid));

	    CREATE INDEX xy_index on xys(x,y);
	    CREATE INDEX keys_index on keys(txt);
	    CREATE INDEX vals_index on vals(txt);
	    CREATE INDEX relations_index on relations(root,member);    
	}
    }    
    # set numlines 2228184102
    # set numlines 88710093

    puts "Progress:"
    set curnum 0

    foreach curcmd [split $::incom \;] {
	
	set fn [open $curcmd]
	foreach i {0 1 2} {
	    gets $fn
	}

	#::n-kov::profiler start
	while {[gets $fn line]>=0 } {
	    #::n-kov::profiler preraw
	    if {[info exists ::outlinestat]} {
		rawstringstat $line
	    }
	    #::n-kov::profiler postraw
	    set line [string trim $line]
	    incr curnum
	    if {$curnum%10000 == 0} {
		if {[info exists ::outsql]} {
		    lappend ::sql1 "COMMIT;"
		    lappend ::sql2 "COMMIT;"
		    sdb eval [join $::sql1 \n]
		    sdb eval [join $::sql2 \n]
		    set ::sql1 "BEGIN;"
		    set ::sql2 "BEGIN;"
		}

		puts  -nonewline "\r[format %.5f [expr {100*$curnum/double($numlines)}]]%"
		flush stdout
	    }	
	    if {[string first { } $line]>1} {
		set atrs [regexp -all -inline {\w+=\"[^\"]*\"} $line] 
		catch {array unset atrar}
		array set atrar {}
		foreach cur $atrs {
		    set first [string first "=\"" $cur]
		    set k [string range $cur 0 [expr {$first-1}]]
		    set v [string range $cur [expr {$first+2}] end]
		    #lassign [split $cur =] k v
		    set atrar($k) [string trim $v \"]
		}
		regexp {<([\w]+) } $line _ tag
		#::n-kov::profiler prehandle
		handledata $tag [array get atrar]
		#::n-kov::profiler posthandle
	    }
	}

	if {[info exists ::outsql]} {
	    lappend ::sql1 "COMMIT;"
	    lappend ::sql2 "COMMIT;"
	    sdb eval [join $::sql1 \n]
	    sdb eval [join $::sql2 \n]
	    set ::sql1 "BEGIN;"
	    set ::sql2 "BEGIN;"
	}
	close $fn
    }

    if {[info exists ::outsql]} {
	sdb eval {	
	    DROP INDEX xy_index;
	    DROP  INDEX keys_index;
	    DROP  INDEX vals_index;
	    DROP  INDEX relations_index;
	    VACUUM;
	}
    }
    #::n-kov::profiler end

    
    if {[info exists ::outtagstat]} {
	set outfile [open $::outtagstat w]
	puts $outfile [array get ::res]
	close $outfile
    }

    
    if {[info exists ::outlinestat]} {
	set outfile [open $::outlinestat w]
	puts $outfile [array get ::stats]
	close $outfile
    }
}

main
#close $anyfile
puts "\nDONE\n"


if 0 {
    lassign {"| osmconvert /home/fudeb/projectsdata/dq/map_heu.pbf" parsechannel} infile command
    lassign {"| osmconvert /home/fudeb/projectsdata/dq/history170209.osm.pbf" parsechannel} infile command
    lassign {"| osmconvert /home/fudeb/projectsdata/dq/ManheimHeidelbergBad.osh.pbf" parsechannel} infile command
    set infile "| bunzip2 -c /home/fudeb/projectsdata/dq/history-170206.osm.bz2"
    set infile "| bunzip2 -c /tmp/out.bz2"
    set infile "| bunzip2 -c /home/fudeb/projectsdata/dq/clipdump/sandona.osh.bz2"
    set infile "| bunzip2 -c /home/fudeb/projectsdata/dq/clipdump/turin.osh.bz2"
    set infile "| bunzip2 -c /home/fudeb/projectsdata/dq/clipdump/southwark.osh.bz2"
    set infile "| bunzip2 -c /home/fudeb/projectsdata/dq/clipdump/sandona.osm.bz2"
    set infile "| bunzip2 -c /home/fudeb/projectsdata/dq/clipdump/turin.osm.bz2"
    set infile "| bunzip2 -c /home/fudeb/projectsdata/dq/clipdump/southwark.osm.bz2"
    set infile "/home/fudeb/projectsdata/dq/map_heu.osm"
}    
