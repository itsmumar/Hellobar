import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({

  theming: Ember.inject.service(),

  initializeTheme() {
    Ember.run.next(() => {
        if (this.get('model.id') === null) {
          this.applyCurrentTheme();
        }
      }
    );
  },

  applyCurrentTheme() {
    const allThemes = this.get('theming').availableThemes();
    const currentThemeId = this.get('model.theme_id');
    const currentTheme = _.find(allThemes, theme => currentThemeId === theme.id);
    const currentThemeType = this.get('model.type');
    if (currentTheme.defaults && currentTheme.defaults[currentThemeType]) {
      let themeStyleDefaults = currentTheme.defaults[currentThemeType] || {};
      _.each(themeStyleDefaults, (value, key) => {
          return this.set(`model.${key}`, value);
        }
      );
    }
  },

  currentTheme: (function () {
    const allThemes = this.get('theming').availableThemes();
    const currentThemeId = this.get('model.theme_id');
    const currentTheme = _.find(allThemes, theme => currentThemeId === theme.id);
    return currentTheme;
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
    if (this.get('originalTheme').theme_id === this.get('model.theme_id')) {
      _.each(this.get('originalTheme'), (value, key) => {
          return this.set(`model.${key}`, value);
        }
      );
    } else {
      return this.applyCurrentTheme();
    }
  }).observes('model.theme_id')

});
