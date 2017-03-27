import Ember from 'ember';
import _ from 'lodash/lodash';

/**
 * @class ThemeTileGrid
 * Grid-based theme selector component.
 */
export default Ember.Component.extend({

  classNames: ['theme-tile-grid'],
  classNameBindings: ['elementTypeCssClass'],

  bus: Ember.inject.service(),
  theming: Ember.inject.service(),

  elementType: function() {
    return this.get('options.elementType');
  }.property('options.elementType'),

  elementTypeCssClass: function() {
    return _.kebabCase(this.get('elementType'));
  }.property('elementType'),

  allThemes: function () {
    return this.get('theming').availableThemes();
  }.property(),

  genericThemes: function () {
    return _.filter(this.get('allThemes'), (theme) => theme.type === 'generic' && theme.id !== 'autodetect');
  }.property('allThemes'),

  templateThemes: function () {
    const elementType = this.get('elementType');
    return _.filter(this.get('allThemes'), (theme) => theme.type === 'template' && _.includes(theme.element_types, elementType));
  }.property('allThemes', 'elementType'),

  hasAnyTemplateThemes: function() {
    const templateThemes = this.get('templateThemes');
    return templateThemes && templateThemes.length > 0;
  }.property('templateThemes'),

  actions: {
    autodetectColors() {
      this.get('bus').trigger('hellobar.core.bar.themeChanged', {
        themeId: 'autodetect',
        elementType: this.get('elementType')
      });
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    }
  }

});
