import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  modelLogic: Ember.inject.service(),
  theming: Ember.inject.service(),
  palette: Ember.inject.service(),

  imageUploadCopy: Ember.computed.oneWay('theming.currentTheme.image.upload_copy'),
  themeHasDefaultImage: Ember.computed.oneWay('theming.themeHasDefaultImage'),
  useThemeImage: Ember.computed.oneWay('theming.useThemeImage'),

  recentColors: Ember.computed.alias('palette.recentColors'),
  siteColors: Ember.computed.alias('palette.colorPalette'),
  focusedColor: Ember.computed.alias('palette.focusedColor'),

  imageOpacity: function () {
    return this.get('model.image_opacity');
  }.property('model.image_opacity'),

  imageOverlayOpacity: function () {
    return this.get('model.image_overlay_opacity');
  }.property('model.image_overlay_opacity'),

  allowImages: Ember.computed('model.type', function () {
      return this.get('model.type') !== "Bar";
    }
  ),

  backgroundImage: Ember.computed('model.image_placement', function () {
      return this.get('model.image_placement') === 'background';
    }
  ),

  actions: {
    selectImagePlacement(imagePlacement) {
      this.set('model.image_placement', imagePlacement.value);
    },

    setImageProps(imageProps) {
      this.get('theming').setImage(imageProps);
    },

    setImageOpacity(opacity) {
      this.set('model.image_opacity', parseInt(opacity));
    },

    setImageOverlayOpacity(opacity) {
      this.set('model.image_overlay_opacity', parseInt(opacity));
    },

    eyeDropperSelected() {
      this.set('focusedColor', null);
      return false;
    }
  }

});
