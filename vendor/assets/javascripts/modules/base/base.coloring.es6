hellobar.defineModule('base.coloring', [], function() {

  // TODO -> base.coloring
  function colorIsBright(hex) {
    var rgb = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    if (rgb == null)
      return true;

    var brightness = luminance(parseInt(rgb[1], 16), parseInt(rgb[2], 16), parseInt(rgb[3], 16));

    return brightness >= 0.5
  }

  // TODO -> base.coloring (make it inner)
  function luminance(r, g, b) {
    // http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
    var rgb = [r, g, b];

    for (var i = 0; i < 3; i++) {
      var val = rgb[i] / 255;
      val = val < .03928 ? val / 12.92 : Math.pow((val + .055) / 1.055, 2.4);
      rgb[i] = val;
    }

    return .2126 * rgb[0] + .7152 * rgb[1] + 0.0722 * rgb[2];
  }

  return {
    colorIsBright
  };

});
