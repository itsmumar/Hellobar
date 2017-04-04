hellobar.defineModule('base.styling', ['hellobar'], function(hellobar) {

  const configuration = hellobar.createModuleConfiguration({
    externalCSS: 'string'
  });

  function applyExternalStyles() {
    // Check if we have any external CSS to add
    if (configuration.externalCSS()) {
      // Create the style tag
      const styleElement = document.createElement('STYLE');
      styleElement.type = 'text/css';
      if (styleElement.styleSheet) {
        styleElement.styleSheet.cssText = configuration.externalCSS();
      }
      else {
        styleElement.appendChild(document.createTextNode(configuration.externalCSS()));
      }
      const head = document.getElementsByTagName('HEAD')[0];
      head.appendChild(styleElement);
    }
  }

  return {
    configuration: () => configuration,
    initialize: (configurator) => {
      configurator && configurator(configuration);
      applyExternalStyles();
    }
  }

});
