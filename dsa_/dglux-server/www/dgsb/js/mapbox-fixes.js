mapboxgl.Map.prototype.dgAddLayerFixed = function(layer, before) {
  // hack to fix unimplemented feature in package:js
  // transforms key names: a_b_c => a-b-c
  if (layer.paint) {
    var oldPaint = layer.paint;
    layer.paint = {};

    Object.keys(oldPaint).forEach(function(key) {
      var newKey = key.split('_').join('-');
      layer.paint[newKey] = oldPaint[key];
    });
  }

  if (layer.layout) {
    var oldLayout = layer.layout;
    layer.layout = {};

    Object.keys(oldLayout).forEach(function(key) {
      var newKey = key.split('_').join('-');
      layer.layout[newKey] = oldLayout[key];
    });
  }

  mapboxgl.Map.prototype.addLayer.call(this, layer, before);
};

mapboxgl.Map.prototype.dgExposeToInterop = function() {
  mapboxgl.fixes.exposedMap = this;
};

mapboxgl.Map.prototype.dgHideFromInterop = function() {
  mapboxgl.fixes.exposedMap = null;
};

mapboxgl.Map.prototype.dgExposeToDebug = function() {
  mapboxgl.fixes.debugMap = this;
};

mapboxgl.Map.prototype.dgFitBounds = function(arr, speed) {
  try {
    mapboxgl.Map.prototype.fitBounds.call(this, arr, { speed: speed });
  } catch(e) {
    console.log(e);
  }  
};

// combine these into a single step
// makes debugging easier to have this in JavaScript
mapboxgl.Map.prototype.dgAddImage = function(name, url, callback) {
  mapboxgl.Map.prototype.loadImage.call(this, url, function(error, image) {
    if (error) {
      throw error;
    }

    mapboxgl.Map.prototype.addImage.call(this, name, image);
    callback();
  }.bind(this));
};

// similar to requestAnimationFrame, but instead for making sure the map source reloads
// https://github.com/mapbox/mapbox-gl-js/issues/3692
mapboxgl.Map.prototype.dgRequestSetDataFrame = function(sourceId, callback) {
  var countdown = 2;

  var dataCallback = (function() {
    if (this.style.sourceCaches[sourceId].loaded()) {
      if (--countdown === 0) callback();
    } else {
      this.once('data', dataCallback);
    }
  }).bind(this);

  dataCallback();

  requestAnimationFrame(function(now) {
    if (--countdown === 0) callback();
  });
};

// most all of these are to work around Dart having no really performant way
// to convert a Dart Map to a JS object
mapboxgl.fixes = {
  // convert DGLux table data into a JS object
  createFeatureProperties: function(columns, data) {
    var map = {};

    var i = 0;
    var length = columns.length;

    for (; i < length; i++) {
      map[columns[i]] = isNaN(Number(data[i])) ? data[i] : Number(data[i]);
    }

    return map;
  },
  getJsonString: function(obj) {
    return JSON.stringify(obj);
  },
  // use JSON.parse instead of Dart's JSON.decode so we can make Mapbox use the
  // data as GeoJSON
  createJsonSource: function(str) {
    return JSON.parse(str);
  },
  getKeyFromJSObject: function(obj, key, _) {
    return obj[key] || _;
  },
  getKeysFromJSObject: function(obj) {
      return Object.keys(obj)|| [];
  },
  printDebug: function(jsObject) {
    console.log(jsObject);
  }
};

/*
["addSource",
  "removeSource",
  "addLayer",
  "removeLayer",
  "setFilter",
  "getFilter",
  "setPaintProperty",
  "setTransitionDuration",
  "setLayoutProperty",
  "dgAddLayerFixed"].forEach((mName) => {
    var method = mapboxgl.Map.prototype[mName];

    mapboxgl.Map.prototype[mName] = function() {
      var args = Array.prototype.slice.call(arguments);
      console.log(`${mName}: `, args);
      method.apply(this, args);
    }
  });
  */