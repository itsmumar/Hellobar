hellobar.defineModule('elements.collecting',
  ['base.preview', 'base.format', 'base.dom', 'base.site', 'tracking.internal', 'elements.conversion'],
  function (preview, format, dom, site, trackingInternal, elementsConversion) {

    // TODO -> elements.collecting
    /**
     * Creates a field for collecting information
     * @param field
     */
    function createInputFieldHtml(field, siteElement) {
      function fieldAttrs() {
        var label = '';
        var type = 'text';

        switch (field.type) {
          case 'builtin-name':
            label = field.label || siteElement.name_placeholder || 'Name';
            break;
          case 'builtin-email':
            label = field.label || siteElement.email_placeholder || 'Email';
            type = preview.isActive() ? 'text' : 'email';
            break;
          case 'builtin-phone':
            label = field.label || 'Phone';
            type = 'tel';
            break;
          default:
            label = HB.sanitize({label: field.label}).label;
        }

        return {label: label, type: type}
      }

      function additionalCssClasses() {
        switch (field.type) {
          case 'builtin-email':
            return 'builtin-email';
          default:
            return '';
        }
      }

      function id() {
        return field.type === 'builtin-email' ? 'f-builtin-email' : 'f-' + field.id;
      }

      var fieldAttrs = fieldAttrs();

      var html = '<div class="hb-input-block hb-editable-block hb-editable-block-input ' +
        additionalCssClasses() + '" ' +
        'data-hb-editable-block="' + id() + '">' +
        '<label for="' + id() + '">' + fieldAttrs.label + '</label>' +
        '<input id="' + id() + '" type="' + fieldAttrs.type + '" placeholder="' +
        fieldAttrs.label + '" ' + (field.type === 'builtin-email' ? 'required' : '') +
        ' value="' + (preview.isActive() ? fieldAttrs.label : '') + '" />' +
        '</div>';

      return html;
    }


    // TODO -> elements.collecting
    // This takes the the email field, name field, and target siteElement DOM element.
    // It then checks the validity of the fields and if valid it records the
    // email and then sets the message in the siteElement to "Thank you". If invalid it
    // shakes the email field
    function submitEmail(siteElement, formElement, targetSiteElement, thankYouText, redirect, redirectUrl, thankYouCssClass) {
      var emailField = formElement ? formElement.querySelector('#f-builtin-email') : null;
      validateEmail(emailField ? emailField.value : '', function () {
          var doRedirect = format.asBool(redirect);
          var removeElements;
          if (siteElement.type === 'ContentUpgrade') {
            var siteElementDoc = document.getElementById('hb-cu-modal-' + siteElement.id);
          } else {
            var siteElementDoc = siteElement.w.contentDocument;
          }


          if (!doRedirect) {
            if ((targetSiteElement != null) && thankYouText) {
              if (siteElement.use_free_email_default_msg) {
                // Hijack the submit button and turn it into a link
                var btnElement = siteElementDoc.getElementsByClassName('hb-cta')[0];
                var linkUrl = 'http://www.hellobar.com?hbt=emailSubmittedLink&sid=' + site.siteId();
                btnElement.textContent = 'Click Here';
                btnElement.href = linkUrl;
                btnElement.setAttribute('target', '_parent');
                btnElement.onclick = null;

                // Remove all the fields
                removeElements = siteElementDoc.querySelectorAll('.hb-input-block, .hb-secondary-text');
              } else {
                // Remove the entire email input wrapper including the button
                removeElements = siteElementDoc.querySelectorAll('.hb-input-wrapper, .hb-secondary-text');
              }
              targetSiteElement.innerHTML = '<span>' + thankYouText + '</span>';
            }
            if (thankYouCssClass) {
              dom.addClass(siteElement.getSiteElementDomNode(), thankYouCssClass);
            }

            if (removeElements != null) {
              for (var i = 0; i < removeElements.length; i++) {
                dom.hideElement(removeElements[i]);
              }
            }
          }
          var values = [];
          values.push(emailField.value);
          var inputs = siteElementDoc.querySelectorAll('input:not(#f-builtin-email)');
          if (inputs) {
            for (var inputIndex = 0; inputIndex < inputs.length; inputIndex++) {
              var input = inputs[inputIndex];
              input && values.push(input.value);
            }
          }
          recordEmail(siteElement, values, function () {
            // Successfully saved
          });

          HB.trigger('emailSubmitted', siteElement, values);

          if (doRedirect) {
            window.location.href = redirectUrl;
          }
        },
        function () {
          // Fail
          dom.shake(emailField);
        }
      );
      return false;
    }


    // TODO inner function in elements.collecting
    // Called to validate the email. Does not actually submit the email
    function validateEmail(email, successCallback, failCallback) {
      if (email && email.match(/.+@.+\..+/) && !email.match(/,/))
        successCallback();
      else
        failCallback();
    }

    // TODO inner function in elements.collecting
    // Called to record an email for the rule without validation (also used by submitEmail)
    function recordEmail(siteElement, values, callback) {
      if (values && values.length > 0) {
        var sanitizedValues = values.map(function (value) {
          // Replace all the commas with spaces as the comma symbol is a delimiter
          return value.replace(/\,/g, ' ');
        });
        var joinedValues = sanitizedValues.join(',');

        // Record the email address to the cnact list and then track that the rule was performed
        trackingInternal.send('c', siteElement.contact_list_id, {e: joinedValues}, function () {
          elementsConversion.converted(this.siteElement, callback);
        }.bind({siteElement: siteElement}));
      }
    }

    return {
      createInputFieldHtml,
      submitEmail
    };

  });
