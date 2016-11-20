// jQuery Background Image Color Selection Plug-In
//
// Copyright 2015 Matt Manske
// Copyright 2010 Jean-Luc Delatre (a.k.a Favonius, a.k.a Kevembuangga)
//
// [JLD] heavy refurbishing, even changing the API...
//
// Dual licensed under the MIT and GPL licenses:
// http://www.opensource.org/licenses/mit-license.php
// http://www.gnu.org/licenses/gpl.html

(function ($) {

  let rgbToHex;
  let config = {};
  let dropper_image = null;
  let dropper_canvas = null;
  let dropper_context = null;
  let hover_spyglass = null;
  let canvas_failure = false;

  let defaults = {
    clickCallback(color, evt) {
      return false;
    },
    mouseMoveCallback(color, evt) {
      return false;
    },
    mouseOutCallback(color, evt) {
      return false;
    },
    selector: $('#background-image'),
    hover_size: 20
  };

  defaults.selector.length = 0;

  //-----------  jQuery Function  -----------#

  $.fn.dropperTrios = function (settings = {}) {

    dropperAbort();

    config = $.extend({}, defaults, settings);
    let style = `width:${config.hover_size}px; height:${config.hover_size}px; display:none`;

    $('body').append(`'<div class="dropperTrios_spyglass" style="${style}"></div>`);
    hover_spyglass = $('.dropperTrios_spyglass');

    if (config.selector && config.selector.length) {
      if (config.selector[0].complete) {
        setupCanvas.call(config.selector[0]);
      } else {
        this.load(setupCanvas);
      }
    }

    return config.selector;
  };

  $.fn.dropperClean = () => dropperAbort();

  //-----------  Abort Previous Instances  -----------#

  var dropperAbort = function () {
    let image_data = [];

    if (dropper_canvas) {
      $(dropper_canvas).remove();
      dropper_canvas = null;
    }

    if (hover_spyglass) {
      hover_spyglass.remove();
      hover_spyglass = null;
    }

    return config.selector = defaults.selector;
  };

  //-----------  Setup Canvas  -----------#

  var setupCanvas = function () {
    dropper_image = this;

    dropper_canvas = document.createElement('canvas');
    dropper_canvas.width = $('.preview-image').width();
    dropper_canvas.height = $('.preview-image').height();

    $(dropper_canvas).insertBefore(this);

    try {
      dropper_context = dropper_canvas.getContext('2d');
      drawImageCanvas(dropper_context, this);
    } catch (e) {
      canvas_failure = true;
      dropperAbort();
      return;
    }

    return bindEvents();
  };

  //-----------  Mimic Background "Cover" Display  -----------#

  var drawImageCanvas = function (ctx, img) {
    let dy;
    let img_ratio = img.height / img.width;
    let ctx_ratio = ctx.canvas.height / ctx.canvas.width;

    let width_ratio = img.width / ctx.canvas.width;
    let height_ratio = img.height / ctx.canvas.height;

    if (ctx_ratio > img_ratio) {
      var sy = 0;
      var sHeight = img.height;
      var sWidth = Math.round(ctx.canvas.width * height_ratio);
      var sx = (img.width - sWidth) / 2;
    } else {
      var sy;
      var sx = sy = 0;
      var sWidth = img.width;
      var sHeight = Math.round(ctx.canvas.height * width_ratio);
    }

    let dx = dy = 0;
    let dWidth = ctx.canvas.width;
    let dHeight = ctx.canvas.height;

    return ctx.drawImage(img, sx, sy, sWidth, sHeight, dx, dy, dWidth, dHeight);
  };

  //-----------  Event Binding  -----------#

  var bindEvents = () =>
    $(dropper_canvas)
      .mousemove(mouseMove)
      .mouseenter(mouseMove)
      .mouseleave(mouseLeave)
      .mousedown(mouseDown);

  let unbindEvents = () =>
    $(dropper_canvas)
      .unbind('mousemove')
      .unbind('mouseleave')
      .unbind('mouseenter')
      .unbind('mousedown');

  //-----------  Mouse Events  -----------#

  var mouseMove = function (evt) {
    let color = colorFromData(evt);
    return hover_spyglass.css({
      'top': evt.pageY - 25,
      'left': evt.pageX - 25,
      'background-color': `#${color}`,
      'position': 'absolute'
    }).show();
  };

  var mouseLeave = evt => hover_spyglass.hide();

  var mouseDown = function (evt) {
    let color = colorFromData(evt);
    config.clickCallback(color, evt);
    return false;
  };

  //-----------  Helper Functions  -----------#

  var colorFromData = function (evt) {
    let pos = findPosition();
    let x = evt.pageX - (pos.x);
    let y = evt.pageY - (pos.y);
    let coord = `x=${x}, y=${y}`;
    let p = dropper_context.getImageData(x, y, 1, 1).data;
    let color = (`000000${rgbToHex(p[0], p[1], p[2])}`).slice(-6);

    return color;
  };

  //-----------  Color Helpers  -----------#

  var findPosition = function () {
    let cur_top;
    let obj = dropper_canvas;
    let cur_left = cur_top = 0;

    if (obj.offsetParent) {
      while (true) {
        cur_left += obj.offsetLeft;
        cur_top += obj.offsetTop;
        if (!(obj = obj.offsetParent)) {
          break;
        }
      }
      return {x: cur_left, y: cur_top};
    }
    return undefined;
  };

  return rgbToHex = function (r, g, b) {
    if (r > 255 || g > 255 || b > 255) {
      throw 'Invalid color component';
    }

    return ((r << 16) | (g << 8) | b).toString(16);
  };

})(jQuery);
