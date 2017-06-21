hellobar.defineModule('contentUpgrades',
  ['hellobar', 'base.templating', 'base.format', 'elements.collecting', 'elements.conversion', 'contentUpgrades.class', 'base.bus'],
  function (hellobar, templating, format, elementsCollecting, elementsConversion, ContentUpgrade, bus) {

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
        const siteStyles = configuration.styles() || {};
        var tpl = templating.getTemplateByName('contentupgrade');
        const content = templating.renderTemplate(tpl, {siteElement: siteElement.model(), siteStyles: siteStyles});
        document.getElementById('hb-cu-' + contentUpgradeId).outerHTML = content;
      }
    }

    function view(contentUpgradeId) {
      const siteElement = contentUpgradeById(contentUpgradeId);

      if (siteElement) {
        elementsConversion.viewed(siteElement);
        document.getElementById(`hb-cu-modal-${siteElement.model().id}`).style.display = 'inline';
      }
    }

    function submit(contentUpgradeId) {
      const siteElement = contentUpgradeById(contentUpgradeId);
      const formElement = document.getElementById('hb-fields-form');
      const targetSiteElement = (document.getElementById('hb_msg_container') || document.getElementsByClassName('hb-headline-text')[0]);
      const redirect = true;
      const model = siteElement.model();
      const downloadLink = model.download_link;
      const thankYouEnabled = !!model.thank_you_enabled;

      bus.on('hellobar.elements.emailSubmitted', () => {
        if (thankYouEnabled) {
          siteElement.showThankYou();
        }
      });

      elementsCollecting.submitEmail(
        siteElement, formElement, targetSiteElement, '', redirect, downloadLink
      );
    }

    return {
      configuration: () => configuration,
      show,
      view,
      submit
    };

  });
