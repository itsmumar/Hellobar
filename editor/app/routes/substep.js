import Ember from 'ember';

export default Ember.Route.extend({

  // Tells the sub-steps to use the model associated w/ it's parent step

  model() {
    return this.modelFor('application');
  },

  // Sets auto-forwarding on the parent step upon selection

  setupController(controller, model) {
    this._super(controller, model);

    let parentRoute = this.routeName.split('.')[0];
    return this.controllerFor(parentRoute).set('routeForwarding', this.routeName);
  }
});


//-----------  Setup Sub-Step Routes  -----------#

/*
TODO adopt this:

HelloBar.SettingsSocialRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.SettingsClickRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.SettingsCallRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.SettingsFeedbackRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.SettingsAnnouncementRoute = HelloBar.SettingsStepRoute.extend();

HelloBar.StyleBarRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.StyleModalRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.StyleSliderRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.StyleTakeoverRoute = HelloBar.SettingsStepRoute.extend();

HelloBar.TargetingEveryoneRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.TargetingMobileRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.TargetingHomepageRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.TargetingCustomRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.TargetingSavedRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.TargetingLeavingRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.TargetingScrollRoute = HelloBar.SettingsStepRoute.extend();
HelloBar.TargetingDelayRoute = HelloBar.SettingsStepRoute.extend();

// Switch controllers based upon Email Ingration UI test
HelloBar.SettingsEmailsRoute = HelloBar.SettingsStepRoute.extend();
*/
