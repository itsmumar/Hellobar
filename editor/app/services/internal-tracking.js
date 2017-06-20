/* globals InternalTracking */

import Ember from 'ember';

/**
 * @class InternalTracking
 * Encapsulates InternalTracking global variable usage
 */
export default Ember.Service.extend({

  applicationSettings: Ember.inject.service('applicationSettings'),

  init() {
    this.tracking = InternalTracking;
  },

  track(eventName, props) {
    const trackingIsEnabled = () => this.get('applicationSettings.settings.track_editor_flow');
    if (trackingIsEnabled()) {
      this.tracking.track_current_person(eventName, props);
    }
  }

});
