import Ember from 'ember';
import InterstitialNestedRouteMixin from '../../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Click “Like” To Learn How To Generate 100+ New Followers a Month Without Spending a Dollar on Ads!',
      'element_subtype': 'social/like_on_facebook',
      'type': 'Alert'
    });
    this.get('router').transitionTo('design');
  }

});
