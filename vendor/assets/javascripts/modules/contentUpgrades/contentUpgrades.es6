hellobar.defineModule('elements.bar', [], function() {

  // TODO adopt

  function showContentUpgrade(id) {
    if (HB.CONTENT_UPGRADES[id]){
      siteElement = HB.CONTENT_UPGRADES[id];
      HB.viewed(siteElement);
      siteStyles = HB.CONTENT_UPGRADES_STYLES;
      var tpl =  HB.contentUpgradeTemplates['contentupgrade'];
      content =  HB.renderTemplate(tpl, siteElement);
      content =  HB.renderTemplate(content, siteStyles);
      document.getElementById('hb-cu-'+id).outerHTML = content;
    }
  }

  const module = {
    initialize: () => null
  };

  return module;

});


