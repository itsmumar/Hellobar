import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({

  theming: Ember.inject.service(),

  firstAttemptOfThemeApplying: false,

  applyCurrentTheme() {
    if (!this.get('model.id') || this.firstAttemptOfThemeApplying) {
      const allThemes = this.get('theming.availableThemes');
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
        this.setSiteColors();
      }
    }
    this.firstAttemptOfThemeApplying = true;
  },

  currentTheme: (function () {
    const allThemes = this.get('theming.availableThemes');
    const currentThemeId = this.get('model.theme_id');
    return currentThemeId ? _.find(allThemes, theme => currentThemeId === theme.id) : this.get('theming.autodetectedTheme');
  }).property('model.theme_id'),


  currentThemeName: (function () {
    const theme = this.get('currentTheme');
    return theme ? theme.name : '';
  }).property('currentTheme'),

  currentThemeIsGeneric: function () {
    const currentTheme = this.get('currentTheme');
    return currentTheme ? currentTheme.type === 'generic' : false;
  }.property('currentTheme'),

  currentThemeIsTemplate: function () {
    const currentTheme = this.get('currentTheme');
    return currentTheme ? currentTheme.type === 'template' : false;
  }.property('currentTheme'),

  onCurrentThemeChanged: (function () {
    if (this.get('currentThemeIsTemplate')) {
      this.set('model.element_subtype', 'email');
      this.get('inlineEditing').initializeBlocks(this.get('model'), this.get('model.theme_id'));
    }
    this.applyCurrentTheme();
  }).observes('model.theme_id')

});
