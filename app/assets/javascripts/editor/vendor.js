//= require jquery
//= require browser
//= require jquery_ujs

//= require_self

//= require zeropad.jquery
//= require jstz-1.0.4.min
//= require underscore
//= require moment

//= require one-color
//= require one-color-ieshim
//= require colorpicker
//= require color_thief
//= require jquery_dropper
//= require imagesloaded
//= require dropzone.min
//= require phoneformat.min

//= require handlebars
//= require handlebars_helpers

$(function () {

  //-----------  Old IE Detection  -----------#

  if (bowser.msie && bowser.version <= 9) {
    return $('body').addClass('oldIE');
  }
});
