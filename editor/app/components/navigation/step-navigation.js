import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['step-navigation'],

  model: null,

  pagination: Ember.inject.service(),
  fullscreenSwitcher: Ember.inject.service(),

  isFullscreen: Ember.computed.alias('fullscreenSwitcher.isFullscreen'),
  isGoalSelected: Ember.computed.notEmpty('model.element_subtype'),

  next: function () {
    return this.get('pagination').next();
  }.property('router.currentPath'),

  prev: function () {
    return this.get('pagination').prev();
  }.property('router.currentPath'),

  routeLinks: function () {
    return this.get('pagination.routeLinks');
  }.property('pagination.routeLinks'),

  actions: {
    toggleFullscreen () {
      this.get('fullscreenSwitcher').toggle();
    }
  }
});
