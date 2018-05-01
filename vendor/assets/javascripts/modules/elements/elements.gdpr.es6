hellobar.defineModule('elements.gdpr',
  ['base.templating', 'base.site', 'base.dom'],
  function (templating, site, dom) {
    const configuration = hellobar.createModuleConfiguration({
      settings: 'object'
    });

    function validate (targetSiteElement) {
      const checkboxes = targetSiteElement
        .querySelectorAll('[name="hb-gdpr-terms-checkbox"], [name="hb-gdpr-consent-checkbox"]');

      return !Array.from(checkboxes).find(input => !input.checked)
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
          console.log('Submit');
          btnElement.onclick = null;
          callback();
        }
      };

      for (let i = 0; i < removeElements.length; i++) {
        dom.hideElement(removeElements[i]);
      }
    }

    function displayCheckboxes (siteElement, formElement, targetSiteElement, callback) {
      const template = templating.render('gdpr', configuration.settings())
      targetSiteElement.innerHTML = template;

      render(siteElement, targetSiteElement, callback);
    }

    return {
      configuration: () => configuration,
      displayCheckboxes
    };
  });
