import Ember from 'ember';
import _ from 'lodash/lodash';

// GLOBALS: isValidNumber, formatLocal functions
const isValidNumber = window.isValidNumber;
const formatLocal = window.formatLocal;

/**
 * @class ModelLogic
 * Contains observers bound to the application model.
 */
export default Ember.Service.extend({

  bus: Ember.inject.service(),

  /**
   * @property {object}
   */
  model: null,

  init() {
    this._trackFieldChanges();
  },

  _trackFieldChanges() {
    this.get('bus').subscribe('hellobar.core.fields.changed', (params) => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    });
  },

  setModel(model) {
    this.set('model', model);
  },

  onElementTypeChange: function () {
    if (this.get('model.type') === 'Bar') {
      const fields = Ember.copy(this.get('model.settings.fields_to_collect'));
      _.each(fields, (field) => {
        if (field && field.type && field.type.indexOf('builtin-') !== 0) {
          field.is_enabled = false;
        }
      });
      this.set('model.settings.fields_to_collect', fields);
    }
  }.observes('model.type'),

  afterModel: function () {
    let cookieSettings = this.get('model.settings.cookie_settings');
    if (_.isEmpty(cookieSettings)) {
      const elementType = this.get('model.type');
      if (elementType === 'Modal' || elementType === 'Takeover') {
        cookieSettings = {
          duration: 0,
          success_duration: 0
        };
      } else {
        cookieSettings = {
          duration: 0,
          success_duration: 0
        };
      }

      this.set('model.settings.cookie_settings', cookieSettings);
    }
  }.observes('model'),

  formatPhoneNumber: function () {
    const phoneNumber = this.get('model.phone_number');
    const countryCode = this.get('model.phone_country_code');
    if (countryCode !== 'XX' && isValidNumber(phoneNumber, countryCode)) {
      this.set('model.phone_number', formatLocal(countryCode, phoneNumber));
    }
  }.observes('model.phone_number', 'model.phone_country_code')

});
