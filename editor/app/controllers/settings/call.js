import Ember from 'ember';

export default Ember.Controller.extend({

  countries: HB.countryCodes,

  actions: {
    selectCallCountryCall(country) {
      // TODO handle action, set model.phone_country_code from country.code
      console.log('country', country);

    }
  }
});
