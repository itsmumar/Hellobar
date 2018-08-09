import Ember from 'ember';
import InterstitialNestedRouteMixin from '../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Flash Sale: 20% Off Sitewide, Enter Code “20savings” on Checkout!',
      'link_text': 'Shop Now',
      'element_subtype': 'announcement'
    });
  }

});
