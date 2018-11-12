import Ember from 'ember';


export default Ember.Component.extend( {
  classNames: ['design-step'],
  isTakeover: Ember.computed.equal('model.type', 'Takeover'),
});
