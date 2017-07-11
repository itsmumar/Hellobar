/* globals siteID */

import Ember from 'ember';

export default Ember.Service.extend({
  settings: {},

  load() {
    return Ember.$.getJSON('/api/settings', { site_id: siteID }).then((applicationSettings) => {
      this.set('settings', applicationSettings);
    });
  }
});
