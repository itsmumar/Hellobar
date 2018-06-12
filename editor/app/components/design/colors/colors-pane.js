import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  palette: Ember.inject.service(),

  elementTypeIsAlert: Ember.computed.equal('model.type', 'Alert'),

  recentColors: Ember.computed.alias('palette.recentColors'),
  siteColors: Ember.computed.alias('palette.colorPalette'),
  focusedColor: Ember.computed.alias('palette.focusedColor'),

  actions: {
    eyeDropperSelected() {
      this.set('focusedColor', null);
      return false;
    },

    buttonBorderUpdated(value) {
      this.set('model.button_border_width', value);
    },

    buttonCornersUpdated(value) {
      this.set('model.button_rounded_corners', value);
    }
  }

});
