hellobar.defineModule('base.ajax', [], function () {

  function ajax(options) {
    var xhr = new XMLHttpRequest();
    xhr.open(options.type || 'GET', options.url);
    xhr.send(null);

    xhr.onreadystatechange = function () {
      var HTTP_STATUS_OK = 200;
      if (xhr.readyState === XMLHttpRequest.DONE) {
        if (xhr.status === HTTP_STATUS_OK) {
          options.success && options.success(xhr.responseText, xhr);
        } else {
          options.error && options.error(xhr);
        }
      }
    };
  }

  /**
   * @module base.ajax {function} Performs AJAX calls
   */
  var module = ajax;

  /**
   * Performs HTTP GET request
   * @param url {string}
   * @param [success] {function} success handler (optional)
   * @param [error] {function} error handler (optional)
   */
  module.get = function (url, success, error) {
    return ajax({
      url: url,
      type: 'GET',
      success: success,
      error: error
    });
  };

  return module;

});
