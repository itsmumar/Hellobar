(function($) {
  $.zeropad = function(string, length) {
    // default to 2
    string = string.toString();
    if (typeof length === "undefined" && string.length == 1) length = 2;
    length = length || string.length;
    return string.length >= length ? string : $.zeropad("0" + string, length);
  }
})(jQuery);
