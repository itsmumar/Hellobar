HelloBar.InterstitialCallController = Ember.Controller.extend({
  needs: ["application"],

  setDefaults() {
    if (!this.get("model")) {
      return false;
    }

    this.set("model.headline", "Talk to us to find out more");
    this.set("model.link_text", "Call Now");
    return this.set("model.element_subtype", "call");
  },

  inputIsInvalid: ( function () {
    return !!(
      Ember.isEmpty(this.get("model.headline")) ||
      Ember.isEmpty(this.get("model.link_text")) || !isValidNumber(this.get("controllers.application.phone_number"), this.get("model.phone_country_code"))
    );
  }).property(
    "model.link_text",
    "model.headline",
    "controllers.application.phone_number",
    "model.phone_country_code"
  ),

  actions: {
    closeInterstitial() {
      return this.transitionToRoute("style");
    }
  }
});