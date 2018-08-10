import Ember from 'ember';
import InterstitialNestedRouteMixin from '../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Have Questions? Get Our Team Live On The Phone!',
      'link_text': 'Call Now!',
      'element_subtype': 'call',
      'type': 'Slider'
    });
    this.get('router').transitionTo('design');
  }

});
