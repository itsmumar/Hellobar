hellobar.defineModule('contentUpgrades',
  ['hellobar', 'base.templating', 'base.format', 'elements.collecting', 'elements.conversion', 'contentUpgrades.class', 'base.bus', 'base.dom', 'elements.data'],
  function (hellobar, templating, format, elementsCollecting, elementsConversion, ContentUpgrade, bus, dom, elementsData) {

    const AB_TEST_FLAG = 'ab';

    const configuration = hellobar.createModuleConfiguration({
      contentUpgrades: 'object',
      styles: 'object'
    });

    function getContentUpgrades(ids) {
      const contentUpgrades = [];

      for (let j = 0; j < ids.length; j++) {
        const id = ids[j];
        const contentUpgrade = configuration.contentUpgrades()[id];

        if (contentUpgrade) {
          contentUpgrades.push(contentUpgrade);
        }
      }

      return contentUpgrades;
    }

    function pickContentUpgrade(ids) {
      const contentUpgrades = getContentUpgrades(ids);

      // previously viewed CU?
      for (let i = 0; i < contentUpgrades.length; i++) {
        const { id } = contentUpgrades[i];

        if (elementsData.getData(id, AB_TEST_FLAG)) {
          return contentUpgrades[i];
        }
      }

      // pick a CU
      const index = Math.floor(Math.random() * contentUpgrades.length);
      const contentUpgrade = contentUpgrades[index];
      if (contentUpgrade)
        elementsData.setData(contentUpgrade.id, AB_TEST_FLAG, 1);

      return contentUpgrade;
    }

    function runABTest(node) {
      if (!node || !node.getAttribute) {
        return;
      }

      const testIds = node.getAttribute('data-hb-cu-ab-test').split(',');
      const contentUpgrade = pickContentUpgrade(testIds);

      if (!contentUpgrade) {
        return;
      }

      show(contentUpgrade.id, node);
    }

    // Run content upgrades by finding elements with data attributes.
    // Example usage:
    // <div data-hb-cu-ab-test="1,2,3,4"></div>
    function run() {
      dom.runOnDocumentReady(() => {
        if (document.querySelectorAll) {
          const testNodes = document.querySelectorAll('[data-hb-cu-ab-test]');
          const ids = [];

          for (let i = 0; i < testNodes.length; i++) {
            runABTest(testNodes[i]);
          }
        }
      });
    }

    function contentUpgradeById(contentUpgradeId) {
      const model = (configuration.contentUpgrades() || {})[contentUpgradeId];

      if (model) {
        return new ContentUpgrade(model);
      }
    }

    function show(contentUpgradeId, node) {
      const siteElement = contentUpgradeById(contentUpgradeId);

      if (siteElement) {
        const siteStyles = configuration.styles() || {};
        var tpl = templating.getTemplateByName('contentupgrade');
        const content = templating.renderTemplate(tpl, {siteElement: siteElement.model(), siteStyles: siteStyles});

        if (!node) {
          node = document.getElementById('hb-cu-' + contentUpgradeId);
        }

        node.outerHTML = content;
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
      run,
      show,
      view,
      submit
    };

  });
