import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({

  bus: Ember.inject.service('bus'),

  location: config.locationType,
  rootURL: window.location.pathname

});

Router.map(function () {
  this.route('home', {path: '/'});
  this.route('goal');
  this.route('type');
  this.route('design');
  this.route('settings');
  this.route('targeting');
  this.route('conversion');
  this.route('interstitial', function () {
      this.route('call');
      this.route('traffic');
      this.route('email');
      this.route('social');
      this.route('target');
      this.route('announcement');
    }
  );
});

export default Router;
