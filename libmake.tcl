
####################################################################
#  
#     A library:  nkovcom/LibsAndTools/GNUMakeTcl/libmake.tcl
#
####################################################################
#   
#   (c) Alexey Noskov (http://a.n-kov.com). 
#   Last updated: 2017/06/23 07:53:28
#
####################################################################
set postproc(nkovcom) {{cd /tmp/nkovcom/LibsAndTools;make uinstall;make install}}
proc glob-r {{dir .}} {
    set res {}
    foreach i [lsort [glob -nocomplain -dir $dir *]] {
        if {[file type $i] eq {directory}} {
            eval lappend res [glob-r $i]
        } else {
            lappend res $i
        }
    }
    set res
}
# 


