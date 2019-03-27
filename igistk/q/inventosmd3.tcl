#/bin/sh
#\
exec tclsh "$0" "$@"

# Calculates general stats of raw OSM data, produces D3 graphs
# (c) Alexey Noskov and  Adam Rousell; 2018
#  http://n-kov.com
# this file contains HTML/CSS and JavaScript code prepared my Adam Rousell (https://www.geog.uni-heidelberg.de/gis/rousell_en.html)

package require n-kov

#eval [set ::n-kov::breakpoint]
# set arg "sandona_linestats.txt,turin_linestats.txt,southwark_linestats.txt,hd_linestats.txt,israel_linestats.txt"
# set arg "sandona_tagstats.txt,turin_tagstats.txt,southwark_tagstats.txt,hd_tagstats.txt,israel_tagstats.txt"
# set arg "SD,TR,SW,HD,IS"
# set arg "San Donà di Piave; di Piave,Turin,Southwark,Heidelberg,Israel"

proc commas {var {num 3} {char ,}} {
    set len   [string length $var]
    set first [expr $len - $num]
    set x     {}
    while {$len > 0} {
        # grab left num chars
        set lef [string range $var $first end] 
        if {[string length $x] > 0} {
            set x   "${lef}$char${x}"
        } else {
            set x   $lef
        }
        # grab everything except left num chars
        set var [string range  $var 0 [expr $first -1]]
        set len   [string length $var]
        set first [expr {$len - $num}]
    }
    return $x
}
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

set USAGE "
 usage(1): [info script] \[-l filename1_linestats.txt,...,filenameN_linestats.txt -t filename1_tagstats.txt,...,filenameN_tagstats.txt\] -o output_file.html []

    -l   -  input line stats data *_linestats.txt files;

    -t   -  input line stats data *_tagstats.txt files;
   
         Warning! At least one -l or -t has to be defined.

    -n   -  (optional) names of areas to be used in output 
            HTML file (optional);

         Warning! Number of elements (separated by comma) provided
         in -l -t -n has to be equal

    -o   -  output HTML file; 

 Examples:

     [info script] -l sandona_linestats.txt,turin_linestats.txt,southwark_linestats.txt,hd_linestats.txt,israel_linestats.txt -t sandona_tagstats.txt,turin_tagstats.txt,southwark_tagstats.txt,hd_tagstats.txt,israel_tagstats.txt -o /tmp/intrwgn.html
"

foreach arg $::argv {
    if {[string index $arg 0] eq "-"} {
	set curcom $arg
	continue
    }
    switch $curcom {
	"-l" {
	    set ldata {}
	    foreach el [split $arg ,] {
		lappend ldata $el
	    }
	}
	"-t" {
	    set tdata {}
	    foreach el [split $arg ,] {
		lappend tdata $el
	    }
	}
	"-n" {
	    set names {}
	    foreach el [split $arg ,] {
		lappend names $el
	    }
	}
	"-o" {
	    set outhtml $arg
	}
    }	
}
if {[expr {![info exists ldata] && ![info exists tdata]}] || ![info exists outhtml]} {
    error "[set ::n-kov::errorHeader] (-l input data OR -t input data) AND -o output_file.html have to be specified \n$::USAGE"
}

foreach vname {ldata tdata names} {
    if {[info exists $vname]} {
	if {[info exists CurFirstInputListLength]} {
	    if {$CurFirstInputListLength ne [llength  [subst $$vname]]} {
		error "[set ::n-kov::errorHeader] Number of elements (separated by comma) provided in -l -t -n has to be equal \n$::USAGE"
	    }
	    
	} else {
	    set CurFirstInputListLength [llength  [subst $$vname]]
	}
    }
}

if {![info exists names]} {
    if {[info exists tdata]} {
	set CurNameList $tdata
    } else {
	set CurNameList $ldata
    }
    set names {}
    foreach el $CurNameList {
	lappend names [file rootname [file tail $el]]
    }
}


foreach an {lAr tAr} {
    catch {array unset $an}
}
for {set i 0} {$i<[llength $names]} {incr i} {
    foreach var {ldata tdata} ar {lAr tAr} {
	if {[info exists $var]} {
	    if {![info exists $ar]} {array set $ar {}}
	    set fl [open [lindex [subst $$var] $i]]
	    foreach {n v} [read $fl] {
		set [subst $ar]($i,$n) $v
	    }
	    close $fl	
	}
    }
}
set ltable ""
set js_line_data ""
set js_line_data ""
if {[info exists lAr]} {
    set ltable "<style>table, th, td {border: 1px solid black;border-collapse: collapse;}</style><table style='width:100%'><tr><th>Attribute name<th><th>[join $names </th><th>]</th>"
    foreach var {lines chars sblank fblank atrs noatrs stags ctags less slashmore more mblanks1  mblanksmore noatrs09 noatrsaz noatrsAZ noatrsascii dquotes atrsblanks atrs09 atrsaz atrsAZ atrslow atrsup atrsalpha atrsdigit atrspunct atrsgraph atrsany} {
	append ltable <tr><th>$var<th>
	for {set i 0} {$i<[llength $names]} {incr i} {
	    if {$var eq "lines"} {
		set l $lAr($i,$var)
		append ltable <td>[commas $l]</td>
	    } else {
		if {$lAr($i,$var) ne 0} {
		    set s <br>([format %.3E [expr {$lAr($i,$var)/double($l)}]])
		} else {
		    set s {}
		}
		append ltable <td>[commas $lAr($i,$var)]$s</td>
	    }
	}
	append ltable </tr>
    }
    append ltable </table>

    set svbar_labels {atrs09 atrsaz atrsAZ  atrspunct}
    set linedata {}
    foreach var $svbar_labels {	    
	set cur {}
	for {set i 0} {$i<[llength $names]} {incr i} {	
	    lappend cur [expr {$lAr($i,$var)/double($lAr($i,lines))}]
	}
	lappend linedata $cur
    }
    set js_line_data [getD3Data svbar {Attrs Chars} $names $linedata $svbar_labels]
}

set js_allseries_len ""
set js_allseries_num ""
if {[info exists tAr]} {
    set tz :Etc/UCT
    set burth [clock scan "01-10-2004 00:00:00" -format {%d-%m-%Y %H:%M:%S} -timezone $tz]
    set curtime [clock seconds]
    set ticks {}
    for {set i $burth} {$i<$curtime} {set i [clock add $i 3 months]} {
	lappend ticks $i
    }
    lappend ticks $curtime
    set months {}
    foreach t $ticks {
	lappend months '[clock format $t -format "%m/%y"]'
    }

    set serieslen {}
    set seriesnum {}
    for {set i 0} {$i<[llength $names]} {incr i} {
	set cur_serieslen {}
	set cur_seriesnum {}
	foreach p [lsort -unique [regsub -all {[0-9]+,[0-9]+::([^:]+::[^:]+)::[^:]+::[0-9]+} [array names tAr 0,*] {\1}]] {
	    set cur_valslen {}
	    set cur_valsnum {}
	    for {set j 0} {$j<[llength $ticks]} {incr j} {
		set total_len 0
		set total_num 0
		foreach n [array names tAr $i,${j}::${p}::*] {
		    set total_len [expr {$total_len+[lindex $tAr($n) 0]}]
		    set total_num [expr {$total_num+[lindex $tAr($n) 1]}]
		}
		lappend cur_valslen $total_len
		lappend cur_valsnum $total_num
	    }
	    lappend cur_serieslen $cur_valslen
	    lappend cur_seriesnum $cur_valsnum
	    
	    
	}
	lappend serieslen $cur_serieslen
	lappend seriesnum $cur_seriesnum
    }    
    set lstlen {};
    set lstnum {};
    for {set i 0} {$i < [llength $names]} {incr i} {
	lappend lstlen "<div id='container_len_$i' style='min-width: 310px; height: 400px; margin: 0 auto'></div>"
	lappend lstnum "<div id='container_num_$i' style='min-width: 310px; height: 400px; margin: 0 auto'></div>"
    }
    foreach t {len num} d {serieslen seriesnum} {
	if {$t eq "len"} {
	    set lable {Value String Length (Million characters)}
	} else {
	    set lable {Value Numbers (Million values)}
	}
	set js_allseries_$t {}
	for {set i 0} {$i<[llength $names]} {incr i} {
	    set js_series {}	
	    set j 0
	    set svar series$t
	    set curval [lindex [subst $$svar] $i]
	    foreach p [lsort -unique [regsub -all {[0-9]+,[0-9]+::([^:]+::[^:]+)::[^:]+::[0-9]+} [array names tAr 0,*] {\1}]] {
		lappend js_series "{name: '$p',data: \[[join [lindex $curval $j] ,]\]}"
		incr j	    
	    }
	    lappend js_allseries_$t "Highcharts.chart('container_${t}_$i', {
      chart: {
	type: 'area'
      },
      title: {
	text: '[lindex $names $i]'
      },
      subtitle: {
	text: ''
      },
      xAxis: {
	categories: \[[join $months ,]\],
	tickmarkPlacement: 'on',
	title: {
	  enabled: false
	}
      },
      yAxis: {
	title: {
	  text: '$lable'
	},
	labels: {
	  formatter: function () {
	    return this.value / 1000000;
	  }
	}
      },
      tooltip: {
	split: true,
	valueSuffix: ''
      },
      plotOptions: {
	area: {
	  stacking: 'normal',
	  lineColor: '#666666',
	  lineWidth: 1,
	  marker: {
	    enabled: false
	  }
	}
      },
      series: \[[join $js_series ,]\]});"
	}
    }
}

if {![info exists lstnum]} {
    set lstnum ""
}
if {![info exists lstlen]} {
    set lstlen ""
}

set f [open $outhtml w+]    
puts $f "<html>
	<head> 
 <meta http-equiv='X-UA-Compatible' content='IE=edge'/>
 <meta http-equiv='Content-Type' content='text/html; charset=utf-8'>
 <meta name='viewport' content='width=device-width, initial-scale=1.0'>
<script src='https://code.highcharts.com/highcharts.js'></script>
<script src='https://code.highcharts.com/modules/exporting.js'></script>
		<script src='https://d3js.org/d3.v5.min.js'></script>
		<script src='https://cdnjs.cloudflare.com/ajax/libs/Chart.js/2.7.2/Chart.bundle.js'></script>
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
var data2 = \[$js_line_data\];

</script>
	</head>
	<body>
$ltable
		<div id='chart-holder'></div>
		<div id='versionsHolder'></div>
[join $lstnum \n]
[join $lstlen \n]
		<script>
if(data2.length>0) {
			addCharts();
}
[join $js_allseries_len \n]
[join $js_allseries_num \n]
</script>
</body>
</html>
"
close $f
puts DONE!

if 0 {
    var colors = [
'#3EBB8B', '#8AF45A', '#B06981', '#DEEC35', '#65F3A0', '#5DC789', '#D722BE', '#2A323C', '#480F95', '#F74C46', '#B0F4E4', '#9E02F2', '#D3C1AF', '#5113FB', '#F6DE0E', '#6CB2F8', '#5A05F5', '#3D5DC2', '#D693AE', '#79D5F9', '#CF1D26', '#82F285', '#0047FC', '#7610AD', '#40FDCA', '#D6135F', '#920827', '#5589C5', '#C828E5', '#F52E14', '#A49FA8', '#EE305F', '#AA0420', '#F53DF2', '#B650CF', '#73AC77', '#4003BE', '#B5E469', '#A70D5C', '#5E6F28', '#D3FB4B', '#173870', '#7A4E71', '#B41353', '#60F1B1', '#9BEF42', '#793126', '#89F186', '#4FF72A', '#EC389E', '#7980F2', '#00BEC9', '#ED8132', '#BD4914', '#08F0A3', '#EE8D0B', '#6E4B50', '#12B30F', '#A9C343', '#529A6A', '#17BD6B', '#94E8FB', '#4BF7A9', '#70AAA9', '#D47352', '#DF8158', '#A502B5', '#551C65', '#BB47C6', '#6588DD', '#FC98A8', '#8AA324', '#DCB6B6', '#5FD364', '#2F6ABD', '#08B4F4', '#A02EE3', '#666DB7', '#AD5A9F', '#18A92E', '#0B12C0', '#FC09A1', '#DC7884', '#6C7082', '#4EC251', '#B78BE6', '#42128D', '#D00E9A', '#6EF918', '#A3E038', '#D5DE4F', '#F65282', '#A3275C', '#6D50A2', '#C8FF99', '#04EA54', '#B434E8', '#FDAA46', '#B642CD', '#DBF3AB',
];
}
