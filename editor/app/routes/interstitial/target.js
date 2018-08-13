import Ember from 'ember';
import InterstitialNestedRouteMixin from '../mixins/interstitial-nested-route-mixin';

export default Ember.Route.extend(InterstitialNestedRouteMixin, {

  afterModel(model) {
    Ember.setProperties(model, {
      'headline': 'Want To Become An Expert In Hosting Webinars? Join Our Free Webinar Masterclass!',
      'link_text': 'Save Me A Spot!',
      'element_subtype': 'traffic'
    });
  }

});
