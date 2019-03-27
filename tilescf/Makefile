PREFIX=/usr/lib
NAME=n-kov
install:
	-mkdir $(PREFIX)/$(NAME)
	cp -r *.tcl $(PREFIX)/$(NAME)/
	-(cd $(PREFIX)/$(NAME)/;rm pkgIndex.tcl)
	(cd $(PREFIX)/$(NAME)/;echo "pkg_mkIndex . *.tcl"|tclsh)
uninstall:
	-rm $(PREFIX)/$(NAME)/*.tcl
	-rmdir $(PREFIX)/$(NAME)
