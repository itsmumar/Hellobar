import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['popup-hint-trigger'],

  hintIsVisible: false,

  mouseEnter() {
    this.set('hintIsVisible', true);
  },

  mouseLeave() {
    this.set('hintIsVisible', false);
  }
});
