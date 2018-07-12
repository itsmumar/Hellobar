/* globals formatE164, EditorErrorsModal */

import Ember from 'ember';

export default Ember.Service.extend({
  validation: Ember.inject.service(),
  bus: Ember.inject.service(),
  modelLogic: Ember.inject.service(),

  model: Ember.computed.alias('modelLogic.model'),

  saveAndPublish () {
    return this.validateAndSave({ publish: true }).then(() => {
      this.redirectToSite();
    });
  },

  save () {
    return this.validateAndSave({ publish: false });
  },

  validateAndSave ({ publish }) {
    return this.validate().then(() => {
      this.set('saving', true);

      return this.sendRequest({ publish }).then(data => {
        this.get('modelLogic').setModel(data);
        this.set('saving', false);
        return data;
      }, data => {
        this.set('saving', false);
        new EditorErrorsModal({ errors: data.responseJSON.full_error_messages }).open();
      });
    });
  },

  redirectToSite () {
    const model = this.get('model');

    if (model.site.site_elements_count === 0) {
      window.location = `/sites/${ model.site.id }`;
    } else {
      window.location = `/sites/${ model.site.id }/site_elements`;
    }
  },

  validate () {
    const model = this.get('model');

    return Ember.RSVP.Promise.all([
      this.get('validation').validate('phone_number', model),
      this.get('validation').validate('url', model),
      this.get('validation').validate('url_to_like', model),
      this.get('validation').validate('cookie_settings.duration', model),
      this.get('validation').validate('cookie_settings.success_duration', model)
    ]).then(() => {
      this.get('bus').trigger('hellobar.core.validation.succeeded');
    }, (failures) => {
      // Validation failed
      this.get('bus').trigger('hellobar.core.validation.failed', failures);
    });
  },

  modelWithFormattedPhoneNumber () {
    const model = this.get('model');

    if (model.phone_number && model.phone_country_code) {
      const formattedPhoneNumber =
        formatE164(model.phone_country_code, model.phone_number);

      model.phone_number = formattedPhoneNumber;
    }

    return model;
  },

  sendRequest ({ publish }) {
    const model = this.modelWithFormattedPhoneNumber();

    model.paused_at = publish ? null : new Date();

    const ajaxParams = window.barID ? {
      url: `/sites/${ model.site.id }/site_elements/${ model.id }.json`,
      method: 'PUT'
    } : {
      url: `/sites/${ model.site.id }/site_elements.json`,
      method: 'POST'
    };

    return Ember.$.ajax({
      type: ajaxParams.method,
      url: ajaxParams.url,
      contentType: 'application/json',
      data: JSON.stringify(model)
    });
  }
});
