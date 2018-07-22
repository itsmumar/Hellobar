import Ember from 'ember';

import HasTriggerOptions from '../../mixins/has-trigger-options-mixin';
import ElementSubtype from '../../mixins/element-subtype-mixin';

export default Ember.Component.extend(HasTriggerOptions, ElementSubtype, {
  /**
   * @property {object} Application model
   */
  model: null,

  canWiggle: function () {
    const goal = this.get('model.element_subtype');
    return goal === 'traffic' || goal  === 'email';
  }.property('model.element_subtype'),

  pushesText: function () {
    if (this.get('model.placement') === 'bar-top') {
      return 'Pushes page down';
    } else {
      return 'Pushes page up';
    }
  }.property('model.placement')
});
