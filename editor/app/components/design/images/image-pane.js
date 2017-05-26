import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  theming: Ember.inject.service(),

  imageUploadCopy: Ember.computed.oneWay('theming.currentTheme.image.upload_copy'),

  defaultImageToggled: function () {
    if (this.get('useThemeImage')) {
      this.setDefaultImage();
    }
  }.observes('model.use_default_image').on('init'),

  setDefaultImage() {
    const imageID = this.get('theming.currentTheme.image_upload_id');
    const imageUrl = this.get('theming.currentTheme.image.default_url');
    this.send('setImageProps', imageID, imageUrl, 'default');
  },

  allowImages: Ember.computed('model.type', function () {
      return this.get('model.type') !== "Bar";
    }
  ),

  themeWithImage: Ember.computed('theming.currentTheme.image_upload_id', function () {
      return !!this.get('theming.currentTheme.image_upload_id');
    }
  ),

  useThemeImage: Ember.computed('model.use_default_image', function () {
      return this.get('model.use_default_image') && this.get('themeWithImage');
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

    setImageProps(imageID, imageUrl, imageType = null) {
      return this.setProperties({
        'model.active_image_id': imageID,
        'model.image_placement': this.get('theming').getImagePlacement(),
        'model.image_url': imageUrl,
        'model.image_type': imageType
      });
    }
  }

});
