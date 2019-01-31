import Ember from 'ember';

export default Ember.Mixin.create({

  isBar: Ember.computed.equal('model.type', 'Bar'),
  isNotBar: Ember.computed.not('isBar'),
  isModal: Ember.computed.equal('model.type', 'Modal'),
  isTakeover: Ember.computed.equal('model.type', 'Takeover'),
  propertiesComponentNameForType: function() {
    const type = this.get('model.type');

    if (!type) {
      return;
    }

    return `design/${ type.toLowerCase() }/properties`;
  }.property('model.type')

});
