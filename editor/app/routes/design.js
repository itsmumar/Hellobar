import Ember from 'ember';

export default Ember.Route.extend({

  theming: Ember.inject.service(),
  fonts: Ember.inject.service(),

  availableFonts: Ember.computed.alias('fonts.availableFonts'),

  imagePlacementOptions: [
    {value: 'top', label: 'Top'},
    {value: 'bottom', label: 'Bottom'},
    {value: 'left', label: 'Left'},
    {value: 'right', label: 'Right'},
    {value: 'above-caption', label: 'Above Caption'},
    {value: 'below-caption', label: 'Below Caption'}
  ],

  selectedImagePlacementOption: (function () {
    const imagePlacement = this.get('model.image_placement');
    const options = this.get('imagePlacementOptions');
    return _.find(options, imagePlacement);
  }).property('model.image_placement'),

  //-------------- Helpers ----------------#

  isABar: Ember.computed.equal('model.type', 'Bar'),
  isCustom: Ember.computed.equal('model.type', 'Custom'),
  elementTypeIsAlert: Ember.computed.equal('model.type', 'Alert'),
  elementTypeIsNotAlert: Ember.computed.not('elementTypeIsAlert'),

  allowImages: Ember.computed('model.type', function () {
      return this.get('model.type') !== "Bar";
    }
  ),

  themeWithImage: Ember.computed('currentTheme.image_upload_id', function () {
      return !!this.get('currentTheme.image_upload_id');
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

  getImagePlacement() {
    const positionIsSelectable = this.get('currentTheme.image.position_selectable');
    const imageIsBackground = (this.get('model.image_placement') === 'background');
    const positionIsEmpty = Ember.isEmpty(this.get('model.image_placement'));

    if (!positionIsSelectable || imageIsBackground || positionIsEmpty) {
      return this.get('currentTheme.image.position_default');
    } else {
      return this.get('model.image_placement');
    }
  }

});
