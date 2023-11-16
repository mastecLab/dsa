function dg_js_init_esri_map(callback) {
    require([
        "esri/Map",
        "esri/views/MapView",
        "esri/views/SceneView",
        "esri/geometry/Geometry",
        "esri/geometry/Point",
        "esri/geometry/ScreenPoint",
        "esri/geometry/Extent",
        "esri/geometry/SpatialReference",
        "esri/layers/FeatureLayer",
        "esri/Basemap",
        "esri/layers/VectorTileLayer"
    ], function(Map, MapView, SceneView, Geometry, Point, ScreenPoint, Extent, SpatialReference, FeatureLayer, Basemap, VectorTileLayer) {
        var context = {};
        context['Map'] = Map;
        context['MapView'] = MapView;
        context['SceneView'] = SceneView;
        context['Geometry'] = Geometry;
        context['Point'] = Point;
        context['ScreenPoint'] = ScreenPoint;
        context['Extent'] = Extent;
        context['SpatialReference'] = SpatialReference;
        context['Basemap'] = Basemap;
        context['VectorTileLayer'] = VectorTileLayer;

        if (!CSSStyleSheet.prototype.removeRule) {
            CSSStyleSheet.prototype.removeRule = CSSStyleSheet.prototype.deleteRule;
        }

        var applyEdits = FeatureLayer.prototype.applyEdits;
        FeatureLayer.prototype.applyEdits = function(src) {
            src['addFeatures'] = JSON.parse(src['addFeatures']);
            src['updateFeatures'] = JSON.parse(src['updateFeatures']);
            src['deleteFeatures'] = JSON.parse(src['deleteFeatures']);
            return applyEdits.apply(this, [src]);
        };

        VectorTileLayer.prototype.setStyle = function(style) {
            var styleMap = style ? JSON.parse(style) : style;
            this.style = styleMap;
        }

        FeatureLayer.prototype.updateRenderer = function(src) {
            this.renderer = JSON.parse(src);
            //console.log(src);
        };

        context['FeatureLayer'] = function(src) {
            //console.log(src);
            src['source'] = JSON.parse(src['source']);
            src['renderer'] = JSON.parse(src['renderer']);
            //console.log(src['renderer']);
            src['fields'] = JSON.parse(src['fields']);
            if (src['popupTemplate']) {
                src['popupTemplate'] = JSON.parse(src['popupTemplate']);
            }
            return new FeatureLayer(src);
        };
        window.esri = context;

        if (dart_require) {
            var esriMapRequire = require;
            require = function(a, b, c) {
                console.log("require: " + a.toString());
                if (a.length > 0 && a[0].indexOf('dart') !== -1) {
                    dart_require(a, b, c);
                } else {
                    esriMapRequire(a, b, c);
                }
            };
        }

        if (callback) {
            callback();
        }
    });
}

var dart_require;
var dart_define;

function dg_js_save_require_context() {
    if (window.require) {
        dart_require = window.require;
        dart_define = window.define;
        window.require = undefined;
        window.define = undefined;
    }
}