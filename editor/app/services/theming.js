import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  inlineEditing: Ember.inject.service(),
  applicationSettings: Ember.inject.service(),
  palette: Ember.inject.service(),
  modelLogic: Ember.inject.service(),

  availableThemes: Ember.computed.alias('applicationSettings.settings.available_themes'),

  model: null,

  setModel(model) {
    this.set('model', model);
  },

  defaultGenericTheme: function () {
    return _.find(this.get('availableThemes'), (theme) => theme.type === 'generic');
  }.property('availableThemes'),

  autodetectedTheme: function () {
    return {
      name: 'Autodetected',
      type: 'generic',
      id: 'autodetected',
      fonts: [
        'open_sans',
        'source_pro',
        'helvetica',
        'arial',
        'georgia'
      ],
      'element_types': ['Bar', 'Modal', 'Slider', 'Takeover'],
      defaults: {},
      image: {
        position_default: 'left',
        position_selectable: true
      }
    };

  }.property(),

  _firstAttemptOfThemeApplying: false,

  setThemeById: function (themeId) {
    const allThemes = this.get('availableThemes');
    const theme = _.find(allThemes, theme => theme.id === themeId);

    if (theme) {
      this.setProperties({
        'model.theme': theme,
        'model.theme_id': themeId
      });
    }
  },

  applyCurrentTheme() {
    if (!this.get('model.id') || this._firstAttemptOfThemeApplying) {
      const allThemes = this.get('availableThemes');
      const currentThemeId = this.get('model.theme_id');
      if (currentThemeId && currentThemeId !== 'autodetect') {
        const currentTheme = _.find(allThemes, theme => currentThemeId === theme.id);
        const currentElementType = this.get('model.type');
        if (currentTheme.defaults && currentTheme.defaults[currentElementType]) {
          const themeStyleDefaults = currentTheme.defaults[currentElementType] || {};
          _.each(themeStyleDefaults, (value, key) => {
              this.set(`model.${key}`, value);
            }
          );
        }
      } else {
        this.get('palette').setSiteColors(this);
      }
    }
    this._firstAttemptOfThemeApplying = true;
  },

  getImagePlacement() {
    const positionIsSelectable = this.get('currentTheme.image.position_selectable');
    const imageIsBackground = (this.get('model.image_placement') === 'background');
    const positionIsEmpty = Ember.isEmpty(this.get('model.image_placement'));
    if (!positionIsSelectable) {
      return this.get('currentTheme.image.position_default');
    } else if (imageIsBackground || positionIsEmpty) {
      return this.get('currentTheme.image.position_default');
    } else {
      return this.get('model.image_placement');
    }
  },

  currentTheme: function () {
    const allThemes = this.get('availableThemes');
    const currentThemeId = this.get('model.theme_id');
    return currentThemeId ? _.find(allThemes, theme => currentThemeId === theme.id) : this.get('defaultGenericTheme');
  }.property('availableThemes', 'model.theme_id'),

  /* jshint ignore:start */
  defaultImage: function () {
    const id = this.get('currentTheme.image_upload_id');
    const imageProps = this.get('currentTheme.image') || {};

    return {
      id,
      ...imageProps
    };
  }.property('currentTheme'),
  /* jshint ignore:end */

  resetUseDefaultImage: function () {
    const { id } = this.get('defaultImage');
    const currentImageId = this.get('model.active_image_id');

    if (id && !currentImageId || id === currentImageId) {
      this.set('model.use_default_image', true);
    }
  }.observes('defaultImage'),

  updateImage: function () {
    const { id, default_url } = this.get('defaultImage');
    const currentImageId = this.get('model.active_image_id');
    const useDefaultImage = this.get('model.use_default_image');

    if (useDefaultImage || !currentImageId) {
      this.setImage({
        imageID: id,
        imageUrl: default_url,
        imageType: 'default'
      });
    } else if (!useDefaultImage && currentImageId === id) {
      // remove the default image
      this.setImage({ imageType: 'default' });
    }
  }.observes('model.use_default_image', 'defaultImage'),

  setImage: function (imageProps) { // jshint ignore:line
    /* jshint ignore:start */
    this.get('modelLogic').setImageProps({
      imagePlacement: this.getImagePlacement(),
      ...imageProps
    });
    /* jshint ignore:end */
  },

  themeHasDefaultImage: function () {
    return !!this.get('currentTheme.image.default_url');
  }.property('currentTheme'),

  useThemeImage: function () {
    return this.get('model.use_default_image') && this.get('themeHasDefaultImage');
  }.property('model.use_default_image', 'themeHasDefaultImage'),

  currentThemeName: function () {
    return this.get('currentTheme.name') || '';
  }.property('currentTheme'),

  currentThemeIsGeneric: Ember.computed.equal('currentTheme.type', 'generic'),
  currentThemeIsTemplate: Ember.computed.equal('currentTheme.type', 'template'),

  onCurrentThemeChanged: (function () {
    if (this.get('currentThemeIsTemplate')) {
      this.set('model.element_subtype', 'email');
      this.get('inlineEditing').initializeBlocks(this.get('model'), this.get('model.theme_id'));
    }
    this.applyCurrentTheme();
    Ember.run.next(() => {
      this.setProperties({
        'model.image_placement': this.getImagePlacement()
      });
    });
  }).observes('model.theme_id')
});
