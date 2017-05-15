import Ember from 'ember';
import _ from 'lodash/lodash';
import config from './config/environment';

const Router = Ember.Router.extend({

  bus: Ember.inject.service('bus'),

  location: config.locationType,
  rootURL: window.location.pathname

});

Router.map(function () {
  this.route('home', {path: '/'});

  this.route('goals');

  this.route('styles');

  this.route('design');

  this.route('text');

  // TODO REFACTOR cleanup
  this.route('targeting'/*, function () {
      this.route('everyone');
      this.route('mobile');
      this.route('homepage');
      this.route('custom');
      this.route('saved');
    }
  */);

  return this.route('interstitial', function () {
      this.route('call');
      this.route('money', {path: 'promote'});
      this.route('contacts');
      this.route('facebook');
    }
  );
});

export default Router;
