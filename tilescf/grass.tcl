#
# grass.tcl --
#    TCL's GRASS GIS API. It enables us to set a GRASS's evironment,
#    execute GRASS's commands from TCL. It can be used as a package
#    or as a standalone application executing TCL commands from stdin.
#
#
# version 0.4.1 (last update 04.2016)
#
# Usefull links:
# (1)  https://groups.google.com/forum/#!topic/comp.lang.tcl/oE8__EWWPM8

package provide grs 0.4
package require fileutil
package require sqlite3
namespace eval n-kov::grs {

variable thre 0.0001

# Here we save unknown's body to var to call it further
# from modified unknown proc.
# HowToUse:
#   eval $init_script
variable init_script {

global unknown_original
set  unknown_original  [ info body  unknown ]

# unknown --

#   It enables us to start grass commands from ::env(PATH)
#   without exec function. If grass command contains
#   inp= argument and doesn't contain out[put]= argument
#   result of command will be saved into a source input
#   raster or vector. It is achieved by saving result
#   into temporary vector or raster, and further ranaming
#   it to the source dataset. The process starts automati-
#   cally when grass command is typed in a tcl shell.
#
# Arguments:
#   args   grass command (else unknown original body will
#          be evaluated.
#
# Results:
#   grass command output is returned.
#
proc unknown args {
    set cmd [lindex $args 0]
    set mystderr [::n-kov::getRandFileName .stderr.txt]
    # Checking if it is grass command    
    if {[string match "*.*" $cmd] && [string is alnum [string map {. ""} $cmd]]} {

	# Checking if saving result to a input dataset
	# is required.
	
	if {[regexp {^[vr].} $cmd curtype] && [string match "*inp=*" $args] && ![string match "*out*" $args]} {
	    regexp { inp=(\w+)\M} $args -> input
	    set output ${input}_temp[::n-kov::RandomlyPicked 4]
	    lappend args "out=$output"
	}

        ;# Main execution.
	;#puts "::n-kov::grs -->> stderr in $mystderr"
        set outCheck1 [catch {exec 2>$mystderr {*}$args} ret] 
        set file [open $mystderr]
	puts [read $file]
	close $file
	# Saving to the input dataset, if required.
	
	if {[info exists output] && !$outCheck1} {
	    if {$curtype == "v."} {
		set curtype vector
	    } else {
		set curtype raster
	    }
	    set outCheck2 [catch {exec 2>$mystderr g.rename $curtype=$output,$input --o}]
            set file [open $mystderr]
            puts [read $file]
	    close $file
	}

	# Returning stdout of the main execution.
	file delete -force $mystderr
	if $outCheck1 {
	    error "${::n-kov::errorHeader} An ERROR occured in $args !"
	}
	if {[info exists $outCheck1] && $outCheck2} {
	    error "${::n-kov::errorHeader} An ERROR ocured in g.rename $curtype=$output,$input --o !"
	}
	return $ret
    }

    # Throwing an error if the command is not grass command
    global unknown_original
    eval $::unknown_original
}
}



# HowToUse:
#   array set ::env [get_env /home/ldeb/projectsdata/temp/trento3dgen.gdb/PERMANENT]
proc get_env {{locationPath {}} {grassPath {}} {version 7.2.2} {evalinit 1}} {
    package require fileutil
    set ::n-kov::grs::curRand [::n-kov::RandomlyPicked 6]
    if {$locationPath != {}} {
	set locpath $locationPath
    } else {
	set locpath [file join [::fileutil::tempdir] grass_[set ::n-kov::grs::curRand]]
    }
    set rcpath [::n-kov::getRandFileName .txt rc_${::n-kov::grs::curRand}_]
    set envFilePath [::n-kov::getRandFileName .sqlite env_${::n-kov::grs::curRand}_]
    if { $grassPath == {} } {

        set GrassExec grass[string cat {*}[lrange [string map {. " "} $version] 0 1]]
	
	if {[string equal -nocase $::tcl_platform(platform) unix]} {
	    
	    set grassPath $GrassExec
	} elseif {[string equal -nocase $::tcl_platform(platform) windows]} {
	    package require registry 
            set ProgDir [registry get {HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\Session Manager\SFC} ProgramFilesDir]
	    set OnX64 ""
	    if [string equal -nocase $::tcl_platform(machine) amd64] {
		set OnX64 " (x86)"
	    }
	    set grassPath [string cat $ProgDir $OnX64 [file separator] "GRASS GIS " $version [file separator] $GrassExec .bat]
	    
	} else {
	    error "[set ::n-kov::errorHeader] we currenly do not support $::tcl_platform(platform)"
	}
    }
    if {![string is print -strict [auto_execok $grassPath]]} {
	error "${::n-kov::errorHeader} $grassPath is not executable"
    }

    if {$locationPath == {} || ![file exists $locationPath]} {
	set flag -c
    } 
    if {[string equal -nocase $::tcl_platform(platform) unix]} {
	set ::env(TERM) linux
    }  elseif {[string equal -nocase $::tcl_platform(platform) windows]} {
	set ::env(TERM) cygwin
    }
    if {[info exists flag]} {
	set io [open |[list $grassPath $flag $locpath] r+]
    } else {
	set io [open |[list $grassPath $locpath] r+]
    }
    fconfigure $io -buffering line -blocking 0
    #fconfigure $io -buffering line 
    
    if {[string is print -strict [auto_execok [file join [file dirname [info nameofexecutable]] tclsh]]]} {
    	puts $io [file join [file dirname [info nameofexecutable]] tclsh]
    } else {
	puts $io [info nameofexecutable]
    }
    puts $io "package require sqlite3;catch {unset ::env(GRASS_PAGER)};sqlite3 db $envFilePath;catch {db eval {CREATE TABLE envars(name,value)}};db eval BEGIN;foreach {name value} \[array get ::env\] {db eval {INSERT INTO envars VALUES(\$name,\$value)}};db eval COMMIT;db close;update;file copy \"\$::env(GISRC)\" \"$rcpath\""
    puts $io exit
    puts $io exit
    close $io
    update
    puts "((( ::n-kov::grs -->> start_reading"
    #gets stdin
    set cont 0
    for {set i 0} {$i<10} {incr i} {
	after 1000
	if [file exists $rcpath] {
	    set cont 1
	    break
	}
    }
    if $cont {
	sqlite3 db $envFilePath
	puts "::n-kov::grs -->> stop_reading )))"
	array set gisEnv [db eval {SELECT * FROM envars}]
	set gisEnv(envfile) $envFilePath
	set gisEnv(GISRC) $rcpath
	db close
    } else {
	error "[set ::n-kov::errorHeader] Env file $envFilePath doesn't exist"
    }
    if {$evalinit} {
	uplevel #0 {eval [set ::n-kov::grs::init_script]}
    }    
    return [array get gisEnv]
}


variable vector_header {ORGANIZATION: n-kov_grs 
DIGIT DATE:   [clock format [clock seconds] -format {%a %b %d %T %Y}]
DIGIT NAME:   n-kov_grs
MAP NAME:     n-kov_grs
MAP DATE:     [clock format [clock seconds] -format {%a %b %d %T %Y}]
MAP SCALE:    1
OTHER INFO:   generated_by_n-kov_grs
ZONE:  0
MAP THRESH:   ${::n-kov::grs::thre}
VERTI:
}

# if $bbox eq "region", the region will be used
proc b2v {outname bbox {delta 0}} {
    if {$bbox eq "region"} {
	foreach par [g.region -g] {
	    set {*}[split $par =]
	}
    } else {
	lassign $bbox w s e n
    }
    set fn [::n-kov::getRandFileName .bbox.txt]
    set f1 [open $fn w]
    set i 0
    foreach p {$e+$delta $w-$delta $n+$delta $s-$delta $w+abs($w-$e)/2.0 $s+abs($n-$s)/2.0} {
	set p$i [expr $p]
	incr i
    }    
    puts $f1 "[subst ${::n-kov::grs::vector_header}]B  5\n$p0 $p2\n$p0 $p3\n$p1 $p3\n$p1 $p2\n$p0 $p2\nC  1 1\n$p4 $p5\n1     2"
    close $f1
    v.in.ascii in=$fn out=$outname format=standard --o
    file delete $fn
}
# ::n-kov::grs::clear [array get ::env]
proc clear {e} {
    array set en $e
    file delete $en(envfile)
    file delete $en(GISRC)
}
    
    
proc dbexe {sql {withcommit 1}} {
    set fn [::n-kov::getRandFileName .sql.txt]
    set f1 [open $fn w]
    if {$withcommit} {
	puts $f1 "BEGIN;\n"
    }
    puts $f1 [join $sql \n]
    if {$withcommit} {
	puts $f1 "COMMIT;"
    }    
    close $f1
    db.execute in=$fn
    file delete $fn
}

proc vinas {lst out {format standard} {opts {}}} {
    set fn [::n-kov::getRandFileName .grascii.txt]
    set f1 [open $fn w]
    if {$format eq {standard}} {
	set header [subst ${::n-kov::grs::vector_header}]
	puts $f1 $header	
    }
    puts $f1 [join $lst \n]
    close $f1
    v.in.ascii in=$fn out=$out f=$format {*}$opts --o
    file delete $fn 
}

proc getBboxOfVect {vect} {
    ::n-kov::setEquals [v.info $vect -g]
    return "$west $south $east $north"
}

# remove superfluous vertices with angle < a
# nodes are not considered, a - angle in degrees
# return "NumberOfRemovedVertices NewVectorName"
# use v.build.polylines before
proc cleanVertices {vect a} {    
    set fn [::n-kov::getRandFileName .grass.ascii.txt vect_]
    set f [open $fn w]
    set rmVert 0
    foreach l [split [v.out.ascii $vect format=standard l=-1] \n] {
	if {[regexp {^[[:blank:]]*[BL][[:blank:]]+[0-9]+[[:blank:]]*$} $l]} {
	    if {[info exist vertices] && $vertices ne {}} {
		puts $f "$ltype  [llength $vertices]"
		puts $f [join $vertices \n]
	    }
	    set vertices {}
	    set ltype [lindex [string trim $l] 0]
	} elseif {[info exist vertices] && [regexp {^[[:blank:]]*[0-9.]{3,}[[:blank:]]+[0-9.]{3,}[[:blank:]]*$} $l]} {
	    if {[llength $vertices]>1} {
		set v1 [string trim [lindex $vertices end-1]]
		set v2 [string trim [lindex $vertices end]]
		set v3 [string trim $l]
		set a1 [::math::geometry::angle [concat $v1 $v2]]
		set a2 [::math::geometry::angle [concat $v2 $v3]]
		if {[expr {abs($a1-$a2)<$a}]} {
		if {0} {if {[::math::geometry::calculateDistanceToLineSegment $v2 "$v1 $v3"]<=$thre} {}}
		    lset vertices end $l
		    incr rmVert
		} else {
		    lappend vertices $l
		}
	    } else {
		lappend vertices $l
	    }
	} else {
	    if {[info exist vertices] && $vertices ne {}} {
		puts $f "$ltype  [llength $vertices]"
		puts $f [join $vertices \n]
		unset vertices ltype
	    }
	    puts $f $l
	}
    }    
    if {[info exist vertices] && $vertices ne {}} {
	puts $f "$ltype  [llength $vertices]"
	puts $f [join $vertices \n]
	unset vertices ltype
    }		
    close $f
    v.in.ascii in=$fn out=cleanvert_$vect format=standard --o
    file delete $fn
    return "$rmVert cleanvert_$vect"
}
}
