import Ember from 'ember';

export default Ember.Component.extend({

  palette: Ember.inject.service(),

  recentColors: Ember.computed.alias('palette.recentColors'),
  siteColors: Ember.computed.alias('palette.colorPalette'),
  focusedColor: Ember.computed.alias('palette.focusedColor'),

  actions: {
    eyeDropperSelected() {
      this.set('focusedColor', null);
      return false;
    }
  }

});
