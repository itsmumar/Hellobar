import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['font-name-input'],

  froalaFonts: Ember.inject.service(),

  fonts: function () {
    return this.get('froalaFonts').googleFonts();
  }.property('froalaFonts'),

  selectedFont: null,

  actions: {
    selectFont (font) {
      this.set('selectedFont', font)
    }
  }
});
