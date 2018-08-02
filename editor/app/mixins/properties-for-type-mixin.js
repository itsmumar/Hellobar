import Ember from 'ember';

export default Ember.Mixin.create({

  isBar: Ember.computed.equal('model.type', 'Bar'),
  isNotBar: Ember.computed.not('isBar'),

  propertiesComponentNameForType: function() {
    const type = this.get('model.type');

    if (!type) {
      return;
    }

    return `design/${ type.toLowerCase() }/properties`;
  }.property('model.type')

});
