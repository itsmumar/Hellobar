import Ember from 'ember';

export default Ember.Component.extend({

  goal: Ember.computed.alias('model.element_subtype'),
  shouldShowEmailProperties: Ember.computed.equal('goal', 'email'),
  shouldShowCallProperties: Ember.computed.equal('goal', 'call'),
  shouldShowTrafficProperties: Ember.computed.equal('goal', 'traffic'),
  shouldShowSocialProperties: Ember.computed.equal('goal', 'social'),
  shouldShowAnnouncementProperties: Ember.computed.equal('goal', 'announcement')

});
