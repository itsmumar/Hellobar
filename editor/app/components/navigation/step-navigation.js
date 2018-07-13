import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['step-navigation'],

  //-----------  Routing  -----------#

  routes: ['goals', 'styles', 'design', 'targeting'],

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
  }.property('router.currentPath')
});
