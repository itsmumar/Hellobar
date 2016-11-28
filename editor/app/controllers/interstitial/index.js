import Ember from 'ember';

export default Ember.Controller.extend({
  
  needs: ["application"],

  global: ( () => window).property(),

  csrfToken: ( () => $("meta[name=csrf-token]").attr("content")).property(),

  afterModel: (function () {
    // default values are defined in DB schema (shema.rb); we remember them here
    return this.defaults = {
      "model.headline": this.model.headline,
      "model.link_text": this.model.link_text,
      "model.element_subtype": this.model.element_subtype,
      "model.phone_country_code": this.model.phone_country_code
    };
  }).observes("model"),

// Reset defaults when transitioning to interstitial index (called from intersitial-route on controller setup)
  setDefaults() {
    if (!this.get("model")) {
      return false;
    }

    return this.setProperties(this.defaults);
  }
});
