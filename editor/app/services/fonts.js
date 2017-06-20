import Ember from 'ember';

export default Ember.Service.extend({
  applicationSettings: Ember.inject.service(),
  availableFonts: Ember.computed.alias('applicationSettings.settings.available_fonts')
});
