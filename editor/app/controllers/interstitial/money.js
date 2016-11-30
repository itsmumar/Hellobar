import Ember from 'ember';

export default Ember.Controller.extend({

  setDefaults() {
    if (!this.get("model")) {
      return false;
    }

    this.set("model.headline", "Check out our latest sale");
    this.set("model.link_text", "Shop Now");
    return this.set("model.element_subtype", "traffic");
  },

  inputIsInvalid: ( function () {
    return !!(
      Ember.isEmpty(this.get("model.headline")) ||
      Ember.isEmpty(this.get("model.link_text")) ||
      Ember.isEmpty(this.get("model.settings.url"))
    );
  }).property(
    "model.settings.url",
    "model.link_text",
    "model.headline"
  ),

  actions: {
    closeInterstitial() {
      return this.transitionToRoute("style");
    }
  }
});
