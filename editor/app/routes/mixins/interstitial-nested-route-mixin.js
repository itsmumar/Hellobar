import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({
  renderTemplate() {
    return this.render({
      into: 'interstitial'
    }); // render sub-interstitial templates into main 'interstitial' template
  }
});
