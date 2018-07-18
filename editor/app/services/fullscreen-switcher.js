import Ember from 'ember';

export default Ember.Service.extend({
  isFullscreen: false,

  toggle () {
    this.toggleProperty('isFullscreen');
  }
})
