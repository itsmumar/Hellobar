import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['step-navigation'],

  bus: Ember.inject.service(),

  //-----------  Routing  -----------#

  routes: ['goals', 'styles', 'design', 'targeting'],

  init() {
    this._super();
    this._subscribeToValidationEvents();
  },

  _subscribeToValidationEvents() {
    this.get('bus').subscribe('hellobar.core.validation.failed', (failures) => {
      this.set('validationMessages', failures.map(failure => failure.error));
    });
    this.get('bus').subscribe('hellobar.core.validation.succeeded', () => {
      this.set('validationMessages', null);
    });
  },

  routeLinks: function () {
    return _.map(this.get('routes'), (route, i) => {
      return {route, past: (i + 1 < this.get('current'))};
    });
  }.property('current'),

  //-----------  Save Actions  -----------#

  actions: {

    saveSiteElement() {
      this.sendAction('action');
    }
  }
});
