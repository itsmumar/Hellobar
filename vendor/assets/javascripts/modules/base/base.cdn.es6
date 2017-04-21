hellobar.defineModule('base.cdn', [], function () {

  let resourceRegistry = {};

  function resourceAlreadyRegistered(href, doc) {
    const documents = resourceRegistry[href];
    return documents && (documents.indexOf(doc) >= 0);
  }

  function registerResource(href, doc) {
    const documents = resourceRegistry[href];
    if (documents) {
      documents.push(doc);
    } else {
      resourceRegistry[href] = [doc];
    }
  }

  function addResource(href, doc, elementFactory) {
    if (resourceAlreadyRegistered(href, doc)) {
      return;
    }
    const actualDocument = doc || document;
    const head = actualDocument.getElementsByTagName('head')[0];
    const element = elementFactory(actualDocument);
    head.appendChild(element);
    registerResource(href, doc);
  }

  function addCss(href, doc) {
    addResource(href, doc, (actualDocument) => {
      const link = actualDocument.createElement('LINK');
      link.href = href;
      link.rel = 'stylesheet';
      link.type = 'text/css';
      return link;
    });
  }

  function addJs(href, doc) {
    addResource(href, doc, (actualDocument) => {
      const script = actualDocument.createElement('SCRIPT');
      script.src = href;
      script.type = 'text/javascript';
      return script;
    });
  }

  return {
    /**
     * Injects CSS file link specified document
     * @param href {string} link to CSS file
     * @param doc [Document] DOM document for CSS insertion (if omitted then current document is used)
     */
    addCss,
    /**
     * Injects external script into specified document
     * @param href {string} link to JS file
     * @param doc [Document] DOM document for JS insertion (if omitted then current document is used)
     */
    addJs
  };

});
