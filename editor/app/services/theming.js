import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  inlineEditing: Ember.inject.service(),
  bus: Ember.inject.service(),
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

  _firstAttemptOfThemeApplying: false,

  setThemeById: function (themeId) {
    const allThemes = this.get('availableThemes');
    const theme = _.find(allThemes, theme => theme.id === themeId);

    if (theme) {
      this.setProperties({
        'model.theme': theme,
        'model.theme_id': themeId
      });
      this.applyCurrentTheme();
    }
  },

  applyCurrentTheme() {
    const allThemes = this.get('availableThemes');
    const currentThemeId = this.get('model.theme_id');
    const currentTheme = _.find(allThemes, theme => currentThemeId === theme.id);
    const currentElementType = this.get('model.type');

    if (!currentTheme) {
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'preview/containers/theming/theme-tile-grid',
        componentOptions: {
          elementType: currentElementType
        }
      });
      return;
    }

    if (currentTheme.defaults && currentTheme.defaults[currentElementType]) {
      const themeStyleDefaults = currentTheme.defaults[currentElementType] || {};
      _.each(themeStyleDefaults, (value, key) => {
          this.set(`model.${key}`, value);
        }
      );
    }

    if (currentThemeId && currentThemeId === 'autodetect') {
      this.get('palette').setSiteColors(this);
    }
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
    return currentThemeId ?
      _.find(allThemes, theme => currentThemeId === theme.id) :
      this.get('defaultGenericTheme');
  }.property('availableThemes', 'model.theme_id'),

  defaultImage: function () {
    return this.get('currentTheme.image') || {};
  }.property('currentTheme'),

  resetUseDefaultImage: function () {
    const { id } = this.get('defaultImage');
    const currentImageId = this.get('model.active_image_id');

    if (id && !currentImageId || id === currentImageId) {
      this.set('model.use_default_image', true);
    }
  }.observes('defaultImage'),

  updateImage: function () {
    if (this.get('model.use_default_image')) {
      this.get('modelLogic').resetUploadedImage();
    }
  }.observes('model.use_default_image'),

  /* jshint ignore:start */
  setImage: function (imageProps) {
    this.get('modelLogic').setImageProps({
      imagePlacement: this.getImagePlacement(),
      ...imageProps
    });
  },
  /* jshint ignore:end */

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

  resetThemeIfNeeded: function(style) {
    const type = style || this.get('model.type');
    const themeSupportsStyle = !_.includes(this.get('model.theme.element_types'), type);

    if (themeSupportsStyle && type) {
      this.set('model.theme', null);
      this.set('model.theme_id', null);
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'preview/containers/theming/theme-tile-grid',
        componentOptions: {
          elementType: this.get('model.type')
        }
      });
      return true;
    }
  },

  onCurrentThemeChanged: function () {
    this.applyCurrentTheme();
    Ember.run.next(() => {
      this.setProperties({
        'model.image_placement': this.getImagePlacement()
      });
    });
  }.observes('model.theme_id')
});
