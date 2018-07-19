import Ember from 'ember';
import { STEP_GOAL, STEP_TYPE, STEP_DESIGN, STEP_TARGETING } from '../../constants';

export default Ember.Component.extend({
  classNames: ['side-navigation', 'links-wrapper'],

  pagination: Ember.inject.service(),
  tagName: 'nav',

  isGoalsDone: function () {
    return this.isDone(STEP_GOAL);
  }.property('router.currentPath'),

  isStylesDone: function () {
    return this.isDone(STEP_TYPE);
  }.property('router.currentPath'),

  isDesignDone: function () {
    return this.isDone(STEP_DESIGN);
  }.property('router.currentPath'),

  isTargetingDone: function () {
    return this.isDone(STEP_TARGETING);
  }.property('router.currentPath'),

  isDone (route) {
    return this.get('pagination').isDone(route);
  }
});
