import Ember from 'ember';
import InterstitialNestedRouteMixin from '../../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {
  theming: Ember.inject.service(),

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Flash Sale: 20% Off Sitewide, Enter Code “20savings” on Checkout!',
      'link_text': 'Shop Now',
      'element_subtype': 'announcement',
      'type': 'Alert'
    });
    this.get('router').transitionTo('design');
    this.get('theming').applyCurrentTheme();
  }

});
