hellobar.defineModule('elements.gdpr',
  ['base.templating', 'base.site', 'base.dom'],
  function (templating, site, dom) {
    const configuration = hellobar.createModuleConfiguration({
      settings: 'object'
    });

    function validate (targetSiteElement) {
      const checkboxes = targetSiteElement
        .querySelectorAll('[name="hb-gdpr-terms-checkbox"], [name="hb-gdpr-consent-checkbox"]');

      return checkboxes[0].checked && checkboxes[1].checked
    }

    function render(siteElement, targetSiteElement, callback) {
      const siteElementContainer = siteElement.contentDocument();
      const siteElementModel = siteElement.model();

      const btnElement = siteElementContainer.getElementsByClassName('hb-cta')[0];
      const btnTextHolder = btnElement.getElementsByClassName('hb-text-holder')[0];

      const removeElements = siteElementContainer.querySelectorAll('.hb-input-block, .hb-secondary-text');

      btnElement.href = 'javascript:void(0)';
      btnTextHolder.textContent = 'Submit';
      btnElement.onclick = () => {
        if (validate(targetSiteElement)) {
          btnElement.onclick = null;
          callback();
        }
      };

      for (let i = 0; i < removeElements.length; i++) {
        dom.hideElement(removeElements[i]);
      }
    }

    function isAvailable (siteElement) {
      const model = siteElement.model()
      return model.theme_id !== 'traffic-growth' && model.type !== 'ContentUpgrade'
    }

    function isEnabled (siteElement) {
      const model = siteElement.model()
      return model.enable_gdpr
    }

    function displayCheckboxes (siteElement, targetSiteElement, callback) {
      if (!targetSiteElement) return callback();

      const template = templating.render('gdpr', configuration.settings())
      targetSiteElement.innerHTML = template;

      if (isEnabled(siteElement) && isAvailable(siteElement)) {
        render(siteElement, targetSiteElement, callback);
      } else {
        callback();
      }
    }

    return {
      configuration: () => configuration,
      displayCheckboxes
    };
  });
