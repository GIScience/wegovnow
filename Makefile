PREFIX=/tmp
NAME=DOESNOTEXIST
SHELL=./tclshc
POSTPROC=no
.ONESHELL:
install:
	set nkov_date {}
	catch {source libmake.tcl}
	if {![file isdirectory $(PREFIX) ] || ![file isdirectory $(NAME) ]} {
	    error {ERROR! $(PREFIX) of $(NAME) directory does not exist.}
	}
	set init_tokens {<== ==>}
	set final_tokens {<%% %%>}
	package require textutil::expander
	::textutil::expander myexp
	foreach fn [glob-r $(NAME)] {
	    set tail [file tail $$fn]
	    set dirname [file dirname $$fn]
	    set extension [file extension $$fn]
	    set headers {}
	    set footers {}
	    set curpath {}
	    if {[string first RCS $$dirname]<0 && $$extension ne {.nkov} && [string first {#} $$fn]<0 && [string first {~} $$fn]<0} {
		foreach path [list . {*}[file split $$dirname]] {
		    lappend curpath $$path
		    if {$$path ne {.}} {file mkdir $(PREFIX)/[file join {*}[lrange $$curpath 1 end]]}
		    if {[file exists [file join [file join {*}$$curpath] header$$extension.nkov]]} {
			set curfile [open [file join [file join {*}$$curpath] header$$extension.nkov]]
			set file_data [read $$curfile]
			lappend headers $$file_data
			close $$curfile
		    }
		    if {[file exists [file join [file join {*}$$curpath] footer$$extension.nkov]]} {
			set curfile [open [file join [file join {*}$$curpath] footer$$extension.nkov]]
			set file_data [read $$curfile]
			lappend footers $$file_data
			close $$curfile
		    }
		}
	        file delete $(PREFIX)/$$fn
	        if {$$headers ne {} || $$footers ne {}} {
		    set curfile [open $$fn]
		    set file_data [read $$curfile]
		    close $$curfile
		    set newheaders {}
		    set newfooters {}
		    ::myexp setbrackets {*}$$init_tokens
		    foreach h $$headers {
			lappend newheaders [myexp expand $$h]
		    }
		    foreach f $$footers {
			lappend newfooters [myexp expand $$f]
		    }
		    set file_data [myexp expand $$file_data]
		    unset headers footers
		    ::myexp setbrackets {*}$$final_tokens
		    set curfile [open $(PREFIX)/$$fn w]
		    foreach h $$newheaders {
	                if {![info exists nkov_noheaders]} {
			    puts $$curfile [myexp expand $$h]
			}
		    }
		    puts $$curfile [myexp expand $$file_data]
		    foreach f $$newfooters {
	                if {![info exists nkov_nofooters]} {
			    puts $$curfile [myexp expand $$f]
			}
	            }
	        } else {
	            file copy -force $$fn $(PREFIX)/$$fn
	        }
	    }
	}
	if {[info exists postproc($(NAME))]} {
	    if {!$(POSTPROC)} {
	        puts "\n\n\nRecommended postprocessing: \n\n$$postproc($(NAME))\n\n\n"
	    } else {
	        foreach cmd $$postproc($(NAME)) {
	            exec {*}$$cmd
	        }
	    }
	}
uninstall:	
	catch {source libmake.tcl}
	if {![file isdirectory $(PREFIX) ] || ![file isdirectory $(NAME) ]} {
	    error {ERROR! $(PREFIX) of $(NAME) directory does not exist.}
	}
	foreach fn [glob-r $(NAME)] {
	    set tail [file tail $$fn]
	    set dirname [file dirname $$fn]
	    set extension [file extension $$fn]
	    if {[string first RCS $$dirname]<0 && $$extension ne {.nkov}} {
		file delete $(PREFIX)/$$fn
		set dirname [file dirname $$fn]
		catch {file delete $(PREFIX)/$$dirname}
	    }
	}
	catch {file delete $(PREFIX)/$(NAME)}
