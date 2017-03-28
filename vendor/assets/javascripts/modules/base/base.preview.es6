hellobar.defineModule('base.preview', ['hellobar'], function(hellobar) {

  let isActive = false;

  return {
    isActive: () => isActive,
    setActive () {
      isActive = true;
    }
  };

});
