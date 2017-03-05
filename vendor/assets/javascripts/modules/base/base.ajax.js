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

  var module = ajax;

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
