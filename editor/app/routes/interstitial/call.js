import Ember from 'ember';
import InterstitialNestedRouteMixin from '../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Talk to us to find out more',
      'link_text': 'Call Now',
      'element_subtype': 'call'
    });
  }

});
