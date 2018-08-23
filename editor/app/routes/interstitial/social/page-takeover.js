import Ember from 'ember';
import InterstitialNestedRouteMixin from '../../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {
  theming: Ember.inject.service(),

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Click “Like” To Learn How To Generate 100+ New Followers a Month Without Spending a Dollar on Ads!',
      'element_subtype': 'social/like_on_facebook',
      'type': 'Takeover'
    });
    this.get('router').transitionTo('design');
    this.get('theming').applyCurrentTheme();
  }

});
