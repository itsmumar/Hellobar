hellobar.defineModule('base.dom', [], function () {

  function forAllDocuments(callback) {
    if (callback) {
      callback(document);
      var iframes = document.getElementsByTagName('iframe') || [];
      Array.prototype.forEach.call(iframes, function (iframe) {
        try {
          var iframeDocument = iframe.contentDocument;
          callback(iframeDocument);
        } catch (e) {
          // We're fully ignoring iframe cross-origin restriction exception (it's represented with DOMException)
          // and print warning for anything else
          if (!(e instanceof DOMException)) {
            console.warn(e);
          }
        }
      });
    }
  }

  function runOnDocumentReady(callback) {
    var eventName = 'DOMContentLoaded';
    var eventHandler = function () {
      callback && callback();
      document.removeEventListener(eventName, eventHandler);
    };
    if (document.body) {
      callback && setTimeout(callback, 0);
    } else {
      document.addEventListener(eventName, eventHandler);
    }
  }

  /**
   * @module base.dom {object} Performs DOM-related operations (traversing, modifying etc)
   */
  return {

    /**
     * Runs specified callback for all the documents - main HTML document and iframe documents (those that we have access to).
     * @param callback {function}
     */
    forAllDocuments: forAllDocuments,

    /**
     * Runs specified callback once DOM has been loaded
     * @param callback {function}
     */
    runOnDocumentReady: runOnDocumentReady

  };

});
