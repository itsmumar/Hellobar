import Ember from 'ember';
import InterstitialNestedRouteMixin from '../../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {
  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Join our mailing list to stay up to date on our upcoming events',
      'link_text': 'Subscribe',
      'element_subtype': 'email',
      'type': 'Bar'
    });
    this.get('router').transitionTo('design');
  }

});
