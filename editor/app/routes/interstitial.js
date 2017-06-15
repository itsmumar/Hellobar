import Ember from 'ember';

export default Ember.Route.extend({

  model() {
    return this.modelFor('application');
  },

  renderTemplate() {
    return this.render({
      outlet: 'interstitial'
    }); // render main interstitial template inside of "interstitial" outlet
  }

});
