HelloBar.StepRoute = Ember.Route.extend({

// All step routes simply use the model loaded the the ApplicationRoute

  model() {
    return this.modelFor('application');
  },

// Updates the current step in the application controller. Currently
// being used to keep the step navigation component tracking correctly.
// Also auto-forwards to an appropriate sub-step route if one has been
// chosen.

  setupController(controller, model) {
    this._super(controller, model);

    this.controllerFor('application').setProperties({
      isFullscreen: false,
      currentStep: controller.step,
      prevRoute: controller.prevStep,
      nextRoute: controller.nextStep
    });

    if (controller.routeForwarding) {
      return this.replaceWith(controller.routeForwarding);
    }
  },

  actions: {
    didTransition(t) {
      let model = this.model();
      let currentRoute = this.controllerFor("application").get("currentRouteName");
      // redirect to interstitial to select a goal after a page refresh unless it's rememebered in model
      // currentRoute==undefined indicates page refresh
      if (!(currentRoute || HB_DATA.skipInterstitial || model.element_subtype)) {
        return this.replaceWith("interstitial");
      }
    }
  }});


//-----------  Setup Step Routes  -----------#

HelloBar.StyleRoute = HelloBar.StepRoute.extend();
HelloBar.DesignRoute = HelloBar.StepRoute.extend();
HelloBar.TargetingRoute = HelloBar.StepRoute.extend();
HelloBar.SettingsRoute = HelloBar.StepRoute.extend();

HelloBar.TextRoute = HelloBar.StepRoute.extend({
// A hack to ensure the preview is in sync with the question tabs
  setupController(controller, model) {
    this._super(controller, model);
    if (model.use_question) {
      return controller.send('showQuestion');
    }
  }
});
