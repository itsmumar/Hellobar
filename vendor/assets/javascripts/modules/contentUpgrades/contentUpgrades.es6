hellobar.defineModule('contentUpgrades',
  ['hellobar', 'base.templating', 'base.format', 'elements.collecting', 'elements.conversion', 'contentUpgrades.class'],
  function (hellobar, templating, format, elementsCollecting, elementsConversion, ContentUpgrade) {

    const configuration = hellobar.createModuleConfiguration({
      contentUpgrades: 'object',
      styles: 'object'
    });

    function contentUpgradeById(contentUpgradeId) {
      const model = (configuration.contentUpgrades() || {})[contentUpgradeId];

      if (model) {
        return new ContentUpgrade(model);
      }
    }

    function show(contentUpgradeId) {
      const siteElement = contentUpgradeById(contentUpgradeId);

      if (siteElement) {
        elementsConversion.viewed(siteElement);
        const siteStyles = configuration.styles() || {};
        var tpl = templating.getTemplateByName('contentupgrade');
        const content1 = templating.renderTemplate(tpl, siteElement.model());
        const content2 = templating.renderTemplate(content1, siteStyles);
        document.getElementById('hb-cu-' + contentUpgradeId).outerHTML = content2;
      }
    }

    function submit(contentUpgradeId) {
      const siteElement = contentUpgradeById(contentUpgradeId);
      const formElement = document.getElementById('hb-fields-form');
      const targetSiteElement = (document.getElementById('hb_msg_container') || document.getElementsByClassName('hb-headline-text')[0]);
      const redirect = true;
      const thankYouText = siteElement.model().thank_you_text || 'Thank you!';
      const downloadLink = siteElement.model().download_link;

      elementsCollecting.submitEmail(
        siteElement, formElement, targetSiteElement, format.stringLiteral(thankYouText), redirect, downloadLink
      );
    }

    return {
      configuration: () => configuration,
      show,
      submit
    };

  });
