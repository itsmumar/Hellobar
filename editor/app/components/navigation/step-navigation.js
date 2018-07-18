import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['step-navigation'],

  pagination: Ember.inject.service(),
  fullscreenSwitcher: Ember.inject.service(),

  isFullscreen: Ember.computed.alias('fullscreenSwitcher.isFullscreen'),

  next: function () {
    return this.get('pagination').next();
  }.property('router.currentPath'),

  prev: function () {
    return this.get('pagination').prev();
  }.property('router.currentPath'),

  routeLinks: function () {
    return this.get('pagination').routeLinks();
  }.property('router.currentPath'),

  actions: {
    toggleFullscreen () {
      this.get('fullscreenSwitcher').toggle();
    }
  }
});
