hellobar.defineModule('elements.collecting',
  ['base.preview', 'base.format', 'base.dom', 'base.site', 'base.sanitizing', 'base.bus', 'tracking.internal', 'elements.conversion'],
  function (preview, format, dom, site, sanitizing, bus, trackingInternal, elementsConversion) {

    /**
     * Creates a field for collecting information
     * @param field {object}
     * @param siteElement {object}
     */
    function createInputFieldHtml(field, siteElement) {
      const siteElementModel = siteElement.model ? siteElement.model() : siteElement;

      function fieldAttributes() {
        var label = '';
        var type = 'text';
        var name = null;

        switch (field.type) {
          case 'builtin-name':
            label = field.label || siteElementModel.name_placeholder || 'Name';
            name = 'name';
            break;
          case 'builtin-email':
            label = field.label || siteElementModel.email_placeholder || 'Email';
            type = preview.isActive() ? 'text' : 'email';
            name = 'email';
            break;
          case 'builtin-phone':
            label = field.label || 'Phone';
            type = 'tel';
            name = 'phone';
            break;
          default:
            label = sanitizing.sanitize({label: field.label}).label;
        }

        return {label: label, type: type, name: name}
      }

      function additionalCssClasses() {
        switch (field.type) {
          case 'builtin-email':
            return 'builtin-email';
          case 'builtin-phone':
            return 'builtin-phone';
          default:
            return '';
        }
      }

      function id() {
        return field.type === 'builtin-email' ? 'f-builtin-email' : 'f-' + field.id;
      }

      debugger
      var fieldAttrs = fieldAttributes();

      let name = fieldAttrs.name ? `name="${fieldAttrs.name}"` : '';
      let type = `type="${fieldAttrs.type}"`;
      let placeholder = `placeholder="${fieldAttrs.label}"`;
      let required = field.type === 'builtin-email' ? 'required' : '';
      let value = preview.isActive() ? `value="${fieldAttrs.label}"` : '';
      let autocomplete = fieldAttrs.name ? 'autocomplete="on"' : '';
      let defaultClasses = 'hb-input-block hb-editable-block hb-editable-block-input';

      let html = `
        <div class="${defaultClasses} ${additionalCssClasses()}" data-hb-editable-block="${id()}">
          <label for="${id()}">${fieldAttrs.label}</label>
          <input id="${id()}" ${type} ${name} ${placeholder} ${required} ${value} ${autocomplete}/>
        </div>
      `;
      return html;
    }


    // This takes the the email field, name field, and target siteElement DOM element.
    // It then checks the validity of the fields and if valid it records the
    // email and then sets the message in the siteElement to "Thank you". If invalid it
    // shakes the email field
    function submitEmail(siteElement, formElement, targetSiteElement, thankYouText, redirect, redirectUrl, thankYouCssClass) {
      const siteElementModel = siteElement.model();
      const emailField = formElement ? formElement.querySelector('#f-builtin-email') : null;
      validateEmail(emailField ? emailField.value : '', function () {
          const doRedirect = format.asBool(redirect);
          let removeElements;
          let siteElementContainer = siteElement.contentDocument();

          if (!doRedirect) {
            if ((targetSiteElement != null) && thankYouText) {
              let btnElement = siteElementContainer.getElementsByClassName('hb-cta')[0];
              let btnTextHolder = btnElement.getElementsByClassName('hb-text-holder')[0];

              if (siteElementModel.use_free_email_default_msg) {
                // Hijack the submit button and turn it into a link
                const linkUrl = `http://www.hellobar.com?hbt=emailSubmittedLink&sid=${site.siteId()}`;
                btnTextHolder.textContent = 'Click Here';
                btnElement.href = linkUrl;
                btnElement.setAttribute('target', '_parent');
                btnElement.onclick = null;

                // Remove all the fields
                removeElements = siteElementContainer.querySelectorAll('.hb-input-block, .hb-secondary-text');
              } else {
                btnElement.href = 'javascript:void(0)';
                btnTextHolder.textContent = 'Close';
                btnElement.addEventListener('click', () => hellobar('elements').findById(siteElement.id).close());

                // Remove the entire email input wrapper including the button
                removeElements = siteElementContainer.querySelectorAll('.hb-input-block, .hb-secondary-text');
              }
              targetSiteElement.innerHTML = `<span>${thankYouText}</span>`;
            }
            if (thankYouCssClass) {
              dom.addClass(siteElement.getSiteElementDomNode(), thankYouCssClass);
            }

            if (removeElements) {
              for (var i = 0; i < removeElements.length; i++) {
                dom.hideElement(removeElements[i]);
              }
            }
          }
          var values = [];
          values.push(emailField.value);
          var inputs = siteElementContainer.querySelectorAll('input:not(#f-builtin-email)');
          if (inputs) {
            for (var inputIndex = 0; inputIndex < inputs.length; inputIndex++) {
              var input = inputs[inputIndex];
              input && values.push(input.value);
            }
          }
          recordEmail(siteElement, values, function () {
            bus.trigger('hellobar.elements.emailSubmitted', siteElement, values);

            if (doRedirect) {
              window.location.href = redirectUrl;
            }
          });
        },
        function () {
          // Fail
          dom.shake(emailField.parentNode);
        }
      );
      return false;
    }


    // Called to validate the email. Does not actually submit the email
    function validateEmail(email, successCallback, failCallback) {
      if (email && email.match(/.+@.+\..+/) && !email.match(/,/))
        successCallback();
      else
        failCallback();
    }

    // Called to record an email for the rule without validation (also used by submitEmail)
    function recordEmail(siteElement, values, callback) {
      if (values && values.length > 0) {
        var sanitizedValues = values.map(function (value) {
          // Replace all the commas with spaces as the comma symbol is a delimiter
          return value.trim().replace(/\,/g, ' ');
        });
        var joinedValues = sanitizedValues.join(',');

        // Record the email address to the contact list and then track that the rule was performed
        trackingInternal.send('c', siteElement.model().contact_list_id, {e: joinedValues}, function () {
          elementsConversion.converted(siteElement, callback);
        });
      }
    }

    return {
      createInputFieldHtml,
      submitEmail
    };

  });
