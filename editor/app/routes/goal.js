import Ember from 'ember';
var firstTime = 0;

export default Ember.Route.extend({
  beforeModel(transition) {
    if ((window.location.href.indexOf("/edit") !== -1) && transition.resolvedModels.application.element_subtype && transition.resolvedModels.application.type && firstTime < 1 ) {
      this.transitionTo('design');
      firstTime+= 1;
    }
  }
});
