import Ember from 'ember';

var renderCount = 0;

export default Ember.Component.extend({
  classNames: ['step-navigation'],

  model: null,

  pagination: Ember.inject.service(),
  fullscreenSwitcher: Ember.inject.service(),

  isFullscreen: Ember.computed.alias('fullscreenSwitcher.isFullscreen'),
  isGoalSelected: Ember.computed.notEmpty('model.element_subtype'),

  didRender() {
    this._super(...arguments);
    $('nav a.button.next').addClass('disabled');
    if(this.get('model.element_subtype') !== null) {
      $('nav a.button.next').removeClass('disabled');
      console.log(renderCount > 0);
      renderCount++;
    }
    if(renderCount > 1 && this.get('model.type') === null)
    {
      $('nav a.button.next').addClass('disabled');

    }
    if(this.get('model.type') !== null) {
      $('nav a.button.next').removeClass('disabled');
    }
  },

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
