
####################################################################
#  
#     A library:  nkovcom/LibsAndTools/n-kov.tcl
#
####################################################################
#   
#   (c) Alexey Noskov (http://a.n-kov.com). 
#   Last updated: 2017/08/17 14:32:25
#
####################################################################
#
# A general purpose tcl library
#
package provide n-kov 1.5
package require fileutil
package require json::write
namespace eval n-kov {

# a checkpoint-based profiler http://wiki.tcl.tk/21331
proc profiler {id} {
        global db_t
        global db_c
        array set db_t {}
        array set db_c {}
        global last
        switch -- $id {
                start {
                        set last [clock microseconds]
                }
                end {
                        set k [array names db_t]
                        puts [format {%-12s %s} {checkpoint:} {avgtime:}]
                        foreach ik $k {
                                puts [format {%-12s %.1f} $ik [expr {1.0*$db_t($ik)/$db_c($ik)}]]
                        }
                        array unset db_t
                        array unset db_c
                }
                default {
                        set delta [expr {[clock microseconds]-$last}]
                        set last [clock microseconds]
                        if {[info exists db_t($id)]} {incr db_t($id) $delta} {set db_t($id) $delta}
                        if {[info exists db_c($id)]} {incr db_c($id) 1     } {set db_c($id) 1     }
                }
        }
 }

    
#eval ${::n-kov::breakpoint} ;#http://wiki.tcl.tk/24690
set breakpoint {set prompt "%dbg%"
    set script {}
    while 1 {
	puts -nonewline $prompt
	flush stdout
	gets stdin line        ;# read...
	if {$line eq ";;"}  {
	    catch [join $script \n] res ;# eval...
	    set script {}
	    puts $res ;# print
	} elseif {$line eq "c"} {
	    break
	} else {
	    lappend script $line
	}
    }
}
    
set errorHeader "ERROR! Message:"



#http://wiki.tcl.tk/367#pagetoca965cf5d
# USAGE: fforeach aLine "./mybigfile.txt" {puts $aLine}
proc fforeach {fforeach_line_ref fforeach_file_path fforeach_body} {
    upvar $fforeach_line_ref fforeach_line
        set fforeach_fid [open $fforeach_file_path r]
    fconfigure $fforeach_fid -encoding utf-8
    while {[gets $fforeach_fid fforeach_line] >= 0} {
        # ------- FOREACH BODY ------------<
            uplevel $fforeach_body
        # ------END FOREACH BODY----------->
    }          
        close $fforeach_fid
 }


#http://wiki.tcl.tk/819#pagetoc9326db77
proc average L {
    expr ([join $L +])/[llength $L].
}

proc randomColor {} {
    format #%06x [expr {int(rand() * 0xFFFFFF)}]
}

proc Lpick L {
    lindex $L [expr {int(rand()*[llength $L])}]
}
proc RandomlyPicked {length {chars {A B C D E F G H I G K L M N O P Q R S T U V W X Y Z 0 1 2 3 4 5 6 7 8 9}} } {
    for {set i 0} {$i<$length} {incr i} {append res [Lpick $chars]}
    return $res
}


proc getRandFileName {{ext {}} {prefix {tmp_n-kov_}} {path /tmp}} {
    if {$path eq "/tmp"} {
	set tmpdir [::fileutil::tempdir]
    }
    while {1} {
	set curRand [RandomlyPicked 6]
	set retfn [file join $path $prefix$curRand$ext]	
	if {![file exist $retfn]} {	    
	    return $retfn
	}	
    }    
}
#processes  a=b in Tcl's manner (i.e., evaluates set a b)
proc setEquals {equals} {
    foreach el $equals {
	lassign [split $el =] p v
	uplevel "set $p $v"
    }
}


proc sleep {time} {
      after $time set end 1
      vwait end
  }



#From http://wiki.tcl.tk/16154
#=============================================================================
# PROC    : baseconvert
# PURPOSE : convert number in one base to another base
# AUTHOR  : Richard Booth
# DATE    : Fri Jul 14 10:40:50 EDT 2006
# ---------------------------------------------------------------------------
# ARGUMENTS :
#   % base_from
#       original base (expressed in base 10)
#   % base_to
#       base to convert number to (expressed in base 10)
#   % number
#       number expressed in base_from (must have form int.fra, int, or .fra)
# RESULTS :
#   * returns number expressed in base_to
# EXAMPLE-CALL :
#{
#  set num16 [baseconvert 10 16 3.1415926535]
#}
#=============================================================================
proc baseconvert {base_from base_to number} {
     set number [string tolower $number]
     if {![regexp {([0-9a-z]*)\.?([0-9a-z]*)} $number match sint sfra]} {
         puts "baseconvert error: number \"$number\" is not in correct format"
         return ""
     }
     set map 0123456789abcdefghijklmnopqrstuvwxyz
     set i -1
     foreach c [split $map ""] {
         incr i
         set D2I($c) $i
         set I2D($i) $c
     }
     set lint [string length $sint]
     set lfra [string length $sfra]
     set converted_number 0
     if {$lint > 0} {
         set B {}
         foreach c [split $sint ""] {
             lappend B $D2I($c)
         }
         set aint ""
         while {1} {
             set s 0
             set r 0
             set C {}
             foreach b $B {
                 set v [expr {$b + $r*$base_from}]
                 set b [expr {$v/$base_to}]
                 set r [expr {$v%$base_to}]
                 incr s $b
                 lappend C $b
             }
             set B $C
             set aint "$I2D($r)$aint"
             if {$s == 0} {break}
         }
         set converted_number $aint
     }
     if {$lfra > 0} {
         set s [expr {int(1.0*$lfra*log($base_from)/log($base_to))}]
         set B {}
         foreach c [split $sfra ""] {
             set B [linsert $B 0 $D2I($c)]
         }
         set afra ""
         for {set j 0} {$j < $s} {incr j} {
             set r 0
             set C {}
             foreach b $B {
                 set v [expr {$base_to*$b + $r}]
                 set r [expr {$v/$base_from}]
                 set b [expr {$v%$base_from}]
                 lappend C $b
             }
             set B $C
             set afra "$I2D($r)$afra"
         }
         append converted_number .$afra
     }
     return $converted_number
}



proc base {base number} {
    set negative [regexp ^-(.+) $number -> number] ;# (1)
    set digits {0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N
        O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p
        q r s t u v w x y z}
    set res {}
    while {$number} {
        set digit [expr {$number % $base}]
        set res [lindex $digits $digit]$res
        set number [expr {$number / $base}]
    }
    if $negative {set res -$res}
    set res
}


proc frombase {base number} {
    set digits {0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N
        O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p
        q r s t u v w x y z}
    set negative [regexp ^-(.+) $number -> number]
    set res 0
    foreach digit [split $number ""] {
        set decimalvalue [lsearch $digits $digit]
        if {$decimalvalue<0 || $decimalvalue >= $base} {
            error "bad digit $decimalvalue for base $base"
        }
        set res [expr {$res*$base + $decimalvalue}]
    }
    if $negative {set res -$res}
    set res
}

proc tcl2json value {
    # Guess the type of the value; deep *UNSUPPORTED* magic!
    regexp {^value is a (.*?) with a refcount} \
	[::tcl::unsupported::representation $value] -> type
 
    switch $type {
	string {
	    return [json::write string $value]
	}
	dict {
	    return [json::write object {*}[
		dict map {k v} $value {tcl2json $v}]]
	}
	list {
	    return [json::write array {*}[lmap v $value {tcl2json $v}]]
	}
	int - double {
	    return [expr {$value}]
	}
	booleanString {
	    return [expr {$value ? "true" : "false"}]
	}
	default {
	    # Some other type; do some guessing...
	    if {$value eq "null"} {
		# Tcl has *no* null value at all; empty strings are semantically
		# different and absent variables aren't values. So cheat!
		return $value
	    } elseif {[string is integer -strict $value]} {
		return [expr {$value}]
	    } elseif {[string is double -strict $value]} {
		return [expr {$value}]
	    } elseif {[string is boolean -strict $value]} {
		return [expr {$value ? "true" : "false"}]
	    }
	    return [json::write string $value]
	}
    }
}


}


namespace eval n-kov::geom {

package require math::geometry   

proc bboxGeomIntersect {bbox geom} {
    lassign [::math::geometry::bbox $geom] bx1 by1 bx2 by2
    lassign $bbox bbx1 bby1 bbx2 bby2
    if {[::math::geometry::rectanglesOverlap  "$bx1 $by1" "$bx2 $by2" "$bbx1 $bby1" "$bbx2 $bby2" 1]} {
	return 1
    } else { return 0}    
}    


proc selectByGeomBbox {sequence geom {buffer 0} {k 1}} {
    ;#set bbox ""
    foreach val [::math::geometry::bbox $geom] sign {- - + +} {
	lappend bbox [expr $val$sign$buffer]
    }
    ;#set outseq ""
    for {set i 0} {$i<[llength $sequence]} {incr i $k} {
	set cur_geom [lrange $sequence $i [expr {$i+$k-1}]]
	if {$k == 1} {
	    set cur_geom [lindex $cur_geom 0]
	}
	if {[bboxGeomIntersect $bbox $cur_geom]} {
	    lappend outseq $cur_geom
	}
    }
    if {![info exist outseq]} {
	return {}
    } else {
	return $outseq
    }
}

proc getBbox {points {buf 0}} {
    set dim [llength [lindex $points 0]]
    lassign {{} {} {} {} {} {}} west east south north bottom top
    foreach p $points {
	switch $dim {
	    1 {set x $p}
	    2 {lassign $p x y}
	    3 {lassign $p x y z}
	    default {error "Error! 1,2,3 sizes of elements are only allowed."}
	}
	if {$west eq {} || $x<$west} {
	    set west $x
	}	    
	if {$east eq {} || $x>$east} {
	    set east $x
	}
	if { $dim > 1 } {
	    if {$south eq {} || $y<$south} {
		set south $y
	    }
	    if {$north eq {} || $y>$north} {
		set north $y
	    }
            if { $dim > 2 } {
		if {$bottom eq {} || $z<$bottom} {
		    set bottom $z
		}
		if {$top eq {} || $z>$top} {
		    set top $z
		}
	    }
	}
    }
    foreach {a b} {west east south north bottom top} {
	if {[subst $$a] ne {} && [subst $$b] ne {}} {
	    set $a [expr {[subst $$a]-$buf}]	    
	    set $b [expr {[subst $$b]+$buf}]
	}
    }
    switch $dim {
	1 {return "$west $east"}
	2 {return "$west $south $east $north"}
	3 {return "$west $south $bottom $east $north $top"}
    }
}
}
# 

