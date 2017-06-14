import Ember from 'ember';

export default Ember.Service.extend({
  settings: {},

  load() {
    return Ember.$.getJSON('/api/settings').then((applicationSettings) => {
      this.set('settings', applicationSettings);
    });
  }
});
