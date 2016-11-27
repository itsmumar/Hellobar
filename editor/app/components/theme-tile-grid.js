import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  theming: Ember.inject.service(),

  allThemes: function () {
    return this.get('theming').availableThemes();
  }.property(),

  genericThemes: function () {
    return _.filter(this.get('allThemes'), (theme) => theme.type === 'generic');
  }.property('allThemes'),

  templateThemes: function () {
    return _.filter(this.get('allThemes'), (theme) => theme.type === 'template')
  }.property('allThemes'),

  classNames: ['theme-tile-grid']
});

