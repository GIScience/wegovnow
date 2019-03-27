package require sqlite3
package require n-kov
package require libtiles
encoding system utf-8
fconfigure stdin -encoding utf-8
fconfigure stdout -encoding utf-8





sqlite3 sdb /var/www/gsdr_wgn.sqlite -readonly 1
sdb enable_load_extension true
sdb eval "SELECT load_extension('/usr/local/lib/libsqlitefunctions')"
sdb eval "SELECT load_extension('/usr/local/lib/mod_spatialite')"
#sdb eval "PRAGMA empty_result_callbacks = on"





set geompat "AsGeoJSON* tile2geom* GeoJSON"
set map_keys {{__s__} { } {___} "(" {__v__} {} {__e__} {=} {__ne__} {!=} {__l__} {<} {__g__} {>} {__le__} {<=} {__ge__} {>=} {__a__} {+} {__r__} {-} {__m__} {*} {__d__} {/}}
set map_vals {{___} ")" {__p__} {%} {__c__} {,} {__q__} {'} {__r__} {-} {__m__} {*} {__o__} {:} {__e__} {!} {__q__} {?}}
#for vals space will be processed either as __s__ or " " in a request
set keys {FROM AND OR NOT IN AS BETWEEN JOIN ON LIKE LIMIT SELECT WHERE HAVING {GROUP BY} {ORDER BY} {SELECT DISTINCT} DESC ASC CASE WHEN THEN ELSE END}

#AND OR NOT IN AS BETWEEN JOIN LIKE LIMIT SELECT WHERE HAVING GROUP__s__BY ORDER__s__BY SELECT__s__DISTINCT
set funcs "abs char coalesce glob hex ifnull instr last_insert_rowid length like lower ltrim ltrim max min nullif printf quote random randomblob replace round rtrim soundex sqlite_version substr trim typeof unicode unlikely upper zeroblob avg count count group_concat max min sum total atan2 acosh asinh atanh difference cosh sinh tanh coth power square ceil floor replicate charindex leftstr rightstr ltrim rtrim trim replace reverse proper padl padr padc strfilter stdev variance mode median lower_quartile upper_quartile spatialite_version freexl_version proj4_version geos_version lwgeom_version libxml2_version HasIconv HasMathSQL HasGeoCallbacks HasProj HasGeos HasGeosAdvanced HasGeosTrunk HasGeosReentrant HasGeosOnlyReentrant HasLwGeom HasLibXML2 HasEpsg HasFreeXL HasGeoPackage HasGCP HasTopology CastToInteger CastToDouble CastToText CastToBlob ForceAsNull CreateUUID MD5Checksum MD5TotalChecksum EncodeURL DecodeURL FileExtFromPath GetGpkgMode GetGpkgAmphibiousMode GetDecimalPrecision Abs Acos Asin Atan Atan2 Ceil Cos Cot Degrees Exp Floor Ln Log Log2 Log10 PI Pow Radians Sign Sin Sqrt Stddev_pop Stddev_samp Tan Var_pop Var_samp CvtToKm CvtToDm CvtToCm CvtToMm CvtToKmi CvtToIn CvtToFt CvtToYd CvtToMi CvtToFath CvtToCh CvtToLink CvtToUsIn CvtToUsFt CvtToUsYd CvtToUsMi CvtToUsCh CvtToIndFt CvtToIndYd CvtToIndCh LongLatToDMS LongitudeFromDMS IsZipBlob IsPdfBlob IsGifBlob IsPngBlob IsTiffBlob IsJpegBlob IsExifBlob IsExifGpsBlob IsWebpBlob IsJP2Blob GetMimeType BlobFromFile BlobToFile ST_Point MakePoint MakePointZ MakePointM MakePointZM MakeLine MakeLine MakeLine MakeCircle MakeEllipse MakeArc MakeEllipticArc MakeCircularSector MakeEllipticSector MakeCircularStripe SquareGrid TriangularGrid HexagonalGrid BuildMbr BuildCircleMbr Extent ToGARS GARSMbr MbrMinX MbrMinY MbrMaxX MbrMaxY ST_MinZ ST_MaxZ ST_MinM ST_MaxM GeomFromText ST_WKTToSQL PointFromText LineFromText PolyFromText MPointFromText MLineFromText MPolyFromText GeomCollFromText BdPolyFromText BdMPolyFromText GeomFromWKB ST_WKBToSQL PointFromWKB LineFromWKB PolyFromWKB MPointFromWKB MLineFromWKB MPolyFromWKB GeomCollFromWKB BdPolyFromWKB BdMPolyFromWKB AsText AsWKT AsBinary AsSVG AsKml GeomFromKml AsGml GeomFromGML AsGeoJSON GeomFromGeoJSON AsEWKB GeomFromEWKB AsEWKT GeomFromEWKT AsFGF GeomFromFGF Dimension CoordDimension ST_NDims ST_Is3D ST_IsMeasured GeometryType SRID SetSRID IsEmpty IsSimple IsValid IsValidReason IsValidDetail Boundary Envelope ST_Expand ST_NPoints ST_NRings ST_Reverse ST_ForceLHR CastToPoint CastToLinestring CastToPolygon CastToMultiPoint CastToMultiLinestring CastToMultiPolygon CastToGeometryCollection CastToMulti CastToSingle CastToXY CastToXYZ CastToXYM CastToXYZM X Y Z M StartPoint EndPoint GLength Perimeter GeodesicLength GreatCircleLength IsClosed IsRing PointOnSurface Simplify SimplifyPreserveTopology NumPoints PointN AddPoint SetPoint SetStartPoint SetEndPoint RemovePoint Centroid Area ExteriorRing NumInteriorRing InteriorRingN NumGeometries GeometryN MbrEqual MbrDisjoint MbrTouches MbrWithin MbrOverlaps MbrIntersects ST_EnvIntersects MbrContains Equals Disjoint Touches Within Overlaps Crosses Intersects Contains Covers CoveredBy Relate Distance PtDistWithin Intersection Difference GUnion GUnion SymDifference Buffer ConvexHull HausdorffDistance OffsetCurve SingleSidedBuffer SharedPaths Line_Interpolate_Point Line_Interpolate_Equidistant_Points Line_Locate_Point Line_Substring ClosestPoint ShortestLine Snap Collect LineMerge BuildArea Polygonize MakePolygon UnaryUnion DissolveSegments DissolvePoints LinesFromRings LinesCutAtNodes RingsCutAtNodes CollectionExtract ExtractMultiPoint ExtractMultiLinestring ExtractMultiPolygon ST_Locate_Along_Measure ST_Locate_Between_Measures DelaunayTriangulation VoronojDiagram ConcaveHull MakeValid MakeValidDiscarded Segmentize Split SplitLeft SplitRight Azimuth Project SnapToGrid GeoHash AsX3D MaxDistance ST_3DDistance ST_3DMaxDistance ST_3dLength ST_Node SelfIntersections Transform SridFromAuthCRS ShiftCoords ST_Translate ST_Shift_Longitude NormalizeLonLat ScaleCoords RotateCoords ReflectCoords SwapCoords ATM_Create ATM_CreateTranslate ATM_CreateScale ATM_CreateRotate ATM_CreateXRoll ATM_CreateYRoll ATM_Multiply ATM_Translate ATM_Scale ATM_Rotate ATM_XRoll ATM_YRoll ATM_Determinant ATM_IsInvertible ATM_Invert ATM_IsValid ATM_AsText ATM_Transform GCP_Compute GCP_IsValid GCP_AsText GCP2ATM GCP_Transform SridIsGeographic SridIsProjected SridHasFlippedAxes SridGetSpheroid SridGetPrimeMeridian SridGetDatum SridGetUnit SridGetProjection SridGetAxis_1_Name SridGetAxis_1_Orientation SridGetAxis_2_Name SridGetAxis_2_Orientation levenshteinDistance"


foreach {a b} $map_keys {
    lappend keys $b    
}

foreach f [info commands ::n-kov::tilescf::*] {
    set fname [string range $f [expr {[string last : $f]+1}] end]
    sdb function $fname $f
    lappend funcs $fname
}

proc levenshteinDistance {s t} {
    if {![set n [string length $t]]} {
	return [string length $s]
    } elseif {![set m [string length $s]]} {
	return $n
    }
    for {set i 0} {$i <= $m} {incr i} {
	lappend d 0
	lappend p $i
    }
    for {set j 0} {$j < $n} {} {
	set tj [string index $t $j]
	lset d 0 [incr j]
	for {set i 0} {$i < $m} {} {
	    set a [expr {[lindex $d $i]+1}]
	    set b [expr {[lindex $p $i]+([string index $s $i] ne $tj)}]
	    set c [expr {[lindex $p [incr i]]+1}]
	    lset d $i [expr {$a<$b ? $c<$a ? $c : $a : $c<$b ? $c : $b}]
	}
	set nd $p; set p $d; set d $nd
    }
    return [lindex $p end]
}

sdb function levenshteinDistance levenshteinDistance

proc printf {s args} {return [format $s {*}$args]}
sdb function printf printf



#sdb eval "SELECT load_extension('mod_spatialite.so');"
#sqlite3 dbosh /home/local/rivetfiles/db/sandona.osh.sqlite
#set ivar -123





# https://wiki.tcl-lang.org/48790
# An xxHash32 implementation in pure Tcl with optional Critcl acceleration.
# Copyright (c) 2017 dbohdan
# License: MIT
namespace eval ::xxhash {
    variable version 0.2.1
    variable useCritcl 0
    # The following variable will be true in Jim Tcl and false in Tcl 8.x.
    variable jim [expr {![catch {info version}]}]
    if {![catch {
	package require critcl 3
    }]} {
	set useCritcl [::critcl::compiling]
    }
}

proc ::xxhash::rol {x n} {
    set x [expr {$x & 0xffffffff}]
    return [expr {(($x << $n) | ($x >> (32 - $n))) & 0xffffffff}]
}

if {$::xxhash::useCritcl} {
    critcl::ccommand xxhash::scan-loop {cdata interp objc objv} {#define \
								     XXHASH32_ROL(x,n) ((x << n) | (x >> (32 - n)))
	char *buf;
	int rc, pos = 0, len, i;
	unsigned int v[4], x, seed, hash;
	Tcl_Obj* result;
	const unsigned int prime1 = 0x9e3779b1, prime2 = 0x85ebca77;

	if (objc != 3) {
	    Tcl_WrongNumArgs(interp, 1, objv, "data seed");
	    return TCL_ERROR;
	}
	rc = Tcl_GetIntFromObj(interp, objv[2], &seed);
	if (rc != TCL_OK) {
	    Tcl_SetObjResult(interp,
			     Tcl_NewStringObj("seed must be integer", -1));
	    return TCL_ERROR;
	}

	buf = Tcl_GetByteArrayFromObj(objv[1], &len);
	v[0] = seed + prime1 + prime2;
	v[1] = seed + prime2;
	v[2] = seed;
	v[3] = seed - prime1;
	do {
	    for (i = 0; i < 4; i++) {
				     x = *(unsigned int*)buf;
				     buf += 4;
				     pos += 4;
				     v[i] += x * prime2;
				     v[i] = XXHASH32_ROL(v[i], 13) * prime1;
				 }
	} while (pos <= len - 16);

	hash = (XXHASH32_ROL(v[0], 1)  +
		XXHASH32_ROL(v[1], 7)  +
		XXHASH32_ROL(v[2], 12) +
		XXHASH32_ROL(v[3], 18)) & 0xffffffff;

	result = Tcl_NewListObj(0, NULL);
	rc = Tcl_ListObjAppendElement(interp, result, Tcl_NewWideIntObj(pos));
	if (rc != TCL_OK) {
	    Tcl_SetObjResult(interp, Tcl_ObjPrintf("can't create result list"));
	    return TCL_ERROR;
	}
	rc = Tcl_ListObjAppendElement(interp, result, Tcl_NewWideIntObj(hash));
	if (rc != TCL_OK) {
	    Tcl_SetObjResult(interp, Tcl_ObjPrintf("can't create result list"));
	    return TCL_ERROR;
	}

	Tcl_SetObjResult(interp, result);
	return TCL_OK;
    }
    xxhash::scan-loop {} 0
}

proc ::xxhash::xxhash32 {data seed} {
    variable jim

    set prime1 0x9e3779b1
    set prime2 0x85ebca77
    set prime3 0xc2b2ae3d
    set prime4 0x27d4eb2f
    set prime5 0x165667b1

    set ptr 0
    set len [string [expr {$jim ? {bytelength} : {length}}] $data]
    if {$len >= 16} {
	if {$::xxhash::useCritcl} {
	    lassign [xxhash::scan-loop $data $seed] ptr hash
	} else {
	    set limit [expr {$len - 16}]
	    set v1 [expr {$seed + $prime1 + $prime2}]
	    set v2 [expr {$seed + $prime2}]
	    set v3 $seed
	    set v4 [expr {$seed - $prime1}]

	    while 1 {
		binary scan $data "@$ptr iu iu iu iu" x1 x2 x3 x4
		incr ptr 16

		incr v1 [expr {$x1 * $prime2}]
		set v1 [expr {[rol $v1 13] * $prime1}]

		incr v2 [expr {$x2 * $prime2}]
		set v2 [expr {[rol $v2 13] * $prime1}]

		incr v3 [expr {$x3 * $prime2}]
		set v3 [expr {[rol $v3 13] * $prime1}]

		incr v4 [expr {$x4 * $prime2}]
		set v4 [expr {[rol $v4 13] * $prime1}]

		if {$ptr > $limit} break
	    }

	    set hash [expr {
			    ([rol $v1 1] + [rol $v2 7] + [rol $v3 12] + [rol $v4 18])
			    & 0xffffffff
			}]
	}
    } else {
	set hash [expr {$seed + $prime5}]
    }

    incr hash $len

    set limit [expr {$len - 4}]
    while {$ptr <= $limit} {
	binary scan $data "@$ptr iu" x
	set hash [expr {$hash + $x * $prime3}]
	set hash [expr {[rol $hash 17] * $prime4}]
	incr ptr 4
    }

    while {$ptr < $len} {
	binary scan $data "@$ptr cu" x
	set hash [expr {$hash + $x * $prime5}]
	set hash [expr {[rol $hash 11] * $prime1}]
	incr ptr 1
    }

    set hash [expr {$hash & 0xffffffff}]
    set hash [expr {(($hash ^ ($hash >> 15)) * $prime2) & 0xffffffff}]
    set hash [expr {(($hash ^ ($hash >> 13)) * $prime3) & 0xffffffff}]
    set hash [expr {($hash ^ ($hash >> 16)) & 0xffffffff}]

    return $hash
}

proc ::xxhash::assert-equal-int {actual expected} {
    if {$actual != $expected} {
	error "expected 0x[format %08x $expected],\
               but got 0x[format %08x $actual]"
    }
}
