import Ember from 'ember';
import _ from 'lodash/lodash';
import config from './config/environment';

const Router = Ember.Router.extend({

  bus: Ember.inject.service('bus'),

  location: config.locationType,
  rootURL: window.location.pathname,
  onTransition: function() {
    const owner = Ember.getOwner(this);
    const routeName = this.currentRouteName;
    const parentRoute = routeName.split('.')[0];
    if (owner.lookup('route:application').get('currentModel')) {
      const controller = owner.lookup('controller:' + parentRoute);
      this._applyRoute(controller, routeName);
      this._updateStepNavigation(controller);
      this._updateRightPaneVisibility(routeName);
    }
  }.on('didTransition'),

  _applyRoute(controller, routeName) {
    if (controller && _.isFunction(controller.applyRoute)) {
      controller.applyRoute(routeName);
    }
  },

  _updateRightPaneVisibility(routeName) {
    if ((!routeName) || (routeName.indexOf('style') !== 0)) {
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    }
  },

  _updateStepNavigation(controller) {
    if (controller.step) {
      const applicationController = Ember.getOwner(this).lookup('controller:application');
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

  this.route('goals', function () {
      this.route('click'); // TODO rename to traffic?
      this.route('email');
      this.route('social');
      this.route('announcement');
      this.route('call');
    }
  );

  this.route('styles', function () {
      this.route('alert');
      this.route('bar');
      this.route('modal');
      this.route('slider');
      this.route('custom');
      this.route('takeover');
    }
  );

  this.route('design');

  this.route('text');

  this.route('targeting', function () {
      this.route('everyone');
      this.route('mobile');
      this.route('homepage');
      this.route('custom');
      this.route('saved');
    }
  );

  return this.route('interstitial', function () {
      this.route('call');
      this.route('money', {path: 'promote'});
      this.route('contacts');
      this.route('facebook');
    }
  );
});

export default Router;
