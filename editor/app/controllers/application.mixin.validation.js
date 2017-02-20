import Ember from 'ember';

// GLOBALS: isValidNumber function

export default Ember.Mixin.create({

  validation: Ember.inject.service(),

  initializeValidation() {
    const validationRules = [
      {
        fieldName: 'phone_number',
        validator: (model) => {
          if (Ember.get(model, 'element_subtype') === 'call') {
            const phoneNumber = Ember.get(model, 'phone_number');
            if (!phoneNumber) {
              return 'Phone number is required';
            }
            const countryCode = Ember.get(model, 'phone_country_code');
            if (!isValidNumber(phoneNumber, countryCode)) {
              return 'Wrong phone number for specified country';
            }
          }
          return null;
        }
      }
    ];
    this.get('validation').add('main', validationRules);
  }

});
