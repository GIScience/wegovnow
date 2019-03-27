::rivet::headers type "application/json; charset=UTF-8"
proc main {map_keys keys map_vals funcs geompat rq} {
    set killwatch [open "|sh /var/www/killdelay.sh [pid]"]
    if {[regexp {^[[:alnum:]_ ,.{}]+$} $rq]} {
	set sql {}
	foreach {k v} $rq {
	    set v [string map {{ } ..SPACE..} $v]
	    if {$k eq "SQL"} {
		puts $sql
		::rivet::exit
	    }
	    if {[regexp {^\w+$} $k] && [regexp {^[[:alnum:]_,.{} ]*$} $v]} {
		set k [string map $map_keys $k]
		if {[lsearch -exact $keys $k]>=0} {
		    set sql "$sql $k"
		} else {
		    "ERROR! Wrong k (is not apeared in the keys list):'$k'"

		}
		set lst {}
		set pref ""
		foreach el [split $v ,] {
		    set el [string map $map_vals $el]
		    if {$el eq ")"} {
			append lst ")"
			set pref ""
		    } elseif {[string match {__*} $el]} {
			set el [string trim $el _]
			if {[lsearch -exact $funcs $el]>=0} {
			    append pref "${el}("
			} else {
			    error "ERROR! Wrong el: el='$el'"
			}
		    } else {
			append lst " $pref$el"
			set pref ""
		    }
		}		
		if {$lst ne {}} {
		    set joined_lst [join $lst ,]		    
		    set sql "$sql [string map {..SPACE.. { }} $joined_lst]"
		}
	    } else {
		error "ERROR! Wrong k or v: k='$k';v='$v'"
	    }
	}
    } else {
	error "ERROR! Wrong request: $rq"
    }
    #set f [open /tmp/delme.txt w]
    #puts $f "$sql"
    #close $f
    #puts $sql
    #puts <br><br>
    sdb eval $sql vals {break}
    array set names {}
    foreach v $vals(*) {
	set names($v) [string trim [regsub -all {\W+} $v _] _]

    }



    sdb eval $sql vals {break}
    array set names {}
    foreach v $vals(*) {
	set names($v) [string trim [regsub -all {\W+} $v _] _]

    }
    foreach pat $geompat {
	if {[llength [array names names $pat]] eq 1} {
	    set geokey $pat
	    break
	}

    }
    puts "\{ \"type\": \"FeatureCollection\","
    if {[info exists geokey]} {
	puts "\"crs\": \{
  \"type\":\"name\",
  \"properties\":\{
      \"name\":\"EPSG:4326\"
    \}
\},"
    }
    puts "\"features\": \["
    set first 1
    sdb eval $sql vals {
	if {!$first} {
	    puts ","
	} else {
	    set first 0
	}
	puts "\{ \"type\": \"Feature\","
	if {[info exists names(id)]} {
	    if {[string is double $vals(id)]} {
		puts  "\"id\": $vals(id),"
	    } else {
		puts  "\"id\": \"$vals(id)\","
	    }
	}
	if {[info exists geokey]} {
	    puts -nonewline "\"geometry\": $vals([array names names $geokey]),"
	}
	puts "\"properties\": \{"
	set firstprop 1
	foreach n [array names names] {
	    if {$n ne {id} && [expr {![info exists geokey] || ![string match $geokey $n]}]} {
		if {!$firstprop} {
		    puts ", "
		} else {
		    set firstprop 0
		}
		if {[string is double $vals($n)] && $n ne {q} && $n ne {tiles.q}} {
		    puts -nonewline "\"$names($n)\": $vals($n)"
		} else {
		    puts -nonewline "\"$names($n)\": \"$vals($n)\""
		}
	    }
	}
	puts -nonewline "\}\}"

    }
    puts "\n\]\n\}"
    exec kill -9 [pid $killwatch]
    catch {exec kill -9 [pid $killwatch]}
    catch {close $killwatch}
}
main $map_keys $keys $map_vals $funcs $geompat [::rivet::var all]
