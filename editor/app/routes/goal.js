import Ember from 'ember';

export default Ember.Route.extend({
  beforeModel(transition) {
    if (transition.resolvedModels.application.element_subtype && transition.resolvedModels.application.type ) {
      this.transitionTo('design');
    }
  }
});
