import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  inlineEditing: Ember.inject.service(),
  applicationSettings: Ember.inject.service(),
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


  // TODO REFACTOR adopt (move to modelLogic?)
  /*themeChanged: Ember.observer('currentThemeName', function () {
   return Ember.run.next(this, function () {
   return this.setProperties({
   'model.image_placement': this.getImagePlacement()
   });
   }
   //'model.use_default_image' : false
   );
   }
   )*/

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
        // TODO REFACTOR adopt
        //this.setSiteColors();
      }
    }
    this._firstAttemptOfThemeApplying = true;
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
  }).observes('model.theme_id')


});
