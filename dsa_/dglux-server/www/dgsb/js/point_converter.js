
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

function boundingClientRect(element, transformationMatrix) {
  var points = multiply(transformationMatrix, [
    [0, element.offsetWidth, 0, element.offsetWidth],
    [0, 0, element.offsetHeight, 0, element.offsetHeight],
    [0, 0, 0, 0],
    [1, 1, 1, 1]
  ]);

  return {
    left:   Math.min.apply(Math, points[0]),
    top:    Math.min.apply(Math, points[1]),
    right:  Math.max.apply(Math, points[0]),
    bottom: Math.max.apply(Math, points[1])
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

function getTransformationMatrix(element) {
  var identity = matrixFromCssString('matrix(1,0,0,1,0,0)'),
      transformationMatrix = identity,
      x = element,
      parentRect, rect, t, c, r, origin, computedStyle, inverseOrigin;

  while (x && x !== document.documentElement) {
    computedStyle = getComputedStyle(x, null) || {};

    // origin and t matrices required only for Firefox (buggy getBoundingClientRect)
    rect = x.getBoundingClientRect();
    parentRect = x.parentNode && x.parentNode.getBoundingClientRect ? x.parentNode.getBoundingClientRect() : rect;
    t = translate(identity, rect.left - parentRect.left, rect.top - parentRect.top, 0);

    c = (computedStyle.OTransform || computedStyle.WebkitTransform || computedStyle.msTransform ||  computedStyle.MozTransform || 'none').replace(/^none$/, 'matrix(1,0,0,1,0,0)');
    c = matrixFromCssString(c);

    origin = computedStyle.OTransformOrigin || computedStyle.WebkitTransformOrigin || computedStyle.msTransformOrigin || computedStyle.MozTransformOrigin || '0 0';
    // Firefox gives "50% 50%" when there is no transform
    if (origin.indexOf('%') !== -1) {
      origin = '0 0';
    }
    origin = origin.split(' ');
    origin = translate(identity, parseFloat(origin[0]), parseFloat(origin[1]), parseFloat(origin[2] || 0));

    // transformationMatrix = t * origin * c * origin^-1 * transformationMatrix
    inverseOrigin = translate(identity, -origin[0][3], -origin[1][3], -origin[2][3]);
    transformationMatrix = multiply(multiply(multiply(multiply(t, origin), c), inverseOrigin), transformationMatrix);

    x = x.parentNode;
  }

  transformationMatrix = translate(transformationMatrix, -window.pageXOffset, -window.pageYOffset, 0);
  if (!buggy()) {
    r = boundingClientRect(element, transformationMatrix);
    rect = element.getBoundingClientRect(element);
    transformationMatrix = translate(transformationMatrix, rect.left - r.left, rect.top - r.top, 0);
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

var convertPointFromPageToNode = function (element, pagept) {
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
  var a = translate(getTransformationMatrix(element), window.pageXOffset, window.pageYOffset, 0);
  var pt = new WebKitPoint(((pagept.x - a[0][3]) * a[1][1] - (pagept.y - a[1][3]) * a[0][1]) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) + xCorrection,
    (a[0][0] * (pagept.y - a[1][3]) - a[1][0] * (pagept.x - a[0][3])) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) + yCorrection);
  return pt;
};

var convertPointFromNodeToPage = function (element, elementpt) {
  var xCorrection = 0;
  var yCorrection = 0;
  if (Object.prototype.toString.call(element).slice(8, -1) == 'SVGPathElement') {
    var bounds = element.getBBox();
    xCorrection = bounds.x;
    yCorrection = bounds.y;
  }
  var a = translate(getTransformationMatrix(element), window.pageXOffset, window.pageYOffset, 0);
  a = invert(a);
  var pt = new WebKitPoint(((elementpt.x - a[0][3]) * a[1][1] - (elementpt.y - a[1][3]) * a[0][1]) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) - xCorrection,
    (a[0][0] * (elementpt.y - a[1][3]) - a[1][0] * (elementpt.x - a[0][3])) / (a[0][0] * a[1][1] - a[0][1] * a[1][0]) - yCorrection);
  return pt;
};