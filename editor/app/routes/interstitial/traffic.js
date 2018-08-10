import Ember from 'ember';
import InterstitialNestedRouteMixin from '../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Check out our latest sale',
      'link_text': 'Shop Now',
      'element_subtype': 'traffic'
    });
  }

});
