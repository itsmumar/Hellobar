import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  modelLogic: Ember.inject.service(),
  theming: Ember.inject.service(),

  imageUploadCopy: Ember.computed.oneWay('theming.currentTheme.image.upload_copy'),
  themeWithImage: Ember.computed.oneWay('theming.themeWithImage'),
  useThemeImage: Ember.computed.oneWay('theming.useThemeImage'),

  allowImages: Ember.computed('model.type', function () {
      return this.get('model.type') !== "Bar";
    }
  ),

  hasUserChosenImage: Ember.computed('model.image_url', 'model.image_type', function () {
      return this.get('model.image_url') && this.get('model.image_type') !== 'default';
    }
  ),

  actions: {
    selectImagePlacement(imagePlacement) {
      this.set('model.image_placement', imagePlacement.value);
    },

    setImageProps(imageProps) {
      this.get('modelLogic').setImageProps(imageProps);
    }
  }

});
