#/bin/sh
#\
exec tclsh "$0" "$@"

# Calculates general stats of OSM data including history dump
# (c) Alexey Noskov, Adam Rousell, and  Nikos Papapessios; 2018
#  http://n-kov.com

# this file contains SQL code prepared by Nikos Papapessios
# this file contains HTML/CSS and JavaScript code prepared my Adam Rousell (https://www.geog.uni-heidelberg.de/gis/rousell_en.html)


package require n-kov
package require sqlite3



#eval [set ::n-kov::breakpoint]

# set arg "San Donà di Piave,sandona.osh.sqlite:Turin,turin.osh.sqlite:Southwark,southwark.osh.sqlite:Heidelberg,hd.osh.sqlite"
# set arg "sandona.poly,turin.poly,southwark.poly,hd.poly"


set USAGE "
 usage(1): [info script] -i name1,filename1.osh.sqlite:...:nameN,filenameN.osh.sqlite -n file1.poly,...,fileN.poly -o output_file.html 
        
    -i   -  input data: area names and *.osh.sqlite files;

    -n   -  normalize results using the length of a boundary 
            of a areas' convex hull (areas were used for clipping 
            OSM full-history dump), number of *.poly file must 
            correspond to the number of files in the \"-i\" parameter,
            libspatialite module should be installed;

    -o   -  output HTML file; 

 Examples:

     [info script] -i \"San Donà di Piave,sandona.osh.sqlite:Turin,turin.osh.sqlite:Southwark,southwark.osh.sqlite:Heidelberg,hd.osh.sqlite\" -n sandona.poly,turin.poly,southwark.poly,hd.poly -o /tmp/intrwgn.html
"

set steps 2

foreach arg $::argv {
    if {[string index $arg 0] eq "-"} {
	set curcom $arg
	continue
    }
    switch $curcom {
	"-i" {
	    set indata {}
	    foreach el [split $arg :] {
		foreach {areaname filename} [split $el ,] {
		    lappend indata $areaname
		    lappend indata $filename
		}
	    }
	}
	"-n" {
	    set polyfiles {}
	    foreach el [split $arg ,] {
		foreach {polyfile} [split $el ,] {
		    lappend  polyfiles $polyfile
		}
	    }
	}
	"-o" {
	    set outhtml $arg
	}
    }	
}

if {![info exists indata] || ![info exists outhtml]} {
    error "[set ::n-kov::errorHeader] -i  input data AND -o output_file.html have to be specified \n$::USAGE"
}

if {[info exists polyfiles] && [llength $polyfiles] ne [expr {[llength $indata]/2}]} {
    error "[set ::n-kov::errorHeader] -n   number of *.poly files is wrond \n$::USAGE"
}



proc putsprg {curstep maxsteps cursubtask maxsubtask} {
    puts "\[[clock format [clock seconds] -format {%T %D}]\]: Step $curstep of $maxsteps, subtask $cursubtask of $maxsubtask..."
}

#type -> vbar hbar shbar svbar line dough sarea
proc getD3Data {type title names data {labels {_}} {normlist {}}} {    
    set lablist {}
    set intlabs {}
    if {[lsearch "hbar shbar svbar " $type] > -1} {
	set intlabs $labels
	foreach cur $names {
	    lappend lablist "'$cur' "
	}
	if {[llength $normlist]>0} {
	    for {set i 0} {$i<[llength $data]} {incr i} {
		for {set j 0} {$j<[llength [lindex $data $i]]} {incr j} {
		    lset data $i $j [expr {[lindex [lindex $data $i] $j]/[lindex $normlist $j]}]
		}
	    }
	}
    } else {
	set intlabs $names
	foreach cur $labels {	    
	    lappend lablist "'$cur'"
	}
	if {[llength $normlist]>0} {
	    for {set i 0} {$i<[llength $data]} {incr i} {
		for {set j 0} {$j<[llength [lindex $data $i]]} {incr j} {
		    lset data $i $j [expr {[lindex [lindex $data $i] $j]/[lindex $normlist $i]}]
		}
	    }
	}
    }    
    array set types {vbar VerticalBar hbar HorizontalBar shbar StackedHorizontalBar svbar StackedVerticalBar line Line dough Doughnut}
    set jsdata "\{	
		title: '$title',
		chartType: '$types($type)',
		holder: 'versionsHolder',
		labels: \[[join $lablist ,]\],
		data: \["

    

    
    set curlist {}
    for {set i 0} {$i < [llength $intlabs]} {incr i} {
	switch $type {
	    "line" -
	    "shbar" -
	    "svbar" -
	    "vbar" {
		lappend curlist "\{label: '[lindex $intlabs $i]',data: \[[join [lindex $data $i] ,]\],style: \{color: colors\[$i\]\}\}"
	    }
	    "dough" -
	    "hbar" {
		if {$type eq "dough" && $i>0} {
		    break
		}
		set colors {}
		for {set j 0} {$j<[llength [lindex $data 0]]} {incr j} {
		    lappend colors "colors\[$j\]"
		}
		lappend curlist "\{data: \[[join [lindex $data 0] ,]\],style: \{color: \[[join $colors ,]\]\}\}"
	    }
	}
    }
    append jsdata "\n[join $curlist ,]\]\}"
    return $jsdata
}

# set sql_session_id {}
# set sql_rownum 0
# proc getrowid {s_id {maxval {}}} {
#     if {$s_id ne $::sql_session_id} {
# 	set ::sql_rownum 0
# 	set ::sql_session_id $s_id
#     }
#     if {$maxval ne {} && $::sql_rownum >= $maxval} {
# 	return $maxval
#     } else {	
# 	return [incr ::sql_rownum]
#     }
# }

set dbs ""
foreach {_ curfile} $indata {
    set dbname [n-kov::RandomlyPicked 10]
    lappend dbs $dbname
    if {![file exists $curfile]} {error "File $curfile does not exist! \n$::USAGE"}
    sqlite3 $dbname $curfile
    $dbname function getrowid getrowid
}
set minyears ""
set maxyears ""
set numdbs [llength $dbs]
set curtask 0
foreach db $dbs {
    putsprg 1 $steps [incr curtask] $numdbs
    set cur_minmax [$db eval {select min(strftime('%Y', datetime(timestamp, 'unixepoch'))),max(strftime('%Y', datetime(timestamp, 'unixepoch')))  from elements}]
    lappend minyears [lindex $cur_minmax 0]
    lappend maxyears [lindex $cur_minmax 1]	
}
set ymin [::tcl::mathfunc::min {*}$minyears]
set ymax [expr {[::tcl::mathfunc::max {*}$maxyears]-1}]
set years ""
for {set i $ymin} {$i<=$ymax} {incr i} {
    lappend years $i
}

set names ""
foreach {name _} $indata {
	lappend names $name
}

if {[info exists polyfiles]} {
    sqlite3 sdb :memory:
    sdb enable_load_extension true
    sdb eval "SELECT load_extension('mod_spatialite.so');SELECT InitSpatialMetaData()"
    set norms {}
    foreach polyfile $polyfiles {
	set pf [open $polyfile]
	set wkt "POLYGON (("
	set coorlist {}
	foreach line [split [read $pf] \n] {
	    if {[llength $line] eq 2 && [string is double [lindex $line 0]] && [string is double [lindex $line 1]]} {
		lappend coorlist "[expr [lindex $line 0]] [expr [lindex $line 1]]"	    
	    }
	}
	append wkt "[join $coorlist ,]))"
	close $pf    
	lappend norms [sdb eval "SELECT CastToInteger(Perimeter(ConvexHull(GeomFromText('$wkt')),1)/1000)"]	
    }
}


set totalcontrs {}
set contrsyear {}
set ver5contrs {}
set usersactivity {}
set usersactivity_labels {}
set featuresversion {}
set curtask 0
set sql_ts2y "strftime('%Y', datetime(timestamp, 'unixepoch'))"
for {set i 0} {$i<$numdbs} {incr i} {
    lappend totalcontrs [[lindex $dbs $i] eval {SELECT count(id) FROM users}]
    putsprg 2 $steps [incr curtask] $numdbs
    catch {array unset curdata}
    foreach y $years {
	set curdata($y) 0
    }
    foreach {y v} [[lindex $dbs $i] eval "SELECT $sql_ts2y,count(*) FROM elements GROUP BY $sql_ts2y"] {
	set curdata($y) $v
    }
    set curdatalist {}
    foreach y $years {
	lappend curdatalist $curdata($y)
    }
    lappend contrsyear $curdatalist
    lappend ver5contrs [[lindex $dbs $i] eval {SELECT SUM(CASE WHEN cnt>6 AND cnt<11 THEN 1 ELSE 0 END),SUM(CASE WHEN cnt>10 AND cnt<101 THEN 1 ELSE 0 END),SUM(CASE WHEN cnt>101 THEN 1 ELSE 0 END) FROM (SELECT count(uid) as cnt FROM elements JOIN users ON users.id=elements.uid WHERE version > 5 GROUP BY uid HAVING count(uid) > 5)}]

    set cur_ua [[lindex $dbs $i] eval {SELECT name, count(uid) FROM users JOIN elements ON elements.uid = users.id GROUP BY uid ORDER BY count(uid) DESC LIMIT 10}]
    lappend cur_ua others [expr {[[lindex $dbs $i] eval {SELECT count(uid) FROM users JOIN elements ON elements.uid = users.id}]-[[lindex $dbs $i] eval {SELECT SUM(cnt) FROM (SELECT count(uid) AS cnt FROM users JOIN elements ON elements.uid = users.id GROUP BY uid ORDER BY count(uid) DESC LIMIT 10)}]}]
    set cur_ua_labels {}
    set cur_ua_data {}
    foreach {name count} $cur_ua {
	lappend cur_ua_labels $name
	lappend cur_ua_data $count
    }
    lappend usersactivity_labels $cur_ua_labels
    lappend usersactivity $cur_ua_data
    
    lappend featuresversion [[lindex $dbs $i] eval {SELECT
sum( case when version = 1 then 1 else 0 end ) as version1,
sum( case when version = 2 then 1 else 0 end ) as version2,
sum( case when version = 3 then 1 else 0 end ) as version3,
sum( case when version = 4 then 1 else 0 end ) as version4,
sum( case when version = 5 then 1 else 0 end ) as version5,
sum( case when version between 6 and 10 then 1 else 0 end ) as version6to10,
sum( case when version >10 then 1 else 0 end ) as version11plus
from elements}]    
}
array unset curdata

set out_ver5contrs {}
set li [llength $ver5contrs]
set lj [llength [lindex $ver5contrs 0]]
for {set vj 0} {$vj < $lj} {incr vj} {
    set curlist {}
    for {set vi 0} {$vi < $li} {incr vi} {
	lappend curlist [lindex [lindex $ver5contrs $vi] $vj]
    }
    lappend out_ver5contrs $curlist
}



set doughnutdata {}
foreach cur_ua $usersactivity cur_ual $usersactivity_labels name $names {
    lappend doughnutdata [getD3Data dough "Most active users in $name" $names [list $cur_ua] $cur_ual]
}


# set jsdata_contryears {};
# foreach name $names {
#     lappend jsdata_contryears "\{
# 		    label: '$name',
# 		    data: \[[join [lindex $data($name) 0] ,]\],
# 		    style: \{
# 		    	color: colors\[[lsearch $names $name]\]
# 		    \}
# \}"
#     lappend jsdata_contryears "\{
# 		    label: '$name',
# 		    data: \[[join [lindex $data($name) 0] ,]\],
# 		    style: \{
# 		    	color: colors\[[lsearch $names $name]\]
# 		    \}
# \}"
#}
# set jsdata_contryears_NORM {};
# foreach name $names {
#     set curdata {}
#     for {set i 0} {$i < [llength [lindex $data($name) 0]]} {incr i} {
# 	lappend curdata [expr {[lindex [lindex $data($name) 0] $i]/[lindex $norms [lsearch $names $name]]}]
#     }
#     lappend jsdata_contryears_NORM "\{
# 		    label: '$name',
# 		    data: \[[join $curdata ,]\],
# 		    style: \{
# 		    	color: colors\[[lsearch $names $name]\]
# 		    \}
# \}"
# }


# set colors_string {}
# for {set i 0} {$i<200} {incr i} {
#     lappend colors_string "colors\[$i\]"
# }
# set jsdata_allcontribs "\{
# 				data: \[[join $totalcontrs ,]\],
# 				style: \{
# 					color: \[[join $colors_string ,]\]
# 				\}
# 			\}"

# set totalcontrs_NORM {}
# for {set i 0} {$i<[llength $names]} {incr i} {
#     lappend totalcontrs_NORM [expr {[lindex $totalcontrs $i]/[lindex $norms $i]}]
# }
# set jsdata_allcontribs_NORM "\{
# 				data: \[[join $totalcontrs_NORM ,]\],
# 				style: \{
# 					color: \[[join $colors_string ,]\]
# 				\}
# 			\}"

set f [open $outhtml w+]    
puts $f "<html>
	<head> 
 <meta http-equiv='X-UA-Compatible' content='IE=edge'/>
 <meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
 <meta name='viewport' content='width=device-width, initial-scale=1.0'>
        <style>
                body \{
         	        background-color: #EEEEEE;
	                font-family: Helvetica,Arial,sans-serif;\}
		.chart \{
			width: 800px;
			height: 500px;
		\}

		.chart-title \{
			font-weight: bold;
			font-size: 16pt;
		\}
</style>
		<script src=\"https://d3js.org/d3.v5.min.js\"></script>
		<script src=\"https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.2/Chart.bundle.js\"></script>
                <script>
        function addCharts() \{
		var chartHolder = d3.select('#chart-holder');

		for(var i=0; i<data2.length; i++) \{
			var chartData = data2\[i\];
			constructChart(chartHolder, chartData);
	\};
\}

       function constructChart(chartHolder, chartData) \{
		var title = chartData.title;

		// Look to see if there was aholder passed
		var chartDiv = null;
		if(chartData\['holder'\] != null) \{
			chartDiv = d3.select('#'+chartData\['holder'\]);
		\}
		if(chartDiv == null || chartDiv.empty()) \{
			// We add the chart to the holder div
			chartDiv = chartHolder.append('div');
			chartDiv.classed('chart', true);
		\} 

		var chartTitle = chartDiv.append('div').classed('chart-title', true).text(title);
		var chartCanvas = chartDiv.append('canvas');
		var canvasId = title.replace(/\[^A-Z0-9\]/ig, '') + '-chart';
		chartCanvas.attr('id', canvasId);

		updateChart(chartData, canvasId);
	\};

	function updateChart(chartData, chartId) \{
		var ctx = document.getElementById(chartId);
		switch(chartData.chartType) \{
			case 'StackedVerticalBar': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
					entry\['backgroundColor'\] = entry.style.color;
				\});
				var chart = new Chart(ctx, \{
					type: 'bar',
					data: \{
						labels: chartData.labels,
						datasets: filledData
					\},
					options: \{
						scales: \{
							xAxes: \[\{ stacked: true \}\],
							yAxes: \[\{ stacked: true \}\]
						\}
					\}
				\});
			break;
			case 'StackedHorizontalBar': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
					entry\['backgroundColor'\] = entry.style.color;
				\});
				var chart = new Chart(ctx, \{
					type: 'horizontalBar',
					data: \{
						labels: chartData.labels,
						datasets: filledData
					\},
					options: \{
						scales: \{
							xAxes: \[\{ stacked: true \}\],
							yAxes: \[\{ stacked: true \}\]
						\}
					\}
				\});
			break;
			case 'VerticalBar': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
					entry\['backgroundColor'\] = entry.style.color;
				\});
				var chart = new Chart(ctx, \{
					type: 'bar',
					data: \{
						labels: chartData.labels,
						datasets: filledData
					\}
				\});
			break;
			case 'HorizontalBar': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
					entry\['backgroundColor'\] = entry.style.color;
				\});
				var chart = new Chart(ctx, \{
					type: 'horizontalBar',
					data: \{
						labels: chartData.labels,
						datasets: filledData
					\},
					options: constructOptions(chartData, \{\})
				\});
			break;
			case 'Line': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
						entry\['borderColor'\] = entry.style.color;
						entry\['lineTension'\] = 0;
						entry\['fill'\] = false;
						entry\['pointRadius'\] = 0;
					\});
				var chart = new Chart(ctx, \{
					type: 'line',
					data: \{
						labels: chartData.labels,
						datasets: chartData.data
					\}
				\});
			break;
			case 'FilledLine': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
						entry\['backgroundColor'\] = addTransparency(entry.style.color);
						entry\['borderColor'\] = entry.style.color;
						entry\['lineTension'\] = 0;
						entry\['pointRadius'\] = 0;
					\});
				var chart = new Chart(ctx, \{
					type: 'line',
					data: \{
						labels: chartData.labels,
						datasets: filledData
					\}
				\});
			break;
			case 'Pie': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
					entry\['backgroundColor'\] = entry.style.color;
				\});
				var chart = new Chart(ctx, \{
					type: 'pie',
					data: \{
						datasets: filledData,
						labels: chartData.labels
					\}
				\});
				break;
			case 'Doughnut': 
				var filledData = chartData.data;
				filledData.forEach(function(entry) \{
					entry\['backgroundColor'\] = entry.style.color;
				\});
				var chart = new Chart(ctx, \{
					type: 'doughnut',
					data: \{
						datasets: filledData,
						labels: chartData.labels
					\}
				\});
				break;
		\}
	\};

	function constructOptions(chartData, defaultOptions) \{
		var data = chartData.data;
		if(data.length == 1) \{
			defaultOptions\['legend'\] = \{display: false\};
		\} 		

		if(chartData\['startAtZero'\] == true) \{
			var valueAxis = 'yAxes';
			if(chartData.chartType == 'HorizontalBar' || chartData.chartType == 'StackedHorizontalBar')
				valueAxis = 'xAxes';

			if(defaultOptions\['scales'\] == null) \{
				defaultOptions\['scales'\] = \{\};
			\}
			if(defaultOptions\['scales'\]\[valueAxis\] == null) \{
				defaultOptions\['scales'\]\[valueAxis\] = \[\];
			\}
			if(defaultOptions\['scales'\]\[valueAxis\]\[0\] == null) \{
				defaultOptions\['scales'\]\[valueAxis\]\[0\] = \{\};
			\}
			if(defaultOptions\['scales'\]\[valueAxis\]\[0\]\['ticks'\] == null) \{
				defaultOptions\['scales'\]\[valueAxis\]\[0\]\['ticks'\] = \{\};
			\}
			defaultOptions\['scales'\]\[valueAxis\]\[0\]\['ticks'\]\['beginAtZero'\] = true;
		\}
		return defaultOptions;
	\}

	function addTransparency(colorIn) \{
		return colorIn + '55';
	\};

        var colors = \[
[set colors {};for {set k 0} {$k<100} {incr k} {lappend colors '[string toupper [n-kov::randomColor]]',};set colors]
\];
var data2 = \[[join [list [getD3Data hbar {Total number of contributors} $names [list $totalcontrs] {_}]\
      [getD3Data hbar {Normalized total number of contributors} $names [list $totalcontrs] {_} $norms]\
      [getD3Data line {Number of contributions per year} $names $contrsyear $years]\
	  [getD3Data line {Normalized number of contributions per year} $names $contrsyear $years $norms]\
	  [getD3Data svbar {Number of the contribution per user who has more than five versions and contributions} $names $out_ver5contrs [list 6-10 11-100 >100]]\
	  [getD3Data svbar {Normalized number of the contribution per user who has more than five versions and contributions} $names $out_ver5contrs [list 6-10 11-100 >100] $norms]\
      [getD3Data vbar {Versions of features} $names $featuresversion [list 1 2 3 4 5 6-10 >10]]\
	  [getD3Data vbar {Normalized versions of features} $names $featuresversion [list 1 2 3 4 5 6-10 >10] $norms]\
	  {*}$doughnutdata      
		    ] ,]\];
</script>
	</head>
	<body>
		<div id=\"chart-holder\"></div>
		<div id=\"versionsHolder\"></div>
		<script>
			addCharts();

		</script>
	</body>
</html>
"

foreach db $dbs {
 $db close
}
close $f
puts DONE!

if 0 {
    var colors = [
'#3EBB8B', '#8AF45A', '#B06981', '#DEEC35', '#65F3A0', '#5DC789', '#D722BE', '#2A323C', '#480F95', '#F74C46', '#B0F4E4', '#9E02F2', '#D3C1AF', '#5113FB', '#F6DE0E', '#6CB2F8', '#5A05F5', '#3D5DC2', '#D693AE', '#79D5F9', '#CF1D26', '#82F285', '#0047FC', '#7610AD', '#40FDCA', '#D6135F', '#920827', '#5589C5', '#C828E5', '#F52E14', '#A49FA8', '#EE305F', '#AA0420', '#F53DF2', '#B650CF', '#73AC77', '#4003BE', '#B5E469', '#A70D5C', '#5E6F28', '#D3FB4B', '#173870', '#7A4E71', '#B41353', '#60F1B1', '#9BEF42', '#793126', '#89F186', '#4FF72A', '#EC389E', '#7980F2', '#00BEC9', '#ED8132', '#BD4914', '#08F0A3', '#EE8D0B', '#6E4B50', '#12B30F', '#A9C343', '#529A6A', '#17BD6B', '#94E8FB', '#4BF7A9', '#70AAA9', '#D47352', '#DF8158', '#A502B5', '#551C65', '#BB47C6', '#6588DD', '#FC98A8', '#8AA324', '#DCB6B6', '#5FD364', '#2F6ABD', '#08B4F4', '#A02EE3', '#666DB7', '#AD5A9F', '#18A92E', '#0B12C0', '#FC09A1', '#DC7884', '#6C7082', '#4EC251', '#B78BE6', '#42128D', '#D00E9A', '#6EF918', '#A3E038', '#D5DE4F', '#F65282', '#A3275C', '#6D50A2', '#C8FF99', '#04EA54', '#B434E8', '#FDAA46', '#B642CD', '#DBF3AB',
];
}
