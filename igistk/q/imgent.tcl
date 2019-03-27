
rm screenshot.png; xvfb-run --server-args="-screen 0, 640x360x24" slimerjs-0.10.3/slimerjs slm.js 'https://gsdr.gq/qview.rvt?curlay=0&attr=MCoNco&area=SanDona&layer=OSM.Current&zoom=14&rotate=0&func=avg&sizeattr=wbi'











proc getPVE {table} {
    #set dmin [expr {$maxthre*0.6/5}]
    #set vdmin [expr {$dmin/3.0}]    
    #lassign $limits west east south north bottom top
    lassign [db1 eval "SELECT min(x),max(x),min(y),max(y),min(z),max(z) FROM $table"] west east south north bottom top
    set xdmin [expr {($east-$west)/100.0}]
    set ydmin [expr {($north-$south)/100.0}]
    set zdmin [expr {($top-$bottom)/100.0}]
    set xydmin [::tcl::mathfunc::max $xdmin $ydmin]
    catch {array unset pixels}
    array set pixels {}
    foreach {x y z} [db1 eval "SELECT x,y,z FROM $table"] {
	set px [expr {int(($x-$west)/$xydmin)}]
	set py [expr {int(($y-$south)/$xydmin)}]
	set pz [expr {int(($z-$bottom)/$zdmin)}]
	set pixels($px,$py,$pz) 1
    }
    set octants {west-east south-north bottom-top}
    set octNums {}
    foreach o $octants {
	lassign [split $o -] left right
	switch $left {
	    west  {set dmin $xydmin}
	    south {set dmin $xydmin}
	    top   {set dmin $zdmin}
	}
	lappend octNums  [expr {int(([subst $$right]-[subst $$left])/$dmin)}]
    }
    set indexes "* * *"
    catch {array unset I}    
    array set I {west-east 0 south-north 0 bottom-top 0}
    foreach o $octants {
	set j [lsearch $octants $o]
	set variants ""
	for {set k 0} {$k<[llength $octants]} {incr k} {
	    if {$k != $j} {
		lassign [split [lindex  $octants $k] -] a b
		lappend variants [expr {int(([subst $$b]-[subst $$a])/$dmin)}]
	    }
	}
	set curvar [expr [join $variants *]]
	if {$curvar==0} {return -1}
	set variants [expr [join $variants *]]
	lassign [split $o -] left right
	set maxrow [expr {int(([subst $$right]-[subst $$left])/$dmin)}]
	for {set i 0} {$i<=$maxrow} {incr i} {
	    if {[catch {set ones [llength [array names pixels [join [lreplace $indexes $j $j $i] ,]]]}]} {
		set ones 0
	    }
	    set zeros [expr {$variants-$ones}]
	    foreach cur "$ones $zeros" {
		set I($o) [expr {$I($o)+abs(double($cur)/$variants-0.5)}]
	    }
	}
	;#set I($o) [expr $I($o)/($norm)]
    }
    set retval ""
    foreach n [array names I] {
	lappend retval $I($n)
    }
    return $retval
}
