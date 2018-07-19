import Ember from 'ember';
import _ from 'lodash/lodash';
import { STEPS } from '../constants';

export default Ember.Service.extend({
  routes: STEPS,
  router: Ember.inject.service('-routing'),

  next () {
    return this.routeByIndex(this.currentRouteIndex() + 1);
  },

  prev () {
    return this.routeByIndex(this.currentRouteIndex() - 1);
  },

  isDone (routePath) {
    const currentRouteIndex = this.currentRouteIndex();
    const routeIndex = _.findIndex(this.get('routes'), (route) => route === routePath);
    return currentRouteIndex >= routeIndex;
  },

  currentRouteIndex () {
    const currentRoute = this.get('router.currentPath');
    return _.findIndex(this.get('routes'), (route) => route === currentRoute);
  },

  routeByIndex (index) {
    const routes = this.get('routes');
    return (index >= 0 && index < routes.length) ? routes[index] : null;
  },

  routeLinks () {
    const currentRouteIndex = this.currentRouteIndex();

    return _.map(this.get('routes'), (route, i) => {
      return {
        route,
        past: (i < currentRouteIndex)
      };
    });
  }
});
