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

  next: function () {
    return this._routeByIndex(this._currentRouteIndex() + 1);
  }.property('router.currentPath'),

  prev: function () {
    return this._routeByIndex(this._currentRouteIndex() - 1);
  }.property('router.currentPath'),

  _currentRouteIndex() {
    const currentRoute = this.get('router.currentPath');
    return _.findIndex(this.get('routes'), (route) => route === currentRoute);
  },

  _routeByIndex(index) {
    const routes = this.get('routes');
    return (index >= 0 && index < routes.length) ? routes[index] : null;
  },

  routeLinks: function () {
    const currentRouteIndex = this._currentRouteIndex();
    return _.map(this.get('routes'), (route, i) => {
      return {route, past: (i < currentRouteIndex)};
    });
  }.property('router.currentPath'),

  //-----------  Save Actions  -----------#

  actions: {

    saveSiteElement() {
      this.sendAction('action');
    }

  }
});
