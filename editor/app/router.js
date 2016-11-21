import Ember from 'ember';
import _ from 'lodash/lodash';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL,
  onTransition: function() {
    const route = this.currentRouteName;
    const parentRoute = route.split('.')[0];
    const controller = this.container.lookup('controller:' + parentRoute);
    controller && (!_.isUndefined(controller.get('routeForwarding'))) && (controller.set('routeForwarding', route));
    // TODO remove this line
    console.log('onTransition controller=', controller);
  }.on('didTransition')
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
