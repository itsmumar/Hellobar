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
  this.route('announcement');
  this.route('call');
  this.route('traffic');
  this.route('email');
  this.route('social');
  this.route('target');
  this.route('interstitial', function () {
      this.route('call', function () {
        this.route('bar');
        this.route('modal');
        this.route('slider');
        this.route('page-takeover');
        this.route('alert');
      }
      );
      this.route('traffic', function () {
          this.route('bar');
          this.route('modal');
          this.route('slider');
          this.route('page-takeover');
          this.route('alert');
        }
      );
      this.route('email', function () {
          this.route('bar');
          this.route('modal');
          this.route('slider');
          this.route('page-takeover');
          this.route('alert');
        }
      );
      this.route('social', function () {
          this.route('bar');
          this.route('modal');
          this.route('slider');
          this.route('page-takeover');
          this.route('alert');
        }
      );
      this.route('target', function () {
          this.route('bar');
          this.route('modal');
          this.route('slider');
          this.route('page-takeover');
          this.route('alert');
        }
      );
      this.route('announcement', function () {
          this.route('bar');
          this.route('modal');
          this.route('slider');
          this.route('page-takeover');
          this.route('alert');
        }
      );
    }
  );
});

export default Router;
