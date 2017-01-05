import Ember from 'ember';
import _ from 'lodash/lodash';

/**
 * @class ThemeTileGrid
 * Grid-based theme selector component.
 */
export default Ember.Component.extend({

  classNames: ['theme-tile-grid'],
  classNameBindings: ['elementTypeCssClass'],

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
    return _.filter(this.get('allThemes'), (theme) => theme.type === 'generic');
  }.property('allThemes'),

  templateThemes: function () {
    const elementType = this.get('elementType');
    // TODO drop support for outdated element_type property
    return _.filter(this.get('allThemes'),
      (theme) => theme.type === 'template'
      && (theme.element_type === elementType
      || _.includes(theme.element_type, elementType)
      || _.includes(theme.element_types, elementType)));
  }.property('allThemes', 'elementType'),

  hasAnyTemplateThemes: function() {
    const templateThemes = this.get('templateThemes');
    return templateThemes && templateThemes.length > 0;
  }.property('templateThemes')

});
