import Ember from 'ember';
import { STEP_GOAL, STEP_TYPE, STEP_DESIGN, STEP_SETTINGS, STEP_TARGETING, STEP_CONVERSION } from '../../constants';

export default Ember.Component.extend({
  classNames: ['side-navigation', 'links-wrapper'],

  pagination: Ember.inject.service(),
  tagName: 'nav',

  isGoalDone: function () {
    return this.isDone(STEP_GOAL);
  }.property('router.currentPath'),

  isTypeDone: function () {
    return this.isDone(STEP_TYPE);
  }.property('router.currentPath'),

  isDesignDone: function () {
    return this.isDone(STEP_DESIGN);
  }.property('router.currentPath'),

  isSettingsDone: function () {
    return this.isDone(STEP_SETTINGS);
  }.property('router.currentPath'),

  isTargetingDone: function () {
    return this.isDone(STEP_TARGETING);
  }.property('router.currentPath'),

  isConversionDone: function () {
    return this.isDone(STEP_CONVERSION);
  }.property('router.currentPath'),

  isDone (route) {
    return this.get('pagination').isDone(route);
  }
});
