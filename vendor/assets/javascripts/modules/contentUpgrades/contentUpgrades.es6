hellobar.defineModule('elements.bar', ['hellobar', 'base.templating'], function (hellobar, templating) {

  const configuration = hellobar.createModuleConfiguration({
    contentUpgrades: 'object',
    styles: 'object'
  });

  // TODO is was showContentUpgrade previously
  function show(contentUpgradeId) {
    const contentUpgrades = configuration.contentUpgrades() || {};
    if (contentUpgrades[contentUpgradeId]) {
      const siteElement = contentUpgrades[contentUpgradeId];
      // TODO REFACTOR
      HB.viewed(siteElement);
      const siteStyles = configuration.styles() || {};
      var tpl = templating.getTemplateByName['contentupgrade'];
      const content1 = templating.renderTemplate(tpl, siteElement);
      const content2 = templating.renderTemplate(content1, siteStyles);
      document.getElementById('hb-cu-' + contentUpgradeId).outerHTML = content2;
    }
  }

  return {
    show
  };

});


