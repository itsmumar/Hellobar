import Ember from 'ember';

export default Ember.Service.extend({
  settings: {},

  load() {
    Ember.$.getJSON('/api/settings').then((applicationSettings) => {
      this.set('settings', applicationSettings);
    });
  }
});
