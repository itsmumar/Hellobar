import Ember from 'ember';

import HasPlacement from '../../../mixins/has-placement-mixin';
import HasTriggerOptions from '../../../mixins/has-trigger-options-mixin';

export default Ember.Component.extend(HasPlacement, HasTriggerOptions, {

  theming: Ember.inject.service(),
  currentThemeIsGeneric: Ember.computed.alias('theming.currentThemeIsGeneric'),

  placementOptions: [
    {value: 'bar-top', label: 'Top'},
    {value: 'bar-bottom', label: 'Bottom'}
  ],

  setDefaults: function () {
    if (this.get('model.pushes_page_down') === null) {
      this.set('model.pushes_page_down', true);
    }
  }.observes('model').on('init'),

  canWiggle: function () {
    return this.get('model.element_subtype') === 'traffic' || this.get('model.element_subtype') === 'email';
  }.property('model.element_subtype'),

  pushesText: function () {
    if (this.get('model.placement') === 'bar-top') {
      return 'Pushes page down';
    } else {
      return 'Pushes page up';
    }
  }.property('model.placement'),

  adoptedBarSize: function () {
    const size = this.get('model.size');
    switch (size) {
      case 'large':
        return 50;
      case 'regular':
        return 30;
      default:
        return parseInt(size);
    }
  }.property('model.size'),

  actions: {
    barSizeUpdated(value) {
      this.set('model.size', value);
    }
  }

});
