# GIScience (Uni-Heidelberg) in WeGovNow


A guide to project outcomes by the GIScience team

![GIScience logo](https://avatars1.githubusercontent.com/u/4661504?s=200&v=4)

This project has received funding from the European Union's Horizon 2020 research and innovation programme under grant agreement No 693514

![eu logo](https://infalia.github.io/wegovnow/assets/images/eu.png)

If you re-use any of the components, modules, or plugins, please acknowledge the WeGovNow project 

![WeGovNow logo](https://infalia.github.io/wegovnow/assets/images/wegovnow-logo-icon.png)


# EmGSDR, Tiles.CF and IGIS.TK

This repository provides mirrored versions of an embeddable instance of Geo-Spatial Data Repository for "Grand" Quality (https://wgn.gsdr.gq), Integrated Geo-Information System Tool Kit (http://igis.tk, see also igistk directory), and Tiles Common Framework (http://tiles.cf, see also tilescf directory). This repository provides all developed source code and required dependencies. Futher, instructions for the deployment of EmGSDR (embeddable GSDR) instances for WeGovNow pilot sites are provided.

(Notice, that full databases for pilot instances can be downloaded from here: https://wgn.gsdr.gq/sd_gsdr_wgn.sqlite.zip , https://wgn.gsdr.gq/sw_gsdr_wgn.sqlite.zip , and https://wgn.gsdr.gq/tr_gsdr_wgn.sqlite.zip . )

# Installation on Debian-like systems (Debian, Ubuntu, Mint, etc.)

The archiving software comprises files (see emgsdr.tar.gz) required for the embeddable services deployment. The proposed services can be easily installed on GNU/linux and any unix-like systems (e.g., *BSD or MacOS). There are no principal obstacles for installing on Windows systems, but it was not tested. We use the same deployment solutions as we have described in \cite{noskov2018fbswebgis}.  Further, we provide concrete installation steps for Debian-like systems (e.g., Debian, Ubuntu, linux Mint, etc.). We use a Debian Jessie system in an ARM cloud.

First of all, we install the standarsdd dependencies provided by a linux distribution:

````
$ apt-get install libxml2-dev libgeos++-dev libproj-dev tcllib apache2-dev
````

Since we need to process multiple concurrent user requests, SQLite database should be configured to use multi-threaded threading mode. Otherwise, there will be errors caused by incorrect processing of multiple requests coming from Apache Rivet. Typically, linux distributions provide an SQLite library with the "serialize" threading mode by default, which is inappropriate for our system. Thus, we compile SQLite to enable the required multi-threaded threading mode. Because of this, all further dependencies must be built for the source code. The source code is obtained using the following instructions:
````
$  wget https://www.sqlite.org/2018/sqlite-autoconf-3260000.tar.gz
$  wget http://apache.40b.nl/tcl/rivet/rivet-3.1.0.tar.gz
$  wget http://www.gaia-gis.it/gaia-sins/libspatialite-4.3.0a.tar.gz
$  wget https://www.sqlite.org/contrib/download/extension-functions.c?get=25
````

Then, all compressed source files need to be extracted using the command $tar -xvzf filename.tar.gz$. Next, a user needs to go to every extracted folder and execute the following standard commands:

````
$ ./configure
$ make
$ sudo make install
````

For the SQLite library an the procedure is slightly different from others (first, configure the library using the SQLITE_THREADSAFE=2 mode and, second, go to tea folder to install the required tcl SQLite library):
````
$ ./configure SQLITE_THREADSAFE=2
$ make
$ sudo make install  
$ cd tea/
$ ./configure
$ make
$ sudo make install
````

The SpatiaLite library was configured using this: $./configure --disable-freexl$. For ./configure commands, users might apply a $"--prefix=/destination/folder"$ option to install compiled files into a non-standard destination. It is useful to one who does not have root permissions.

Now, a user should install the embeddable system itself. For this, first, she needs to download the archiving software and, second, carry out the installation instructions:
````
$ cd gsdrfiles
$ tar -xvzf emgsdr.tar.gz
$ tar -xvzf nkov.tar.gz
$ tar -xvzf tilescf.tar.gz
$ chmod +x tclshc
$ make NAME=nkov
$ make NAME=tilescf
$ cd /tmp/nkov
$ make install
$ cd /tmp/tilescf
$ make install
````

Next, users need to configure Apache. Supposing that Apache uses the /var/www/html folder for storing web files, 000-default.conf needs to comprise the following virtual host configuration:
````
<VirtualHost *:80>
DocumentRoot /var/www/html
LoadModule rivet_module /usr/lib/apache2/modules/mod_rivet.so
AddType 'application/x-rivet-tcl;charset=utf-8' tcl
RivetServerConf ChildInitScript "source /var/www/initscript.tcl"
</VirtualHost>
````
The apache2.conf needs to configure Apache Rivet using such code (a user configures concrete values, it depends on available resources):
````
RivetServerConf SeparateVirtualInterps yes
RivetServerConf SeparateChannels yes
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %{HTTPS} !on
RewriteRule .* https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L,QSA]
</IfModule>
KeepAlive Off
<IfModule prefork.c>
StartServers        5
MinSpareServers     5
MaxSpareServers     10
MaxClients          150
MaxRequestsPerChild 1500
</IfModule>
````

Next, databases and server-side code files should be copied to proper destinations:

````
$ cp www/html/api.tcl /var/www/html
$ chmod +r /var/www/html/api.tcl
$ cp www/initscript.tcl www/killdelay.sh /var/www
$ chmod +x www/killdelay.sh
$ chmod +r www/initscript.tcl www/killdelay.sh
````


Finally, a database gsdr_wgn_*.sqlite needs to be copied into the /var/www folder. An instance is ready-to-use after the restarting a web server. 




# Installation on CentOS 7


````
$ tar -xvzf emgsdrwgn.tar.gz
$ cd emgsdrwgn
````
## System Dependencies Installation:
````
$ sudo yum install geos-devel proj-devel tcllib httpd-devel tcl-devel gcc make libxml2-devel
````

### 1) Building Required Dependencies:

   1.0)) Apache Rivet
````
$ cd rivet-3.1.1
$ autoreconf -f -i
$ ./configure --prefix=/usr/local
$ make
$ sudo make install 
````
#### 1.2) SQLite and SQLite Tcl
````
$ cd ../sqlite-autoconf-3200100/
$ ./configure SQLITE_THREADSAFE=2 --prefix=/usr/local 
$ make
$ sudo make install
$ cd tea
$ ./configure --prefix=/usr/local --libdir=/usr/local/lib
$ make
$ sudo make install
````
#### 1.3) extension-functions
````
$ cd ../..
$ gcc -fPIC -lm -shared extension-functions.c -o libsqlitefunctions.so
$ sudo cp libsqlitefunctions.so /usr/local/lib
````
#### 1.4) LibSpatialite
````
$ cd libspatialite
$ autoreconf -f -i
$ ./configure --prefix=/usr/local --disable-knn --disable-freexl --disable-geosreentrant
$ make
$ sudo make install
````
#### 1.5) GSDR libs:
````  
$ cd ..
$ make NAME=nkov
$ (cd /tmp/nkov/; sudo  make install PREFIX=/usr/local/lib; sudo chmod +r /usr/local/lib/n-kov/n-kov.tcl)
$ make NAME=tilescf
$ (cd /tmp/tilescf/; sudo  make install PREFIX=/usr/local/lib)
$ rm -rf /tm/tilescf /tmp/nkov
````
### 2) Copying files (supposing, /var/www/html is a virtual host's root) - select correct ps: sandona, southwark, or turin
````
$ sudo cp www/initscript.tcl www/killdelay.sh ps/sandona/gsdr_wgn.sqlite /var/www/
$ sudo chmod +r /var/www/initscript.tcl /var/www/killdelay.sh /var/www/gsdr_wgn.sqlite
$ sudo cp www/initscript.tcl www/killdelay.sh ps/sandona/gsdr_wgn.sqlite /var/www/
$ sudo cp www/html/api.tcl /var/www/html
$ sudo cp www/html/qosapi.tcl www/html/*.js www/html/*.css /var/www/html
(select appropriate: sandona, southwark, or turin)
$ sudo cp ps/sandona/index.html /var/www/html
$ sudo chmod +r /var/www/html/*
````
### 3) Configuring System =

Add the following instructions to  

#### 3.1) /etc/sysconfig/httpd:
````
LD_LIBRARY_PATH=/usr/local/lib
TCLLIBPATH=/usr/local/lib
````
#### 3.2) /etc/httpd/conf/httpd.conf (! can be modified according to the available resources !):
````
RivetServerConf SeparateVirtualInterps yes
RivetServerConf SeparateChannels yes
KeepAlive Off
<IfModule prefork.c>
StartServers        2
MinSpareServers     2
MaxSpareServers     5
MaxClients          150
MaxRequestsPerChild 1500
</IfModule>
````

#### 3.3) /etc/httpd/conf.d/vhost.conf (Just a sample, !!! /var/www/initscript.tcl depends on the destination path, see the copying section 3)):
````
<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog /var/log/httpd/error.log
        CustomLog /var/log/httpd/access.log combined
    LoadModule rivet_module /usr/lib64/httpd/modules/mod_rivet.so
    AddType 'application/x-rivet-tcl;charset=utf-8' tcl
    RivetServerConf ChildInitScript "source /var/www/initscript.tcl"
</VirtualHost>
````


### 4) Final configuration of GSDR

Set the correct path to gsdr_wgn.sqlite in the following line of /var/www/initscript.tcl (see section 2))
sqlite3 sdb /var/www/gsdr_wgn.sqlite -readonly 1

Set the correct path to killdelay.sh in the following line of /var/www/html/api.tcl (see section 2))
set killwatch [open "|sh /var/www/killdelay.sh [pid]"]

Set correct domain in xxhash.min.js instead of http://localhost in lines 25 and 27


### 5) Testing the installation

The following shoul print "OK", change the path to /var/www/gsdr_wgn.sqlite in necessary:
````
$ export LD_LIBRARY_PATH=/usr/local/lib; export TCLLIBPATH=/usr/local/lib;echo "package require sqlite3;package require n-kov;package require libtiles;sqlite3 sdb /var/www/gsdr_wgn.sqlite -readonly 1;sdb enable_load_extension true;sdb eval \"SELECT load_extension('/usr/local/lib/libsqlitefunctions')\";sdb eval \"SELECT load_extension('/usr/local/lib/mod_spatialite')\";puts OK"|tclsh
````
Open index.html