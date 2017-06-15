import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  modelLogic: Ember.inject.service(),
  theming: Ember.inject.service(),

  imageUploadCopy: Ember.computed.oneWay('theming.currentTheme.image.upload_copy'),
  themeHasDefaultImage: Ember.computed.oneWay('theming.themeHasDefaultImage'),
  useThemeImage: Ember.computed.oneWay('theming.useThemeImage'),

  allowImages: Ember.computed('model.type', function () {
      return this.get('model.type') !== "Bar";
    }
  ),

  actions: {
    selectImagePlacement(imagePlacement) {
      this.set('model.image_placement', imagePlacement.value);
    },

    setImageProps(imageProps) {
      this.get('theming').setImage(imageProps);
    }
  }

});
