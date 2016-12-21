import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  //-----------  Step Settings  -----------#

  applicationController: Ember.inject.controller('application'),

  cannotContinue: ( function () {
    return this.set('applicationController.cannotContinue', Ember.isEmpty(this.get('model.element_subtype')));
  }).observes('model.element_subtype'),

  step: 1,
  prevStep: false,
  nextStep: 'style',
  hasSideArrows: ( () => false).property(),

  goalSelectionInProgress: false,

  applyRoute (routeName) {
    const routeByElementSubtype = (elementSubtype) => {
      if (/^social/.test(elementSubtype)) {
        return 'settings.social';
      } else {
        switch (elementSubtype) {
          case 'call':
            return 'settings.call';
          case 'email':
            return 'settings.emails';
          case 'traffic':
            return 'settings.click';
          case 'announcement':
            return 'settings.announcement';
          default:
            return null;
        }
      }
    };
    if (_.endsWith(routeName, '.index')) {
      // We hit the index route. Redirect if required
      const newRouteName = routeByElementSubtype(this.get('model.element_subtype'));
      if (newRouteName) {
        this.transitionToRoute(newRouteName);
      } else {
        $.ajax({ method: "POST", url: `/sites/${siteID}/track_selected_goal` });
        this.set('goalSelectionInProgress', true);
      }
    } else {
      // We hit route for given goal. Update model accordingly
      switch (routeName) {
        case 'settings.emails':
          this.set('model.element_subtype', 'email');
          break;
        case 'settings.call':
          this.set('model.element_subtype', 'call');
          break;
        case 'settings.click':
          this.set('model.element_subtype', 'traffic');
          break;
        case 'settings.announcement':
          this.set('model.element_subtype', 'announcement');
          break;
        case 'settings.social':
          this.set('model.element_subtype', 'social/like_on_facebook');
          break;
      }
      this.set('goalSelectionInProgress', false);
      if (trackEditorFlow) {
        return InternalTracking.track_current_person('Editor Flow', {
          step: 'Goal Settings',
          goal: this.get('model.element_subtype')
        });
      }
    }
  },

  currentThemeIsGeneric: Ember.computed.alias('applicationController.currentThemeIsGeneric'),

  goalListCssClasses: (function () {
    let classes = ['step-link-wrapper'];
    !this.get('goalSelectionInProgress') && (classes.push('is-selected'));
    return classes.join(' ');
  }).property('goalSelectionInProgress'),

  actions: {
    changeSettings() {
      this.set('goalSelectionInProgress', true);
      return false;
    }
  }
});
