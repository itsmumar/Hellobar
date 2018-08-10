import Ember from 'ember';
import InterstitialNestedRouteMixin from '../../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Want Free Shipping? Enter Code “Hello1” At Checkout',
      'link_text': 'Yes, I Want FREE SHIPPING!',
      'element_subtype': 'traffic',
      'type': 'Alert'
    });
    this.get('router').transitionTo('design');
  }

});
