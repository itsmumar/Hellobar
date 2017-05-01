import Ember from 'ember';
import ENV from 'editor/config/environment';

export default Ember.Service.extend({
  settings: {},

  load() {
    Ember.$.getJSON('/api/settings').then((applicationSettings) => {
      this.set('settings', applicationSettings);

      if (applicationSettings.lead_data) {
        new LeadDataModal(applicationSettings).checkCountryAndOpen();
      }
    });
  },

  settings() {
    return this.get('settings')
  }
});
