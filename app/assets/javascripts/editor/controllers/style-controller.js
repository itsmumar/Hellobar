HelloBar.StyleController = Ember.Controller.extend({

  //-----------  Step Settings  -----------#

  step: 2,
  prevStep: 'settings',
  nextStep: 'design',

  //-----------  Sub-Step Selection  -----------#

  // Sets a property which tells the route to forward to a previously
  // selected child route (ie. sub-step)

  routeForwarding: false,

  setType: (function() {
    switch (this.get('routeForwarding')) {
      case 'style.modal':
        this.set('model.type', 'Modal');
        break;
      case 'style.slider':
        this.set('model.type', 'Slider');
        break;
      case 'style.takeover':
        this.set('model.type', 'Takeover');
        break;
      default:
        this.set('model.type', 'Bar');
    }
    if (trackEditorFlow) { return InternalTracking.track_current_person("Editor Flow", {step: "Style Settings", goal: this.get("model.element_subtype")}); }
  }).observes('routeForwarding'),

  trackStyleView: (function() {
    if (trackEditorFlow && !Ember.isEmpty(this.get('model'))) { return InternalTracking.track_current_person("Editor Flow", {step: "Choose Style", goal: this.get("model.element_subtype")}); }
  }).observes('model').on('init'),

  actions: {

    changeStyle() {
      this.set('routeForwarding', false);
      this.transitionToRoute('style');
      return false;
    }
  }
});
