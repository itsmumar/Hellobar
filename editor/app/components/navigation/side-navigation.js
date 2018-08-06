import Ember from 'ember';
import _ from 'lodash/lodash';
import { STEP_GOAL, STEP_TYPE, STEP_DESIGN, STEP_SETTINGS, STEP_TARGETING, STEP_CONVERSION } from '../../constants';

export default Ember.Component.extend({
  classNames: ['side-navigation', 'links-wrapper'],

  model: null,

  pagination: Ember.inject.service(),
  tagName: 'nav',

  isGoalSelected: Ember.computed.notEmpty('model.element_subtype'),

  links: function () {
    const routeLinks = this.get('pagination.routeLinks');

    return _.map(routeLinks, (link, i) => {
      return {
        route: link.route,
        isDone: this.isDone(link.route),
        icon: `icons/icon-${ link.route }`,
        caption: _.capitalize(link.route),
        classNames: this.get('isGoalSelected') ? '' : 'disabled'
      };
    });
  }.property('pagination.routeLinks'),

  isDone (route) {
    return this.get('pagination').isDone(route);
  }
});
