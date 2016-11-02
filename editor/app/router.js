import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function () {
  this.route('home', {path: '/'});

  this.route('settings', function () {
      this.route('emails');
      this.route('social');
      this.route('click');
      this.route('call');
      this.route('feedback');
      return this.route('announcement');
    }
  );

  this.route('style', function () {
      this.route('bar');
      this.route('modal');
      this.route('slider');
      return this.route('takeover');
    }
  );

  this.route('design');

  this.route('text');

  this.route('targeting', function () {
      this.route('everyone');
      this.route('mobile');
      this.route('homepage');
      this.route('custom');
      return this.route('saved');
    }
  );

  return this.route('interstitial', function () {
      this.route('call');
      this.route('money', {path: 'promote'});
      this.route('contacts');
      return this.route('facebook');
    }
  );
});

export default Router;
