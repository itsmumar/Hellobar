// ember-cli-rails-addon appends X-CSRF-Token regardless do we crossDomain request or not
// so we just use these few lines of code instead

(function ($) {
  $.ajaxPrefilter(function (options, originalOptions, xhr) {
    if (!options.crossDomain) {
      const token = $('meta[name="csrf-token"]').attr('content');
      xhr.setRequestHeader('X-CSRF-Token', token);
    }
  });
})(jQuery);
