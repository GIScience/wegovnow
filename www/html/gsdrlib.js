defvars = {curlay:0,attr:'wbi',area:'SD',layer:'OSM.CUR',cx:1398788.915,cy:5721247.690,zoom:14,rotate:0,func:'avag',sizeattr:'wbi'};
views = {'SD': {label:'San Donà di Piave','center':[1401138.829,5721892.882],zoom:14},
	  'TR': {label:'Turin','center':[853412.592,5635945.084],zoom:14},
	  'SW': {label:'Southwark','center':[-7885.135,6708634.745],zoom:14},
	  'HD': {label:'Heidelberg','center':[965452.176,6345812.538],zoom:14}
	 };
colors = getColors();
geoJsonFormat=new ol.format.GeoJSON();
sourceOSM = new ol.source.OSM();
osml = new ol.layer.Tile({
    source: sourceOSM
});

/*****************************************************

                     GENERAL PURPOSE

******************************************************/
function getJSON(requrl) {
    for (var i in [0,1,2]) {
	try {
	    var json = JSON.parse(getTEXT(requrl));
	    return json
	} catch(e) { errjson = json }
	sleep(parseInt(Math.random()*1000)+100);
    }
}

function getTEXT(requrl) {
    var Httpreq = new XMLHttpRequest();
    Httpreq.open("GET",requrl,false);
    Httpreq.send(null);
    return Httpreq.responseText;
}

function hexToRgb(hex) {
    var result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (!result) {
	var result = 'rgba(0,0,0,0)';
    }
    return 'rgba('+parseInt(result[1], 16)+','+parseInt(result[2], 16)+','+parseInt(result[3], 16)+',0.9)';
}

function sleep(milliseconds) {
    var start = new Date().getTime();
    for (var i = 0; i < 1e7; i++) {
	if ((new Date().getTime() - start) > milliseconds){
	    break;
	}
    }
}

function getColors(numberOfItems = 100, gradient=['red','pink','lightgreen','green']) {
    var rainbow = new Rainbow();
    rainbow.setNumberRange(0, numberOfItems);
    rainbow.setSpectrum.apply(this,gradient);
    var colors = new Array();
    for (var i = 1; i <= numberOfItems; i++) {
	var hexColour = rainbow.colourAt(i);
	colors.push('#' + hexColour);
    }
    return colors
}

/*****************************************************

                     URLs

******************************************************/

function defvarsFromUrl() {
    var query = location.search.substr(1);
    var result = {};
    query.split("&").forEach(function(part) {
	var item = part.split("=");
	var num = decodeURIComponent(item[1]);
	if(num.match(/^\d+$/)){
	    num =  parseInt(num)
	} else if(num.match(/^\d+\.\d+$/)){
	    num = parseFloat(num)
	}
	if (typeof defvars[item[0]] !== 'undefined') {
	    defvars[item[0]] = num
	}
    });
}

function defvarsUpdate(key,value) {
    if(typeof key !== "undefined" && typeof defvars[key] !== "undefined") {
	defvars[key]=value;
    }
    var url_list=[];
    var path=location.pathname;
    for (k in defvars) {
	url_list.push(k+'='+defvars[k]);
    }
    path=path+'?'+url_list.join('&');
    window.history.pushState("object or string", "Title", path.replace(/\/+/,''));
    gsdrwm();
    try {
    if(typeof key !== "undefined" && typeof defvars[key] !== "undefined") {} else {
	var selel = document.getElementById("sizeattr");
	if (defvars.curlay == 2) {
	    selel.style.display = '';
	} else {
	    selel.style.display = 'none';
	}
	var vals =  [defvars.area,defvars.layer,defvars.curlay,defvars.attr, defvars.sizeattr];
	var names = ["sel_area",  "sel_layer",  "sel_display", "sel_colattr","sel_sizeattr"];
	for (i in names) {
	    document.getElementById(names[i]).value=vals[i];
	}
	var selel = document.getElementById("display");
	if (defvars.curlay == 3) {
	    
	    selel.style.display = 'none';
	} else {
	    selel.style.display = '';
	}
    }}
    catch(err) {}
}

/*****************************************************

                     OnChange - Select

******************************************************/

/*
function changeArea(selectObject) {
    defvarsUpdate('area',selectObject.value);
    map.getView().setCenter(views[defvars.area].center);
    map.getView().setZoom(views[defvars.area].zoom);
}

function changeDatasrc(selectObject,key='layer') {
    defvarsUpdate(key,selectObject.value);
    map.removeLayer(layers[defvars.curlay]);
    map.addLayer(layers[defvars.curlay]);
    layers[defvars.curlay].getSource().changed();
    layers[defvars.curlay].changed();    
}

function changeLayer(selectObject) {
    map.removeLayer(layers[defvars.curlay]);
    defvarsUpdate('curlay',parseInt(selectObject.value));
    map.addLayer(layers[defvars.curlay]);
    layers[defvars.curlay].getSource().changed();
    layers[defvars.curlay].changed();
}

function changeValue(selectObject,key='attr') {
    if (defvars.curlay!=2) {
    changeSource();
    } else {
    vtileLayer.getSource().tileCache.clear();
    }
    defvarsUpdate(key,selectObject.value);
    layers[defvars.curlay].getSource().changed();
    if (defvars.curlay==2) {
    location.reload();
    }
}
*/

function onchangeLayer(selectObject) {
    var selel = document.getElementById("display");
    if (selectObject.value.indexOf('-')>1) {
	selel.style.display = 'none'
    } else {
	selel.style.display = ''
    }
}

function toggleviz(selectObject) {
    var selel = document.getElementById("sizeattr");
    if (selectObject.value == '2') {
	selel.style.display = '';
    } else {
	selel.style.display = 'none';
    }
}

function apply() {
    
    defvars.func=document.getElementById("sel_agfunc").value;
    map.removeLayer(layers[defvars.curlay]);
    defvars.curlay=parseInt(document.getElementById("sel_display").value);
    defvars.layer=document.getElementById("sel_layer").value;
    if (defvars.layer.indexOf('-')>1) {
	defvars.curlay=3;
    }
    defvars.attr=document.getElementById("sel_colattr").value;
    defvars.sizeattr=document.getElementById("sel_sizeattr").value;
    if (defvars.area != document.getElementById("sel_area").value) {
	defvars.area=document.getElementById("sel_area").value;
	map.getView().setCenter(views[defvars.area].center);
	map.getView().setZoom(views[defvars.area].zoom);
    }    
    defvarsUpdate();
    initVectors();
    layers=[vectorLayer,heatmap,vtileLayer,compTileLayer];
    map.addLayer(layers[defvars.curlay]);
    onMoveEnd();
}

/*****************************************************

                     STYLES

******************************************************/

//stroke = new ol.style.Stroke({color: 'black', width: 0});
//vtileLayer.getSource().sourceTiles_["14,8765,-5851"].getFeatures()[0].get('main')
/*
function styleTileFunction(feature) {
    var range = minmaxdata['sd_'+defvars.sizeattr+'_max']-minmaxdata['sd_'+defvars.sizeattr+'_min'];
    var scale = Math.round(20*((parseFloat(feature.get(defvars.sizeattr))-minmaxdata['sd_'+defvars.sizeattr+'_min'])/range));
    var colorrange = minmaxdata['sd_'+defvars.attr+'_max']-minmaxdata['sd_'+defvars.attr+'_min'];
    var outfeature = feature;
    var color = hexToRgb(colors[Math.round(99*((parseFloat(outfeature.get(defvars.attr))-minmaxdata['sd_'+defvars.attr+'_min'])/colorrange))]);
    if (typeof color == "undefined") {
    var color = 'rgba(255,0,0,0.9)';
    }
    //var txt = String(feature.get(feature.get('f.'+defvars.sizeattr)));
    return new ol.style.Style({image:
           new ol.style.Circle({
	      radius: 2+scale,
	         fill: new ol.style.Fill({
		        color: color
			   }),
			      stroke: new ol.style.Stroke({color: color, width: 1})})
			            })
}
*/





/*****************************************************

                     Data Manipulation

******************************************************/

prevminmaxurl = "";
function setminmax() {
    if (typeof map !== 'undefined') {
	var zreq = map.getView().getZoom();
    } else {
	var zreq = defvars.zoom;
    }

    var zreq = zreq+2;//+3;
    if (zreq>19) {
	var zreq = 19
    }

    if (defvars.curlay==3) {
	var [a,b] = defvars.layer.split('.')[0].split('-');
	var c = defvars.layer.split('.')[1];
	var layA = defvars.area+'.'+a+'.'+c;
	var layB = defvars.area+'.'+b+'.'+c;
	var cururl = 'api.tcl?SELECT=__min,val,___&AS='+defvars.attr+'_min,__max,val,___&AS='+defvars.attr+'_max&FROM&___=&SELECT=__'+defvars.func+','+a+'.'+defvars.attr+',___&__a__=__'+defvars.func+','+b+'.'+defvars.attr+',___&AS=val&FROM=wbidata&AS='+a+'&JOIN=tiles&ON='+a+'.tile&__e__=tiles.rowid&JOIN=wbidata&AS='+b+'&ON='+b+'.tile&__e__=tiles.rowid&WHERE='+a+'.name&__e__=__q__'+layA+'__q__&AND='+b+'.name&__e__=__q__'+layB+'__q__&GROUP__s__BY=__substr,q,1,'+zreq+',___,___';
    } else if (defvars.curlay==2) {
	var cururl = 'api.tcl?SELECT=__min,valA,___&AS='+defvars.attr+'_min,__max,valA,___&AS='+defvars.attr+'_max,__min,valB,___&AS='+defvars.sizeattr+'_min,__max,valB,___&AS='+defvars.sizeattr+'_max&FROM&___=&SELECT=__'+defvars.func+','+defvars.attr+',___&AS=valA,__'+defvars.func+','+defvars.sizeattr+',___&AS=valB&FROM=wbidata&JOIN=tiles&ON=wbidata.tile&__e__=tiles.rowid&WHERE=wbidata.name&__e__=__q__'+defvars.layer+'.'+defvars.area+'__q__&GROUP__s__BY=__substr,q,1,'+zreq+',___,___';
    } else {
	var cururl = 'api.tcl?SELECT=__min,'+defvars.attr+',___&AS='+defvars.attr+'_min,__max,'+defvars.attr+',___&AS='+defvars.attr+'_max,__min,'+defvars.sizeattr+',___&AS='+defvars.sizeattr+'_min,__max,'+defvars.sizeattr+',___&AS='+defvars.sizeattr+'_max&FROM=wbidata&WHERE=wbidata.name&__e__=__q__'+defvars.layer+'.'+defvars.area+'__q__';
    }
    if (prevminmaxurl != cururl) {
	prevminmaxurl = cururl;
	var curdata = getJSON(cururl);
	minmaxdata = {};
	for (k in curdata.features[0].properties) {
	    minmaxdata[k]=curdata.features[0].properties[k];
	}
    }
}

function changeSource() {
    var extent = map.getView().calculateExtent(map.getSize());
    extent = ol.proj.transformExtent(extent,'EPSG:3857','EPSG:4326');
    var url = 'api.tcl?SELECT=__printf,__q____p__s__c____p__s__c____p__s__q__,19,col,row,___&AS=id,'+defvars.attr+',__AsGeoJSON,geomcent,___&FROM=wbidata&JOIN=tiles&ON=tile&__e__=tiles.rowid&WHERE=name&__e__=__q__'+defvars.layer+'.'+defvars.area+'__q__&AND=__Within,geomcent,__BuildMbr,' + extent.join(',')+',___,___';
    vectorSource.clear(true);
    var features = geoJsonFormat.readFeatures(getJSON(url), {
	dataProjection: 'EPSG:4326',
	featureProjection: 'EPSG:3857'
    });
    vectorSource.addFeatures(features);
}

prevpos = [];
prevdefvars = [];
last_timestamp = 0;


function onMoveEnd(evt) {
    var curts = new Date().getTime();
    var curpos = [map.getView().getCenter()[0],map.getView().getCenter()[1],map.getView().getZoom()];
    //    try {
    if ((curts-last_timestamp)/1000 > 2 && (prevpos != curpos || prevdefvars != defvars)) {	
	prevpos = curpos;
	prevdefvars = defvars;
	last_timestamp=curts;
	
	if (map.getView().getZoom()>18) {
	    datalay.disabled=false;
	    if (datalay.value!="None") {
		setemptylay(true);
	    } else {
		setemptylay(false);
	    }	
	} else {
	    datalay.disabled=true;
	    datalay.value="None";
	    setemptylay(true);
	}
    //    } catch(err) {}
	if (defvars.curlay<2) {

		changeSource ();
	    layers[defvars.curlay].getSource().changed();
	} else {
	    setminmax()
	}
	defvarsUpdate('cx',map.getView().getCenter()[0]);
	defvarsUpdate('cy',map.getView().getCenter()[1]);
	defvarsUpdate('zoom',map.getView().getZoom());
	defvarsUpdate('rotate',map.getView().getRotation());
    }
}


function initVectors() {
    setminmax();
    vectorSource = new ol.source.Vector({
	format: geoJsonFormat,
	projection: 'EPSG:4326'
    });

    vectorLayer = new ol.layer.Vector({
	source: vectorSource,
	style: function(feature) {
	    curfeature=feature;
	    var cls = Math.round(99*((feature.values_[defvars.attr]-minmaxdata[defvars.attr+'_min'])/parseFloat(minmaxdata[defvars.attr+'_max']-minmaxdata[defvars.attr+'_min'])));
	    var color = hexToRgb(colors[cls]);
	    return new ol.style.Style({
		image: new ol.style.RegularShape({
		    fill: new ol.style.Fill({color: color}),
		    points: 4,
		    radius: 10,
		    angle: Math.PI / 4
		})
	    })
	},
	opacity: 0.5
    });

    heatmap = new ol.layer.Heatmap({
	gradient: ['white','red','pink','lightgreen','green'],
	source: vectorSource
    });
    heatmap.getSource().on('addfeature', function(event) {
	var cls = Math.round(99*((event.feature.get(defvars.attr)-minmaxdata[defvars.attr+'_min'])/parseFloat(minmaxdata[defvars.attr+'_max']-minmaxdata[defvars.attr+'_min'])));
	event.feature.set('weight', cls*0.01);
    });

    vectorSourceTile = new ol.source.VectorTile({
	url: "{z}/{x}/{y}",
	tileGrid: ol.tilegrid.createXYZ(),
	format: new ol.format.GeoJSON(),
	tileLoadFunction: function(tile, url) {
	    tile.setLoader(function() {
		var [z,col,row]=url.split('/');
		var q=getJSON('api.tcl?SELECT=__tile2quadkey,'+col+','+row+','+z+',___&AS=q').features[0].properties.q;
		var zreq = parseInt(z)+2;//+3;
		if (zreq > 19) {
		    zreq = 19;
		}
		var resurl = 'api.tcl?SELECT=__q__'+z+','+col+','+row+'__q__&AS=id,__tile2geom,__quadkey2tile,__substr,q,1,'+zreq+',___,___,__r__1,__r__1,4,___,__'+defvars.func+','+defvars.attr+',___&AS='+defvars.attr+',__'+defvars.func+','+defvars.sizeattr+',___&AS='+defvars.sizeattr+'&FROM=wbidata&JOIN=tiles&ON=tile&__e__=tiles.rowid&WHERE=name&__e__=__q__'+defvars.layer+'.'+defvars.area+'__q__&AND=__substr,q,1,'+z+',___&__e__=__q__'+q+'__q__&GROUP__s__BY=__substr,q,1,'+zreq+',___';
		var json = getJSON(resurl);
		var format = tile.getFormat();
		var prj = format.readProjection(json);
		if (json.features === null) {
		    json.features = [{'type':'Feature'}];
		}
		//tile.setFeatures(format.readFeatures(json, {featureProjection: prj}));
		tile.setFeatures(format.readFeatures(json, {featureProjection: prj}));
		tile.setProjection(prj);
	    })
	}})
    vtileLayer = new ol.layer.VectorTile({
	source: vectorSourceTile,
	style: function(feature) {
	    var range = minmaxdata[defvars.sizeattr+'_max']-minmaxdata[defvars.sizeattr+'_min'];
	    var scale = Math.round(20*((parseFloat(feature.get(defvars.sizeattr))-minmaxdata[defvars.sizeattr+'_min'])/range));
	    var colorrange = minmaxdata[defvars.attr+'_max']-minmaxdata[defvars.attr+'_min'];
	    var outfeature = feature;
	    var color = hexToRgb(colors[Math.round(99*((parseFloat(outfeature.get(defvars.attr))-minmaxdata[defvars.attr+'_min'])/colorrange))]);
	    if (typeof color == "undefined") {
		var color = 'rgba(255,0,0,0.9)';
	    }
	    //var txt = String(feature.get(feature.get('f.'+defvars.sizeattr)));
	    return new ol.style.Style({image:
				       new ol.style.Circle({
					   radius: 2+scale,
					   fill: new ol.style.Fill({
					       color: color
					   }),
					   stroke: new ol.style.Stroke({color: color, width: 1})})
				      })
	}})

    compSourceTile = new ol.source.VectorTile({
	url: "{z}/{x}/{y}",
	tileGrid: ol.tilegrid.createXYZ(),
	format: new ol.format.GeoJSON(),
	tileLoadFunction: function(tile, url) {
	    tile.setLoader(function() {
		var [z,col,row]=url.split('/');
		var q=getJSON('api.tcl?SELECT=__tile2quadkey,'+col+','+row+','+z+',___&AS=q').features[0].properties.q;
		var zreq = parseInt(z)+2;//+3;
		if (zreq > 19) {
		    zreq = 19;
		}
		var [a,b] = defvars.layer.split('.')[0].split('-');
		var c = defvars.layer.split('.')[1];
		var layA = defvars.area+'.'+a+'.'+c;
		var layB = defvars.area+'.'+b+'.'+c;
		var resurl = 'api.tcl?SELECT=__q__'+z+','+col+','+row+'__q__&AS=id,__tile2geom,__quadkey2tile,__substr,q,1,'+zreq+',___,___,__r__1,__r__1,4,___,__'+defvars.func+','+a+'.'+defvars.attr+',___&AS=green,__'+defvars.func+','+b+'.'+defvars.attr+',___&AS=red&FROM=wbidata&AS='+a+'&JOIN=tiles&ON='+a+'.tile&__e__=tiles.rowid&JOIN=wbidata&AS='+b+'&ON='+b+'.tile&__e__=tiles.rowid&WHERE='+a+'.name&__e__=__q__'+layA+'__q__&AND='+b+'.name&__e__=__q__'+layB+'__q__&AND=__substr,q,1,'+z+',___&__e__=__q__'+q+'__q__&GROUP__s__BY=__substr,q,1,'+zreq+',___';

		var json = getJSON(resurl);
		var format = tile.getFormat();
		var prj = format.readProjection(json);
		if (json.features === null) {
		    json.features = [{'type':'Feature'}];
		}
		tile.setFeatures(format.readFeatures(json, {featureProjection: prj}));
		tile.setProjection(prj);
	    })
	}})
    compTileLayer = new ol.layer.VectorTile({
	source: compSourceTile,
	opacity: 0.5,
	style: function(feature) {
	    //compfeature = feature;
	    var range = minmaxdata[defvars.attr+'_max']-minmaxdata[defvars.attr+'_min'];
	    var scale = Math.round(20*(((feature.get('red')+feature.get('green'))-minmaxdata[defvars.attr+'_min'])/range));
	    var radius=2+scale;
	    var data = [feature.get('green'),feature.get('red')];

	    return new ol.style.Style(
		{image: new ol.style.Chart(
		    {type: "pie",
		     radius: radius,
		     data: data,
		     rotateWithView: true,
		     stroke: new ol.style.Stroke(
			 {color: "#fff",
			  width: 0
			 }),
		    })
		})
	}})
}


function getvectlay(url) {
    vectorLayer = new ol.layer.Vector({
	source: new ol.source.Vector({
	    url: [location.origin,'api.tcl?'+url].join('/'),
	    format: geoJsonFormat	    
	})
    })
}


function getvectlay(url) {
    vectorLayer = new ol.layer.Vector({
	source: new ol.source.Vector({
	    url: [location.origin,'api.tcl?'+url].join('/'),
	    format: geoJsonFormat	    
	})
    })
}


function setemptylay(isempty) {
    try {
	map.removeLayer(emptylayer);
    } catch (e) {} 
    if (isempty) {
	emptylayer = new ol.layer.Vector({source: new ol.source.Vector({})});
    } else {
	var extent = map.getView().calculateExtent(map.getSize());
	extent = ol.proj.transformExtent(extent,'EPSG:3857','EPSG:4326');
	emptylayer = new ol.layer.Vector({
	    source: new ol.source.Vector({
		url: 'api.tcl?SELECT=elements.id&AS=elid,__AsGeoJSON,geom,___,datasrc,__group_concat,__printf,__q____p__s__r____p__s__q__,keys.txt,vals.txt,___,___&AS=data&FROM=elements&JOIN=tags&ON=tags.id&__e__=elements.id&JOIN=keys&ON=keys.rowid&__e__=tags.key&JOIN=vals&ON=vals.rowid&__e__=tags.val&WHERE=datasrc&__e__=__q__'+datalay.value+'.'+areasel.value+'__q__&AND=__Intersects,geom,__BuildMbr,' + extent.join(',')+',___,___&GROUP__s__BY=elements.id',
		format: geoJsonFormat	    
	    })
	})	
    }
    try {
	map.addLayer(emptylayer);
    } catch (e) {}
}


/*****************************************************

                     POPUPS

******************************************************/

function pops() {
    container = document.getElementById('popup');
    content = document.getElementById('popup-content');
    closer = document.getElementById('popup-closer');


    closer.onclick = function() {
	overlay.setPosition(undefined);
	closer.blur();
	return false;
    };
    overlay = new ol.Overlay({
	element: container,
	autoPan: true,
	autoPanAnimation: {
	    duration: 250
	}
    });
}



/*****************************************************

                     UI

******************************************************/

function sidebar_open() {
    document.getElementById("Main").style.marginLeft = "200px";
    document.getElementById("sidebar").style.width = "200px";
    document.getElementById("sidebar").style.display = "block";
    document.getElementById("openNav").style.display = 'none';
    document.getElementById("footer").style.marginLeft = "210px";
    document.getElementById("map").style.left = "210px";
    if (typeof map !== 'undefined') map.updateSize();
}

function sidebar_close() {
    document.getElementById("sidebar").style.display = "none";
    document.getElementById("Main").style.marginLeft = "30px";
    document.getElementById("openNav").style.display = "block";
    document.getElementById("footer").style.marginLeft = "30px";
    document.getElementById("map").style.left = "30px";
    if (typeof map !== 'undefined') map.updateSize();
}

function autosidebar() {
    if (document.getElementById("sidebar") !== null) {	
	if ($(document).width()>700) {
	    sidebar_open();
	} else {
	    sidebar_close();
	}
    }
}

$(window).resize(function () {autosidebar()});
