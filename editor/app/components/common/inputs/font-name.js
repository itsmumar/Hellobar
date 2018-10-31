import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['font-name-input'],

  froalaFonts: Ember.inject.service(),

  fonts: function () {
   var font= this.get('froalaFonts').fontFamily();
   var result = Object.keys(font).map(function(key) {
      return font[key];
   });
    return result
  }.property('froalaFonts'),

  selectedFont: null,

  actions: {
    selectFont (font) {
      this.set('selectedFont', font);
    }
  }
});
