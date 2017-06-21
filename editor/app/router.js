import Ember from 'ember';
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
  this.route('targeting');
  this.route('interstitial', function () {
      this.route('call');
      this.route('traffic');
      this.route('email');
      this.route('social');
    }
  );
});

export default Router;
