import Ember from 'ember';
import _ from 'lodash/lodash';

// TODO REFACTOR remove controller
export default Ember.Controller.extend({

  /*applyRoute(routeName) {
   const routeByTargeting = (presetRuleName) => {
   switch (presetRuleName) {
   case 'Everyone':
   return 'targeting.everyone';
   case 'Mobile Visitors':
   return 'targeting.mobile';
   case 'Homepage Visitors':
   return 'targeting.homepage';
   case 'Saved':
   return 'targeting.saved';
   default:
   return null;
   }
   };
   if (_.endsWith(routeName, '.index')) {
   // We hit the index route. Redirect if required
   const newRouteName = routeByTargeting(this.get('model.preset_rule_name'));
   if (newRouteName) {
   this.transitionToRoute(newRouteName);
   } else {
   this.set('targetingSelectionInProgress', true);
   }
   } else {

   if (this.showUpgradeModal(routeName)) {
   // If account is free then we show Upgrade Dialog and cannot proceed with targeting setting
   return;
   }

   // We hit route for given targeting. Update model accordingly
   let defaultRules = this.get('defaultRules');
   let customRules = this.get('customRules');

   switch (routeName) {
   case 'targeting.everyone':
   this.associateRuleToModel(defaultRules['Everyone']);
   this.set('model.preset_rule_name', 'Everyone');
   break;
   case 'targeting.mobile':
   this.associateRuleToModel(defaultRules['Mobile Visitors']);
   this.set('model.preset_rule_name', 'Mobile Visitors');
   break;
   case 'targeting.homepage':
   this.associateRuleToModel(defaultRules['Homepage Visitors']);
   this.set('model.preset_rule_name', 'Homepage Visitors');
   break;
   case 'targeting.custom':
   this.associateRuleToModel(null);
   this.send('openRuleModal');
   break;
   case 'targeting.saved':
   this.set('model.preset_rule_name', 'Saved');
   break;
   default:
   this.associateRuleToModel(null);
   }
   this.set('targetingSelectionInProgress', this.get('showDropdown'));

   if (this.get('applicationSettings.track_editor_flow')) {
   InternalTracking.track_current_person('Editor Flow', {
   step: 'Choose Targeting Type',
   targeting: this.get(routeName)
   });
   }
   }
   },*/

});
