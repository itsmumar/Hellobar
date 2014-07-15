(function($) {
  $.zeropad = function(string, length) {
    length = length || 2;
    return ("0" + string).slice(length * -1);
  }
})(jQuery);
