import Ember from 'ember';

export default Ember.Mixin.create({
  renderTemplate() {
    return this.render({
      into: 'interstitial'
    }); // render sub-interstitial templates into main 'interstitial' template
  }
});
