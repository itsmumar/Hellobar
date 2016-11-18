import Ember from 'ember';

export default Ember.Controller.extend({
  showFacebookUrl: false,
  facebookLikeOptions: [
    {value: "homepage", label: "Home Page"},
    {value: "use_location_for_url", label: "Current Page Visitor is Viewing"},
    {value: "other", label: "Other"}
  ],

  selectedFacebookLikeOptions: ( function (key, value) {
    if (arguments.length > 1) {
      this.set("showFacebookUrl", false);
      this.set("model.settings.use_location_for_url", false);

      if (value === "homepage") {
        this.set("model.settings.url_to_like", this.get("model.site.url"));
      } else if (value === "use_location_for_url") {
        this.set("model.settings.use_location_for_url", true);
      } else {
        this.set("showFacebookUrl", true);
      }
      return value;
    } else {
      return "homepage";
    }
  }).property(),

  setDefaults() {
    if (!this.get("model")) {
      return false;
    }

    this.set("model.headline", "Like us on Facebook!");
    return this.set("model.element_subtype", "social/like_on_facebook");
  },

  inputIsInvalid: ( function () {
    return !!(
      !this.get("model.settings.use_location_for_url") &&
      Ember.isEmpty(this.get("model.settings.url_to_like"))
    );
  }).property(
    "model.settings.use_location_for_url",
    "model.settings.url_to_like"
  ),

  actions: {
    closeInterstitial() {
      return this.transitionToRoute("style");
    }
  }
});
