import Ember from 'ember';

export default Ember.Service.extend({
  availableThemes() {
    return window.availableThemes ? window.availableThemes : [];
  }
});
