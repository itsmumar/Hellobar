hellobar.defineModule('elements.injection', [], function() {

  let injectionPolicy = defaultInjectionPolicy;

  function inject(element, atBottom) {
    return injectionPolicy(element, atBottom);
  }

  function defaultInjectionPolicy(element, atBottom = false) {
    if (!atBottom && document.body.children.length > 0) {
      document.body.insertBefore(element, document.body.children[0]);
    } else {
      document.body.appendChild(element);
    }
  }

  function overrideInjectionPolicy(newInjectionPolicy) {
    injectionPolicy = newInjectionPolicy;
  }

  return {
    inject,
    overrideInjectionPolicy
  };

});
