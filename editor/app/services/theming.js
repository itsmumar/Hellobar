import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  inlineEditing: Ember.inject.service(),
  applicationSettings: Ember.inject.service(),
  palette: Ember.inject.service(),

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
    return currentThemeId ? _.find(allThemes, theme => currentThemeId === theme.id) : this.get('autodetectedTheme');
  }.property('availableThemes', 'model.theme_id'),


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
