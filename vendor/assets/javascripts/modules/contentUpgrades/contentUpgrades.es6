hellobar.defineModule('elements.bar', ['base.templating'], function(templating) {

  // TODO adopt

  function showContentUpgrade(id) {
    if (HB.CONTENT_UPGRADES[id]){
      siteElement = HB.CONTENT_UPGRADES[id];
      HB.viewed(siteElement);
      siteStyles = HB.CONTENT_UPGRADES_STYLES;
      var tpl =  templating.getTemplateByName['contentupgrade'];
      content =  templating.renderTemplate(tpl, siteElement);
      content =  templating.renderTemplate(content, siteStyles);
      document.getElementById('hb-cu-'+id).outerHTML = content;
    }
  }

  const module = {
    initialize: () => null
  };

  return module;

});


