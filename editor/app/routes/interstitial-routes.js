HelloBar.InterstitialRoute = Ember.Route.extend({
  model() {
    return this.modelFor("application");
  },

  renderTemplate() {
    return this.render({
      outlet: "interstitial"
    }); // render main interstitial template inside of "interstitial" outlet
  },

  // Set sub-step forwarding on interstitial load
  setSettingsForwarding(model) {
    let settings = this.controllerFor("settings");

    if (/^social/.test(model.element_subtype)) {
      return settings.routeForwarding = "settings.social";
    } else {
      switch (model.element_subtype) {
        case "call":
          return settings.routeForwarding = "settings.call";
        case "email":
          return settings.routeForwarding = "settings.emails";
        case "traffic":
          return settings.routeForwarding = "settings.click";
        case "announcement":
          return settings.routeForwarding = "settings.announcement";
        default:
          return settings.routeForwarding = false;
      }
    }
  }
});

let NestedInterstitialRoute = HelloBar.InterstitialRoute.extend({
  renderTemplate() {
    return this.render({
      into: "interstitial"
    }); // render sub-interstitial templates into main "interstitial" template
  },

  setupController(controller, model) {
    this._super(controller, model);

    controller.setDefaults();
    return this.setSettingsForwarding(model);
  }
});


HelloBar.InterstitialIndexRoute = NestedInterstitialRoute.extend();
HelloBar.InterstitialMoneyRoute = NestedInterstitialRoute.extend();
HelloBar.InterstitialContactsRoute = NestedInterstitialRoute.extend();
HelloBar.InterstitialCallRoute = NestedInterstitialRoute.extend();
HelloBar.InterstitialFacebookRoute = NestedInterstitialRoute.extend();
