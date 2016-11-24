import Ember from 'ember';
import _ from 'lodash/lodash';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: window.emberRootURL,
  onTransition: function() {
    const owner = Ember.getOwner(this);
    const route = this.currentRouteName;
    const parentRoute = route.split('.')[0];
    if (owner.lookup('route:application').get('currentModel')) {
      const controller = this.container.lookup('controller:' + parentRoute);
      this._updateRouteForwarding(controller, route);
      this._updateStepNavigation(controller);
    }

    // TODO uncomment and adopt:
    /*if ((!newRoute) || (newRoute.indexOf('style') !== 0)) {
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    }*/
    // TODO remove this line
    //console.log('onTransition controller=', controller);
  }.on('didTransition'),

  _updateRouteForwarding(controller, route) {
    console.log('_updateRouteForwarding controller = ', controller, ' routeForwarding = ', controller.get('routeForwarding'), ' route = ', route);
    if (controller && (!_.isUndefined(controller.get('routeForwarding')))) {
      if (_.includes(route, '.')) {
        controller.set('routeForwarding', route);
      }

    }
  },

  _updateStepNavigation(controller) {
    if (controller.step) {
      const applicationController = this.container.lookup('controller:application');
      applicationController.setProperties({
        isFullscreen: false,
        currentStep: controller.step,
        prevRoute: controller.prevStep,
        nextRoute: controller.nextStep
      });
    }
  }

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
