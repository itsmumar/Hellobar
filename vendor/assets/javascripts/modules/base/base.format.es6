hellobar.defineModule('base.format', [], function() {

  function stripTrailingSlash(urlPart) {
    return urlPart.replace(/(.+)\/$/i, '$1');
  }

  // TODO previously it was called HB.n
  // Normalizes a URL so that "https://www.google.com/#foo" becomes "http://google.com"
  // Also sorts the params alphabetically
  function normalizeUrl(url, pathOnly) {
    url = (url + '').toLowerCase();
    // Add trailing slash when we think it's needed
    if (url.match(/^https?:\/\/[^\/?]*$/i) ||
      url.match(/^[^\/]*\.(com|edu|gov|us|net|io)$/i))
      url += '/';

    //normalize query string to start with slash
    url = url.replace(/([^\/])\?/, '$1/?')

    // Get rid of things that make no difference in the URL (such as protocol and anchor)
    url = url.
      replace(/https?:\/\//, '').
      replace(/^www\./, '').
      replace(/\#.*/, '');

    // Strip the host if pathOnly
    if (pathOnly) {
      // Unless it starts with a slash
      if (!url.match(/^\//)) {
        url = url.replace(/.*?\//, '/');
      }
    }

    if (url === '/' || url === '/?') {
      return url;
    }

    // If no query string just return the URL
    if (url.indexOf('?') === -1) {
      return stripTrailingSlash(url);
    }

    // Get the params
    var urlParts = url.split('?');

    // If no params just return the URL with ?
    if (!urlParts[1]) {
      return stripTrailingSlash(urlParts[0]) + '?';
    }

    // Sort the params
    var sortedParams = urlParts[1].split('&').sort().join('&');
    return stripTrailingSlash(urlParts[0] + '/') + '?' + sortedParams;
  }


  return {
    normalizeUrl
  };

});
