HelloBar.SettingsController = Ember.Controller.extend({

  //-----------  Step Settings  -----------#

  needs: ['application'],
  cannotContinue: ( function () {
    return this.set('controllers.application.cannotContinue', Ember.isEmpty(this.get('model.element_subtype')));
  }).observes('model.element_subtype'),

  step: 1,
  prevStep: false,
  nextStep: 'style',
  hasSideArrows: ( () => false).property(),

  //-----------  Sub-Step Selection  -----------#

  setSubtype: (function () {
    switch (this.get("routeForwarding")) {
      case "settings.emails":
        this.set("model.element_subtype", "email");
        break;
      case "settings.call":
        this.set("model.element_subtype", "call");
        break;
      case "settings.click":
        this.set("model.element_subtype", "traffic");
        break;
      case "settings.announcement":
        this.set("model.element_subtype", "announcement");
        break;
      case "settings.social":
        this.set("model.element_subtype", "social/like_on_facebook");
        break;
    }
    if (trackEditorFlow) {
      return InternalTracking.track_current_person("Editor Flow", {
        step: "Goal Settings",
        goal: this.get("model.element_subtype")
      });
    }
  }).observes('routeForwarding'),

  // Sets a property which tells the route to forward to a previously
  // selected child route (ie. sub-step)

  routeForwarding: false,

  actions: {

    changeSettings() {
      this.set('routeForwarding', false);
      this.transitionToRoute('settings');
      return false;
    }
  }
});
