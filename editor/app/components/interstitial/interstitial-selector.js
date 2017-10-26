import Ember from 'ember';

export default Ember.Component.extend({
  global: ( () => window).property(),

  csrfToken: ( () => $('meta[name=csrf-token]').attr('content')).property(),
  siteID: Ember.computed.alias('model.site.id'),

  afterModel: function () {
    // default values are defined in DB schema (shema.rb); we remember them here
    this.defaults = {
      'model.headline': this.model.headline,
      'model.link_text': this.model.link_text,
      'model.element_subtype': this.model.element_subtype,
      'model.phone_country_code': this.model.phone_country_code
    };
  }.observes('model'),

  // Reset defaults when transitioning to interstitial index (called from intersitial-route on controller setup)
  setDefaults() {
    if (!this.get('model')) {
      return false;
    }

    this.setProperties(this.defaults);
  },

  actions: {
    selectGoal (routeName) {
      if (this.get('siteID')) {
        $.ajax({
          method: 'POST',
          url: `/sites/${this.get('siteID')}/track_selected_goal`
        });
      }

      this.get('router').transitionTo(routeName);
    }
  }
});
