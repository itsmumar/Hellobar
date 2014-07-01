/*
* jQuery dropper plug-in
*
* Copyright 2009 Scott Trudeau
* Copyright 2010 Jean-Luc Delatre (a.k.a Favonius, a.k.a Kevembuangga)
* 
* [JLD] heavy refurbishing, even changing the API...
*
* Dual licensed under the MIT and GPL licenses:
* http://www.opensource.org/licenses/mit-license.php
* http://www.gnu.org/licenses/gpl.html
*/

(function ($) {

    var dropperimages = [];
    var hoverchip = null;
    var canvasfailure = false;
    var APIfailure = false;
    var config = {};
    var dataplaces = [];
    var defaults = {
  clickCallback: function(color,evt) { },
  mouseMoveCallback: function(color,evt) { },
  mouseOutCallback: function(color,evt) { },
  selector: $('#_____'),  // unlikely
  hoverwidth: 15
    };
    
    defaults.selector.length = 0;  // make sure to have a default empty selector

    //   changed the name since the API is different
    //   |
    //   v----------v
    $.fn.dropperredux = function (settings) {

  //innerlog('redux '+settings.selector.length);

   dropperabort();  // cleaning previous run

  settings = settings || {};
  config = $.extend({}, defaults, settings);

   // bind callbacks to each IMG from selector
  // in config NOT from the calling selector

  if (this.length && this[0].tagName == "IMG") {
      if (!APIfailure)
    alert("Wrong call to 'dropperredux', API isn't the one from 'jquery.dropper'");
      APIfailure = true;
      return this;
  }

  APIfailure = false;
  canvasfailure = false;
  dataplaces = [];

  // generate div for hover color floater
 
        $('body').append('<div style="width:'+config.hoverwidth
       +'px; height:'+config.hoverwidth+'px; border-radius: 3px; border: 1px solid #cecece; display:none"></div>');
  hoverchip = $('body').children().last();

  if (config.selector && config.selector.length)
      config.selector.each(function () {
        if (this.tagName == "IMG") {
      
      dropperimages.push(this);
      
      if (this.complete) 
          bindevents.call(this);
      else 
          // Attach to load event to make sure we have 
          // the loaded image before we push it into a canvas
          $(this).load(bindevents);
        }
    });


  return config.selector;  // surprise...
    };

    // functions out of scope to prevent wasteful dynamic recreation
    
    var dropperabort = function () {
  var img, can;

  dataplaces = [];
  while (img = dropperimages.pop()) {
      $(img).unbind('load'); // who knows...*
      can = $(img).prev();   // the replacing canvas
      if (can && can.length && can[0].tagName == 'CANVAS') {
    can.unbind('mousemove').unbind('mouseleave').
        unbind('mouseenter').unbind('mousedown');
    can.remove();
      };
      $(img).show();
  }
  
  if (hoverchip) {
      $(hoverchip).remove();
      hoverchip = null;
  }
  
  config.selector = defaults.selector;
    };
    
    var bindevents = function () {
  
  if (canvasfailure) return;  // don't insist
  
  // Get width & height of image
  var w = $(this).width();
  var h = $(this).height();
  
  // Use DOM methods to create the canvas element
  
  var imgElement = $(this)[0];
  var containerElement = ($(this).parent())[0];
  var canvasElement = document.createElement('canvas');
  canvasElement.width = w;
  canvasElement.height = h;
  containerElement.insertBefore(canvasElement, imgElement);
  
  // Get canvas context, draw canvas, get image data    
  // if fails we don't support canvas, so give up
  try {
      var canvasContext = canvasElement.getContext('2d');
      canvasContext.drawImage(imgElement, 0, 0);
      var imageData = canvasContext.getImageData(0, 0, w, h);
  }
  catch(e) {
      // canvas not supported
      canvasfailure = true;
      dropperabort();
      return;
  }
  
  // save separately to use the same callbacks for EVERY image
  $(canvasElement).attr('imdata', dataplaces.length);
  dataplaces.push(imageData); 

  // mousemove (hover) event
  $(canvasElement).mousemove(mousemove)
  // also pretend a move on mouseenter for quick start
  .mouseenter(mousemove)
  // mouseleave event
  .mouseleave(mouseleave)
  // click event
  .mousedown(mousedown);
  // hide the original image, since we've replaced it w/ a canvas element
  $(this).hide();
    };
    
    var mousemove = function (evt) {
  var canvasIndex = canvasIndexFromEvent(evt, $(this).width(), $(this).offset());
  var color = colorFromData(canvasIndex, dataplaces[$(this).attr('imdata')].data);
  hoverchip.css({
    'background-color': '#' + color.rgbhex,
        'position': 'absolute',
        'top': evt.pageY - 33,
        'left': evt.pageX + 25
        }).show();
  // callback disabled for now 
  //config.mouseMoveCallback(color,evt);
    };
    
    var mouseleave = function (evt) {
  hoverchip.hide();
  var canvasIndex = canvasIndexFromEvent(evt, $(this).width(), $(this).offset());
  var color = colorFromData(canvasIndex, dataplaces[$(this).attr('imdata')].data);
  // callback disabled for now 
  //config.mouseOutCallback(color,evt);
    };
    
    var mousedown = function (evt) {
  var canvasIndex = canvasIndexFromEvent(evt, $(this).width(), $(this).offset());
  var color = colorFromData(canvasIndex, dataplaces[$(this).attr('imdata')].data);  config.clickCallback(color,evt);
  return false;
    };
    
    // helper functions
    // colorData: array containing canvas-style data for a pixel in order: r, g, b, alpha transparency
    // return color object
    var colorFromData = function (canvasIndex, data) {
  var color = {
      r: data[canvasIndex],
      g: data[canvasIndex + 1],
      b: data[canvasIndex + 2],
      alpha: data[canvasIndex + 3]
  };
  color.rgbhex = rgbToHex(color.r, color.g, color.b);
  return color;
    };
    
    // e: click event object
    // w: width of canvas element
    // offset: canvas selement offset object
    // returns canvas index
    var canvasIndexFromEvent = function (e, w, offset) {
  var x = e.pageX - parseInt(offset.left);
  var y = e.pageY - parseInt(offset.top);
  return (x + y * w) * 4;
    };
    
    // i: color channel value, integer 0-255
    // returns two character string hex representation of a color channel (00-FF)
    var toHex = function (i) {
  if (i === undefined) return 'FF'; // TODO this shouldn't happen; looks like offset/x/y might be off by one
  var str = i.toString(16);
  while (str.length < 2) {
      str = '0' + str;
  }
  return str;
    };
    
    // r,g,b: color channel value, integer 0-255
    // returns six character string hex representation of a color
    var rgbToHex = function (r, g, b) {
  return toHex(r) + toHex(g) + toHex(b);
    };
    
})(jQuery);
