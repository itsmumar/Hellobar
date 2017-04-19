(function ($) {
  $.ajaxPrefilter((options, originalOptions, xhr) => {
    if (!options.crossDomain) {
      const token = $('meta[name="csrf-token"]').attr('content');
      xhr.setRequestHeader('X-CSRF-Token', token);
    }
  });
})(jQuery);
