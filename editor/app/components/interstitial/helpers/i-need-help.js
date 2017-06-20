import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['i-need-help'],

  activated: false,

  csrfToken: function() {
    return $('meta[name=csrf-token]').attr('content');
  }.property(),

  siteID: Ember.computed.alias('model.site.id'),

  returnTo: function() {
    let siteID = this.get('siteID');
    return `/sites/${siteID}/site_elements/new`;
  }.property('siteID'),

  actions: {
    onToggle() {
      this.toggleProperty('activated');
    },

    onCancel() {
      this.set('activated', false);
    }
  }

});
