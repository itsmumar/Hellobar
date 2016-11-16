import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['popup-hint-trigger'],

  hintIsVisible: false,

  mouseEnter() {
    return this.set('hintIsVisible', true);
  },

  mouseLeave() {
    return this.set('hintIsVisible', false);
  }
});

