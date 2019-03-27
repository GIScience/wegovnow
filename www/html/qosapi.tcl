::rivet::headers type "image/svg+xml"
proc verify1 {h t s ua ref} {
    set debugstring {<rect width="160" height="90" style="fill:rgb(%d,%d,%d);stroke-width:3;stroke:rgb(200,200,200)" /><text x="20" y="50" font-family="Verdana" font-size="20">%s</text>}
    set status {REJECTED}
    if {[regexp {^[\w:?#,.!_*%@^&()=/-]*$} $ref] &&  [string is digit $h] && [string is digit $t] && [string is digit $s] &&  [expr {abs([clock milliseconds]-$t)}]<3600000} {
	if {$h<5000000 && [::xxhash::xxhash32 "$ua :: $ref :: $t" $s]==$h} {
	    exec curl -s --connect-timeout 0.05 https://wgn.gsdr.gq/wmq2/api.tcl?fineurl=[::rivet::escape_string $ref]
	    set status {ACCEPTED}
	}
    }
    set svgdata {<svg version="1.1" baseProfile="full" xmlns="http://www.w3.org/2000/svg">}
    if {[::rivet::var get debug] ne {}} {
	if {$status eq "ACCEPTED"} {
	    set rgb {0 255 0}
	} else {
	    set rgb {255 0 0}
	}
	set svgdata "$svgdata\n[format $debugstring {*}$rgb $status]"
    }
    set svgdata "$svgdata\n<!-- $status -->\n</svg>"
    ::rivet::headers add Content-Length [string length $svgdata]
    puts $svgdata        
}
if {[::rivet::var exists refurl]} {
    verify1 [::rivet::var get hash] [::rivet::var get time] [::rivet::var get seed] [::rivet::env HTTP_USER_AGENT] [::rivet::unescape_string [::rivet::var get refurl]]
} else {
    verify1 [::rivet::var get hash] [::rivet::var get time] [::rivet::var get seed] [::rivet::env HTTP_USER_AGENT] [::rivet::env HTTP_REFERER]    
}
