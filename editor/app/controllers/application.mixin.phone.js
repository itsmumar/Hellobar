import Ember from 'ember';

export default Ember.Mixin.create({

  setPhoneDefaults: (function () {
    if (this.get('model.element_subtype') === 'call') {
      this.set('isMobile', true);
    }
  }).observes('model.element_subtype').on('init'),

  formatPhoneNumber: function () {
    const phoneNumber = this.get('model.phone_number');
    const countryCode = this.get('model.phone_country_code');
    if (countryCode !== 'XX' && isValidNumber(phoneNumber, countryCode)) {
      this.set('model.phone_number', formatLocal(countryCode, phoneNumber));
    }
  }.observes('model.phone_number', 'model.phone_country_code')

});
