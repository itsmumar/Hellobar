hellobar.defineModule('elements.bar',
  ['hellobar', 'base.templating', 'base.format', 'elements.collecting'],
  function (hellobar, templating, format, elementsCollecting) {

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

    function contentUpgradeById(contentUpgradeId) {
      return (configuration.contentUpgrades() || {})[contentUpgradeId];
    }

    function submit(contentUpgradeId) {
      const contentUpgrade = contentUpgradeById(contentUpgradeId);
      elementsCollecting.submitEmail(contentUpgrade,
        document.getElementById('hb-fields-form'),
        (document.getElementById('hb_msg_container') || document.getElementsByClassName('hb-headline-text')[0]),
        format.stringLiteral(contentUpgrade.thank_you_text),
        true,
        contentUpgrade.download_link);
    }

    return {
      configuration: () => configuration,
      show,
      submit
    };

  });
