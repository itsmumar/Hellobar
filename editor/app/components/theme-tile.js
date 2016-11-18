import Ember from 'ember';

export default Ember.Component.extend({

  bus: Ember.inject.service(),

  classNames: ['theme-tile'],

  theme: null,

  imageSrc: (function () {
    return `/assets/themes/tiles/modal/${this.get('theme.id')}.png`;
  }).property('theme'),

  init() {
    return this._super();
  },

  selectButtonIsVisible: false,

  mouseEnter() {
    return this.set('selectButtonIsVisible', true);
  },

  mouseLeave() {
    return this.set('selectButtonIsVisible', false);
  },

  actions: {
    select() {
      this.get('bus').trigger('hellobar.core.bar.themeChanged', {themeId: this.get('theme.id')});
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    }
  }
});


