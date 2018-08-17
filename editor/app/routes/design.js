import Ember from 'ember';

export default Ember.Route.extend({
  theming: Ember.inject.service(),

  beforeModel(transition) {
    if (!transition.resolvedModels.application.element_subtype) {
      this.transitionTo('goal');
    }
  },

  afterModel(model) {
    this.get('theming').applyCurrentTheme();
  }
});
