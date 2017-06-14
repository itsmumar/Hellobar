import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  style: Ember.computed.alias('model.type'),

  propertiesComponentName: function() {
    const style = this.get('style');
    return `styles/${style}/${style}-style-properties`;
  }.property('style')

});
