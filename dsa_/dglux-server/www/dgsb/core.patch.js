
WebKitPoint = function(x, y){
 this.x = x;
 this.y = y;
};

function multiply(a, b) {
  var r = [], i, j, k, t;
  for (i = 0; i < a.length; i++) {
    for (j = 0; j < b[0].length; j++) {
      t = 0;
      for (k = 0; k < a[0].length; k++) {
        t += a[i][k] * b[k][j];
      }
      r[i] = r[i] || [];
      r[i][j] = t;
    }
  }
  return r;
}

function matrixFromCssString(c) {
  c = c.match(/matrix3?d?\(([^\)]+)\)/i)[1].split(',');

  if (c.length === 6) {
    c = [c[0], c[1], 0, 0, c[2], c[3], 0, 0, 0, 0, 1, 0, c[4], c[5], 0, 1];
  }
  var i, j, m = [];
  for (i = 0; i < 4; i++) {
    for (j = 0; j < 4; j++) {
      m[i] = m[i] || [];
      m[i][j] = parseFloat(c[j * 4 + i]);
    }
  }
  return m;
}

function translate(m/*, tx, ty, tz*/) {
  var i, j, r = [];
  for (i = 0; i < 4; i++) {
    r[i] = [];
    for (j = 0; j < 4; j++) {
      r[i][j] = m[i][j] + (j === 3 ? +arguments[1 + i] || 0 : 0);
    }
  }
  return r;
}

function boundingClientRect(element, transformationMatrix, width, height) {
  var points = multiply(transformationMatrix, [
    [0, width, 0, width],
    [0, 0, height, /*0, */height], // tried to fix bug when algorithm is not working correctly for rotation 90..180 and -90..-180
    [0, 0, 0, 0],
    [1, 1, 1, 1]
  ]);

  return {
    left:   Math.min.apply(Math, points[0]),
    top:    Math.min.apply(Math, points[1])
    //right:  Math.max.apply(Math, points[0]),  right, bottom - is not used currently, cut off
    //bottom: Math.max.apply(Math, points[1])
  };
}

var buggyResult;

var buggy = function () {
  if (buggyResult == null) {
    var div, rect;
    div = document.createElement('div');
    div.style.cssText = 'width:200px;height:200px;position:fixed;-moz-transform:scale(2);';
    document.body.appendChild(div);
    rect = div.getBoundingClientRect();
    buggyResult = !!(getComputedStyle(div, null).MozTransform && (rect.bottom - rect.top < 300));//!

    div.parentNode.removeChild(div);
    div = null;
    rect = null;
  }
  return buggyResult;
};

var getMatrixResults = {};

var internalIDs = 0;

var dgGlobalScrollHandlerSet = false;

var dgPageXOffset = 0;
var dgPageYOffset = 0;

//clear getMatrixResults cache for the element
function clearConvertPointCache(element) {
    if (!element['internalID']) return;
    getMatrixResults[element['internalID']] = null;
}

function getTransformationMatrix(element) {
	if (!dgGlobalScrollHandlerSet) {
		dgPageXOffset = window.pageXOffset;
		dgPageYOffset = window.pageYOffset;
		window.addEventListener('onscroll',
			function(e) {
				dgPageXOffset = window.pageXOffset;
				dgPageYOffset = window.pageYOffset;
			});
		dgGlobalScrollHandlerSet = true;
	}

	if (!element['internalID']) {
		element['internalID'] = internalIDs++;
	}

	var res = getMatrixResults[element['internalID']];
	if (!res) {
		res = getTransformationMatrixHelper(element);
		getMatrixResults[element['internalID']] = res;
		setTimeout(function () {
				getMatrixResults[element['internalID']] = null;
			}, 25);
	}
	return res;
}

function getTransformationMatrixHelper(element) {
  var identity = matrixFromCssString('matrix(1,0,0,1,0,0)'),
      transformationMatrix = identity,
      x = element,
      parentRect, rect, t, c, r, origin, computedStyle, inverseOrigin;

  var zoom = 1;

  while (x && x !== document.documentElement) {
    computedStyle = getComputedStyle(x, null) || {};

    zoom *= computedStyle.zoom || 1;

    // origin and t matrices required only for Firefox (buggy getBoundingClientRect)
    rect = x.getBoundingClientRect();
    parentRect = x.parentNode && x.parentNode.getBoundingClientRect ? x.parentNode.getBoundingClientRect() : rect;
    t = translate(identity, rect.left - parentRect.left, rect.top - parentRect.top, 0);

	// transform resolved value (value from getComputedStyle) is always matrix or "none" (or undefined if property is not supported)
    c = computedStyle.OTransform || computedStyle.WebkitTransform || computedStyle.msTransform || computedStyle.MozTransform || 'none';
    if (c !== 'none') {
    	c = matrixFromCssString(c);

	    origin = computedStyle.OTransformOrigin || computedStyle.WebkitTransformOrigin || computedStyle.msTransformOrigin || computedStyle.MozTransformOrigin || '0 0';

	    // Firefox gives "50% 50%" when there is no transform
	    if (origin.indexOf('%') !== -1) {
	      origin = '0 0';
	    }

	    origin = origin.split(' ');

	    var ox = parseFloat(origin[0]) || 0;
	    var oy = parseFloat(origin[1]) || 0;
	    var oz = parseFloat(origin[2]) || 0;

	    if (ox === 0 && oy === 0 && oz === 0) {
	    	transformationMatrix = multiply(multiply(t, c), transformationMatrix);
	    } else {
	    	origin = translate(identity, ox, oy, oz);

		    // transformationMatrix = t * origin * c * origin^-1 * transformationMatrix
		    inverseOrigin = translate(identity, -ox, -oy, -oz);
		    transformationMatrix = multiply(multiply(multiply(multiply(t, origin), c), inverseOrigin), transformationMatrix);
		}
	} else {
		transformationMatrix = multiply(t, transformationMatrix);
	}

    x = x.parentNode;
  }

  var ew,eh;
  transformationMatrix = translate(transformationMatrix, dgPageXOffset, dgPageYOffset, 0);
  if (!buggy()) {
  	// SVGElement doesn't have offsetWidth, offsetHeight etc.
    if (element instanceof SVGElement) {
	  var bbox = element.getBBox();  // getBBox - last chance to get width and height in local coordinates
	  ew = bbox.width;
	  eh = bbox.height;
    } else {
      ew = element.offsetWidth;
      eh = element.offsetHeight;
    }
    r = boundingClientRect(element, transformationMatrix, ew, eh);
    rect = element.getBoundingClientRect(element);
    transformationMatrix = translate(transformationMatrix, rect.left + dgPageXOffset - r.left, rect.top + dgPageYOffset - r.top, 0);
  }
  // VSTS: https://ablcode.visualstudio.com/DGIoTPlatform/DGLux 5/_workitems?id=95580
  //zoom *= (getComputedStyle(document.documentElement, null) || {}).zoom || 1;
  if (zoom != 1) {
    // we should apply zoom
    transformationMatrix[0][0] *= zoom;
    transformationMatrix[1][1] *= zoom;
    transformationMatrix[0][3] *= zoom;
    transformationMatrix[1][3] *= zoom;
  }
  return transformationMatrix;
}

function invert(m) {
  // only for 4x4 matrix
  var s0 = m[0][0] * m[1][1] - m[1][0] * m[0][1];
  var s1 = m[0][0] * m[1][2] - m[1][0] * m[0][2];
  var s2 = m[0][0] * m[1][3] - m[1][0] * m[0][3];
  var s3 = m[0][1] * m[1][2] - m[1][1] * m[0][2];
  var s4 = m[0][1] * m[1][3] - m[1][1] * m[0][3];
  var s5 = m[0][2] * m[1][3] - m[1][2] * m[0][3];

  var c5 = m[2][2] * m[3][3] - m[3][2] * m[2][3];
  var c4 = m[2][1] * m[3][3] - m[3][1] * m[2][3];
  var c3 = m[2][1] * m[3][2] - m[3][1] * m[2][2];
  var c2 = m[2][0] * m[3][3] - m[3][0] * m[2][3];
  var c1 = m[2][0] * m[3][2] - m[3][0] * m[2][2];
  var c0 = m[2][0] * m[3][1] - m[3][0] * m[2][1];

  // Should check for 0 determinant
  var invdet = 1.0 / (s0 * c5 - s1 * c4 + s2 * c3 + s3 * c2 - s4 * c1 + s5 * c0);

  var b = matrixFromCssString('matrix(1,0,0,1,0,0)');

  b[0][0] = ( m[1][1] * c5 - m[1][2] * c4 + m[1][3] * c3) * invdet;
  b[0][1] = (-m[0][1] * c5 + m[0][2] * c4 - m[0][3] * c3) * invdet;
  b[0][2] = ( m[3][1] * s5 - m[3][2] * s4 + m[3][3] * s3) * invdet;
  b[0][3] = (-m[2][1] * s5 + m[2][2] * s4 - m[2][3] * s3) * invdet;
  b[1][0] = (-m[1][0] * c5 + m[1][2] * c2 - m[1][3] * c1) * invdet;
  b[1][1] = ( m[0][0] * c5 - m[0][2] * c2 + m[0][3] * c1) * invdet;
  b[1][2] = (-m[3][0] * s5 + m[3][2] * s2 - m[3][3] * s1) * invdet;
  b[1][3] = ( m[2][0] * s5 - m[2][2] * s2 + m[2][3] * s1) * invdet;
  b[2][0] = ( m[1][0] * c4 - m[1][1] * c2 + m[1][3] * c0) * invdet;
  b[2][1] = (-m[0][0] * c4 + m[0][1] * c2 - m[0][3] * c0) * invdet;
  b[2][2] = ( m[3][0] * s4 - m[3][1] * s2 + m[3][3] * s0) * invdet;
  b[2][3] = (-m[2][0] * s4 + m[2][1] * s2 - m[2][3] * s0) * invdet;
  b[3][0] = (-m[1][0] * c3 + m[1][1] * c1 - m[1][2] * c0) * invdet;
  b[3][1] = ( m[0][0] * c3 - m[0][1] * c1 + m[0][2] * c0) * invdet;
  b[3][2] = (-m[3][0] * s3 + m[3][1] * s1 - m[3][2] * s0) * invdet;
  b[3][3] = ( m[2][0] * s3 - m[2][1] * s1 + m[2][2] * s0) * invdet;

  return b;
}

var convertPointFromPageToNode = function (element, pagept, topLeftElement) {
  /*
      cx = a11 a12 a14   x
      cy = a21 a22 a24   y
       1 =   0   0   1   1
  */
  var xCorrection = 0;
  var yCorrection = 0;
  if (Object.prototype.toString.call(element).slice(8, -1) == 'SVGPathElement') {
    var bounds = element.getBBox();
    xCorrection = bounds.x;
    yCorrection = bounds.y;
  }
  var a = translate(getTransformationMatrix(element), dgPageXOffset, dgPageYOffset, 0);
  var pt = new WebKitPoint(((pagept.x - a[0][3]) * a[1][1] - (pagept.y - a[1][3]) * a[0][1]) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) + xCorrection,
    (a[0][0] * (pagept.y - a[1][3]) - a[1][0] * (pagept.x - a[0][3])) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) + yCorrection);

  //do convertPointFromNodeToPage relative to topLeftElement in Safari or IOS when zoomed. Helps to fix coordinates
    if (topLeftElement) {
        if (Object.prototype.toString.call(topLeftElement).slice(8, -1) == 'SVGPathElement') {
            var bounds = topLeftElement.getBBox();
            xCorrection = bounds.x;
            yCorrection = bounds.y;
        }
        a = translate(getTransformationMatrix(topLeftElement), dgPageXOffset, dgPageYOffset, 0);
        a = invert(a);
        pt = new WebKitPoint(((pt.x - a[0][3]) * a[1][1] - (pt.y - a[1][3]) * a[0][1]) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) - xCorrection,
            (a[0][0] * (pt.y - a[1][3]) - a[1][0] * (pt.x - a[0][3])) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) - yCorrection);
    }
    return pt;
};

var convertPointFromNodeToPage = function (element, elementpt, topLeftElement) {
  var xCorrection = 0;
  var yCorrection = 0;
  if (Object.prototype.toString.call(element).slice(8, -1) == 'SVGPathElement') {
    var bounds = element.getBBox();
    xCorrection = bounds.x;
    yCorrection = bounds.y;
  }
  var a = translate(getTransformationMatrix(element), dgPageXOffset, dgPageYOffset, 0);
  a = invert(a);
  var pt = new WebKitPoint(((elementpt.x - a[0][3]) * a[1][1] - (elementpt.y - a[1][3]) * a[0][1]) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) - xCorrection,
    (a[0][0] * (elementpt.y - a[1][3]) - a[1][0] * (elementpt.x - a[0][3])) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) - yCorrection);

  //do convertPointFromPageToNode relative to topLeftElement in Safari or IOS when zoomed. Helps to fix coordinates
  if (topLeftElement) {
      if (Object.prototype.toString.call(topLeftElement).slice(8, -1) == 'SVGPathElement') {
          var bounds = topLeftElement.getBBox();
          xCorrection = bounds.x;
          yCorrection = bounds.y;
      }
      a = translate(getTransformationMatrix(topLeftElement), dgPageXOffset, dgPageYOffset, 0);
      pt = new WebKitPoint(((pt.x - a[0][3]) * a[1][1] - (pt.y - a[1][3]) * a[0][1]) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) + xCorrection,
          (a[0][0] * (pt.y - a[1][3]) - a[1][0] * (pt.x - a[0][3])) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) + yCorrection);
  }

  return pt;
};



// custom jsonp loader with iframe

jsonpLoaderCallback = null;
function jsonpLoaderInit(callback){
  jsonpLoaderCallback = callback;
}
function jsonpLoaderCreate(id, url, callbackName){
  var frame = document.createElement('iframe');
  frame.width='5px';
  frame.height='5px';
  frame.id=id;
  frame.style.position = 'absolute';
  frame.style.visibility = 'hidden';
  frame.style.zIndex = -1;
  document.body.appendChild(frame);

  var cDoc = frame.contentWindow.document;
  var cDocScript1 = "<script type='text/javascript'>jsonRslt='';";
  var nameParts = callbackName.split('.');
  if (nameParts.length > 1){
    nameParts.pop();
    for (var i = 1;i <= nameParts.length;++i){
      cDocScript1 = cDocScript1 + nameParts.slice(0,i).join('.')+"={};";
    }
  }
  cDocScript1 = cDocScript1 + callbackName + "=function(data){jsonRslt = JSON.stringify(data);}</script>"
  cDoc.write(cDocScript1);
  cDoc.write("<script type='text/javascript' src='"+url+"'></script>");
  cDoc.write("<script type='text/javascript'>window.parent.jsonpLoaderFinished('" + id + "', jsonRslt)</script>");

}
function jsonpLoaderFinished(id, data){
  frame = document.getElementById(id);
  if (frame != null){
    frame.remove();
  }
  if (jsonpLoaderCallback != null){
    jsonpLoaderCallback(id, data);
  }
}


var allGMapItems = [];

function initializeGMap() {
  if (initializeGMapCallback != null) {
    initializeGMapCallback();

    var defaultPolylineConstructor = google.maps.Polyline;
    function newPolylineConstructor(params) {
    	defaultPolylineConstructor.call(this, params);
		allGMapItems.push(this);
    }
    newPolylineConstructor.prototype = Object.create(defaultPolylineConstructor.prototype);
    newPolylineConstructor.prototype.constructor = newPolylineConstructor;
    google.maps.Polyline = newPolylineConstructor;


	var defaultMarkerConstructor = google.maps.Marker;
    function newMarkerConstructor(params) {
    	defaultMarkerConstructor.call(this, params);
		allGMapItems.push(this);
    }
    newMarkerConstructor.prototype = Object.create(defaultMarkerConstructor.prototype);
    newMarkerConstructor.prototype.constructor = newMarkerConstructor;
    google.maps.Marker = newMarkerConstructor;


	var defaultPolygonConstructor = google.maps.Polygon;
    function newPolygonConstructor(params) {
	 	defaultPolygonConstructor.call(this, params);
		allGMapItems.push(this);
	}
    newPolygonConstructor.prototype = Object.create(defaultPolygonConstructor.prototype);
    newPolygonConstructor.prototype.constructor = newPolygonConstructor;
    google.maps.Polygon = newPolygonConstructor;


	var defaultRectConstructor = google.maps.Rectangle;
    function newRectConstructor(params) {
		defaultRectConstructor.call(this, params);
		allGMapItems.push(this);
	}
    newRectConstructor.prototype = Object.create(defaultRectConstructor.prototype);
    newRectConstructor.prototype.constructor = newRectConstructor;
    google.maps.Rectangle = newRectConstructor;


	var defaultCircleConstructor = google.maps.Circle;
    function newCircleConstructor(params) {
		defaultCircleConstructor.call(this, params);
		allGMapItems.push(this);
	}
    newCircleConstructor.prototype = Object.create(defaultCircleConstructor.prototype);
    newCircleConstructor.prototype.constructor = newCircleConstructor;
    google.maps.Circle = newCircleConstructor;


	var defaultGroundOverlayConstructor = google.maps.GroundOverlay;
    function newGroundOverlayConstructor(a, b) {
		defaultGroundOverlayConstructor.call(this, a, b);
		allGMapItems.push(this);
	}
    newGroundOverlayConstructor.prototype = Object.create(defaultGroundOverlayConstructor.prototype);
    newGroundOverlayConstructor.prototype.constructor = newGroundOverlayConstructor;
    google.maps.GroundOverlay = newGroundOverlayConstructor;


	var defaultCustomOverlayConstructor = google.maps.OverlayView;
    function newCustomOverlayConstructor() {
		defaultCustomOverlayConstructor.call(this);
		allGMapItems.push(this);
	}
    newCustomOverlayConstructor.prototype = Object.create(defaultCustomOverlayConstructor.prototype);
    newCustomOverlayConstructor.prototype.constructor = newCustomOverlayConstructor;
    google.maps.OverlayView = newCustomOverlayConstructor;


	var defaultFusionTablesLayerConstructor = google.maps.FusionTablesLayer;
    function newFusionTablesLayerConstructor(params) {
		defaultFusionTablesLayerConstructor.call(this, params);
		allGMapItems.push(this);
	}
    newFusionTablesLayerConstructor.prototype = Object.create(defaultFusionTablesLayerConstructor.prototype);
    newFusionTablesLayerConstructor.prototype.constructor = newFusionTablesLayerConstructor;
    google.maps.FusionTablesLayer = newFusionTablesLayerConstructor;


	var defaultKmlLayerConstructor = google.maps.KmlLayer;
    function newKmlLayerConstructor(params) {
		defaultKmlLayerConstructor.call(this, params);
		allGMapItems.push(this);
	}
    newKmlLayerConstructor.prototype = Object.create(defaultKmlLayerConstructor.prototype);
    newKmlLayerConstructor.prototype.constructor = newKmlLayerConstructor;
    google.maps.KmlLayer = newKmlLayerConstructor;


	var defaultTrafficLayerConstructor = google.maps.TrafficLayer;
    function newTrafficLayerConstructor() {
		defaultTrafficLayerConstructor.call(this);
		allGMapItems.push(this);
	}
	newTrafficLayerConstructor.prototype = Object.create(defaultTrafficLayerConstructor.prototype);
    newTrafficLayerConstructor.prototype.constructor = newTrafficLayerConstructor;
    google.maps.TrafficLayer = newTrafficLayerConstructor;


	var defaultTransitLayerConstructor = google.maps.TransitLayer;
    function newTransitLayerConstructor() {
		defaultTransitLayerConstructor.call(this);
		allGMapItems.push(this);
	}
    newTransitLayerConstructor.prototype = Object.create(defaultTransitLayerConstructor.prototype);
    newTransitLayerConstructor.prototype.constructor = newTransitLayerConstructor;
    google.maps.TransitLayer = newTransitLayerConstructor;


	var defaultBicyclingLayerConstructor = google.maps.BicyclingLayer;
    function newBicyclingLayerConstructor() {
		defaultBicyclingLayerConstructor.call(this);
		allGMapItems.push(this);
	}
    newBicyclingLayerConstructor.prototype = Object.create(defaultBicyclingLayerConstructor.prototype);
    newBicyclingLayerConstructor.prototype.constructor = newBicyclingLayerConstructor;
    google.maps.BicyclingLayer = newBicyclingLayerConstructor;


  }
}


function clearGMapStuff(map) {
	var aliveItems = [];
	var n = allGMapItems.length;
	var item;
	for(var i = 0; i < n; i++) {
	 	item = allGMapItems[i];
		if (item.map == map) {
			item.setMap(null);
		} else if (item.map != null) {
			aliveItems.push(item);
		}
	}
	allGMapItems = aliveItems;
}

if (window.navigator.msSaveBlob != null) {
  dgMsSaveBlob = function(a,b){
    window.navigator.msSaveBlob(a,b);
  }
}

// for correct work of 'beforeunload' event listeners

var beforeUnloadMessage;
var fSkipChangesCheck = false; // to ignore repeated events (IE11 bug)

function addBeforeUnloadListener(message) {
  beforeUnloadMessage = message;
  window.addEventListener('beforeunload', showBeforeUnloadWarning);
}

function removeBeforeUnloadListener() {
  window.removeEventListener('beforeunload', showBeforeUnloadWarning);
}

function showBeforeUnloadWarning(e) {
  if (!fSkipChangesCheck) {
    disableBeforeUnloadEvents();
    e.returnValue = beforeUnloadMessage;
    return beforeUnloadMessage;
  }
}

function disableBeforeUnloadEvents() {
  fSkipChangesCheck = true;
  setTimeout("enableBeforeUnloadEvents()", "100"); // in next 100 ms we will ignore 'beforeunload' events
}

function enableBeforeUnloadEvents() {
  fSkipChangesCheck = false;
}

function dartDeferredLibraryLoader(uri, successCallback, errorCallback) {
    var e = document.createElement("script");
    e.type = "text/javascript";

    var baseURL;
    var n = document.scripts.length;
    for (var i = 0; i < n; i++) {
        if (document.scripts[i]['src'].indexOf('core.patch.js') >= 0) {
            baseURL = document.scripts[i]['src'].substring(0, document.scripts[i]['src'].indexOf('core.patch.js'));
            break;
        }
    }

    if (baseURL == null) {
        var libSrc = window.location.href;
        var pos1 = libSrc.lastIndexOf(".html");
        if (pos1 > 0) {
            libSrc = libSrc.substring(0, pos1);
        }
        libSrc = libSrc.substring(0, libSrc.lastIndexOf("/"));
        baseURL = libSrc
    }

    var pos = uri.lastIndexOf('/');

    if (baseURL != null && baseURL.lastIndexOf('/') == baseURL.length - 1) {
        baseURL = baseURL.substring(0, baseURL.length - 1);
    }

    libSrc =  baseURL + (pos >= 0 ? uri.substring(pos) : '/' + uri);
    e.src = libSrc;
    e.addEventListener("load", successCallback, false);
    e.addEventListener("error", errorCallback, false);
    document.body.appendChild(e);
}

function getCompassHeading(event){
  if (event.webkitCompassHeading) {
    return event.webkitCompassHeading;
  } else {
    return (360 - event.alpha) % 360;
  }
}

// extends function for typescript

var __extends = (this && this.__extends) || function (d, b) {
    for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p];
    function __() { this.constructor = d; }
    d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
};

// dgluxjs compiled from https://github.com/dglogik/dglux5_js_widget

var dgluxjs;
(function (dgluxjs) {
    var getDgModelValue;
    var setDgModelValue;
    var updateDgModelValue;
    var updateDgModelTable;
    var getDgTableRows;
    var getDgTableColumns;
    var getDgResourceUrl;
    var getDgObjectType;
    function getObjectType(value) {
        var result = typeof value;
        if (result == 'object') {
            if (getDgObjectType != null) {
                return getDgObjectType(value);
            }
        }
        return result;
    }
    dgluxjs.getObjectType = getObjectType;
    function getTableRows(value) {
        return getDgTableRows(value);
    }
    dgluxjs.getTableRows = getTableRows;
    function getTableColumns(value) {
        return getDgTableColumns(value);
    }
    dgluxjs.getTableColumns = getTableColumns;
    function updateStorage(key, value, session) {
        var storage;
        if (session) {
            storage = window.sessionStorage;
            key = 'dgs::' + key;
        }
        else {
            storage = window.localStorage;
            key = 'dg::' + key;
        }
        var oldVal = storage[key];
        storage[key] = value;
        var se = document.createEvent('StorageEvent');
        se.initStorageEvent('storage', false, false, key, oldVal, value, '/', storage);
        window.dispatchEvent(se);
    }
    dgluxjs.updateStorage = updateStorage;
    var Widget = (function () {
        function Widget(div, model) {
            this.destroyed = false;
            this.parentDiv = div;
            this._model = model;
        }
        Widget.prototype.getDefinition = function () {
            return {
                "name": "",
                "variables": [],
                "layout": {
                    "type": "vbox",
                    "children": []
                }
            };
        };
        ;
        Widget.prototype.setModel = function (model) {
            this._model = model;
        };
        Widget.prototype.getModelValue = function (field) {
            return getDgModelValue(this._model, field);
        };
        Widget.prototype.setModelValue = function (field, value) {
            setDgModelValue(this._model, field, value);
        };
        Widget.prototype.updateModelValue = function (field, value) {
            updateDgModelValue(this._model, field, value);
        };
        Widget.prototype.updateModelTable = function (field, columns, rows) {
            updateDgModelTable(this._model, field, columns, rows);
        };
        Widget.prototype.getResourceUrl = function (value) {
            return getDgResourceUrl(this._model, value);
        };
        Widget.prototype.getPropMap = function () {
            return Widget._blankPropMap;
        };
        Widget.prototype.commitProperties = function (changes) {
            var map = this.getPropMap();
            if (changes == null) {
                for (var key in map) {
                    map[key](this, this.getModelValue(key));
                }
            }
            else {
                for (var i in changes) {
                    var key = changes[i];
                    var callback = map[key];
                    if (callback != null) {
                        callback(this, this.getModelValue(key));
                    }
                }
            }
        };
        /* will be called when definition.size == 'sensor' */
        Widget.prototype.onResize = function () {
        };
        Widget.prototype.destroy = function () {
        };
        Widget._blankPropMap = {};
        return Widget;
    }());
    dgluxjs.Widget = Widget;
    function setDgJsCallback(requireCallback, defineCallback, getModelValueCallback, setModelValueCallback, updateModelValueCallback, updateModelTableCallback, getTableRowsCallback, getTableColumnsCallback, getResourceUrlCallback, getObjectTypeCallback) {
        window['require'] = requireCallback;
        window['define'] = defineCallback;
        getDgModelValue = getModelValueCallback;
        setDgModelValue = setModelValueCallback;
        updateDgModelValue = updateModelValueCallback;
        updateDgModelTable = updateModelTableCallback;
        getDgTableRows = getTableRowsCallback;
        getDgTableColumns = getTableColumnsCallback;
        getDgResourceUrl = getResourceUrlCallback;
        getDgObjectType = getObjectTypeCallback;
    }
    dgluxjs.setDgJsCallback = setDgJsCallback;
    function callJsFunction(func, args) {
        return func.apply(null, args);
    }
    dgluxjs.callJsFunction = callJsFunction;
    function newDgJsWidget(module, div, model) {
        if (module.hasOwnProperty("dgNewWidget")) {
            return module["dgNewWidget"](div, model);
        }
        return null;
    }
    dgluxjs.newDgJsWidget = newDgJsWidget;
})(dgluxjs || (dgluxjs = {}));
