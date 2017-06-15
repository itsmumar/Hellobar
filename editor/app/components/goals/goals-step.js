import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  goal: Ember.computed.alias('model.element_subtype'),

  propertiesComponentName: function() {
    const [goal] = this.get('goal').split('/');
    return `goals/${goal}/${goal}-goal-properties`;
  }.property('goal')

});
