import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  applicationController: Ember.inject.controller('application'),

  targetingUiVariant: (() => window.targetingUiVariant).property('model'),

  trackTargetingView: (function () {
    if (trackEditorFlow && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person('Editor Flow', {step: 'Targeting Step'});
    }
  }).observes('model').on('init'),

  //-------------- Helpers ----------------#

  defaultRules: ( function () {
    let rules = this.get('model.site.rules').filter(rule => rule.editable === false);
    return rules.reduce(function (hash, rule) {
        hash[rule.name] = rule;
        return hash;
      }, {});
  }).property(),

  customRules: ( function () {
    return this.get('model.site.rules').filter(rule => rule.editable === true);
  }).property('model.site.rules'),

  hasCustomRules: ( function () {
    return this.get('customRules').length > 0;
  }).property('model.site.rules'),

  associateRuleToModel(rule) {
    this.set('model.rule_id', rule && rule.id);
    this.set('model.rule', rule);
  },

  navigateRoute(newRoute) {
    this.transitionToRoute(newRoute);
  },

  targetingListCssClasses: (function() {
    let classes = ['step-link-wrapper'];
    !this.get('targetingSelectionInProgress') && (classes.push('is-selected'));
    return classes.join(' ');
  }).property('targetingSelectionInProgress'),

  //-----------  Original UI Support  -----------#
  // remove these functions and all code paths where targetingUiVariant == false and/or fucntion names match *Original
  // if/when conclude the a/b test "Targeting UI Variation 2016-06-13" with 'variant'
  // revert this controller to the previous version if we conclude with 'original'

  trackUpgrade() {
    if (trackEditorFlow) {
      return InternalTracking.track_current_person('Editor Flow', {
        step: 'Choose Targeting Type - Converted to Pro',
        ui: this.get('targetingUiVariant') ? 'variant' : 'original'
      });
    }
  },


  canUseRuleModal: ( function () {
    return this.get('model.site.capabilities.custom_targeted_bars');
  }).property('model.site.capabilities.custom_targeted_bars'),

  popNewRuleModal: (function () {
    if (!this.get('targetingUiVariant') && !this.get('model.rule_id')) {
      return this.send('openRuleModalOriginal', {});
    }
  }).observes('model.rule_id'),

  showAfterConvertOptions: [
    {value: true, label: 'Continue showing even after the visitor responds'},
    {value: false, label: 'Stop showing after the visitor provides a response'}
  ],

  hideShowAfterConvertOptions: Ember.computed.equal('model.element_subtype', 'announcement'),

  //-----------  New/Edit Rule Modal  -----------#

  canTarget: ( function () {
    return this.get('model.site.capabilities.custom_targeted_bars');
  }).property('model.site.capabilities.custom_targeted_bars'),

  ruleOptions: ( function () {
    let rules = this.get('model.site.rules').slice().filter(rule => rule.editable === true);
    rules.unshift({name: 'Choose a saved rule...', description: '?', editable: true});
    return rules;
  }).property('model.site.rules'),

  ruleOptionsOriginal: ( function () {
    let rules = this.get('model.site.rules').slice();
    rules = rules.filter(rule => rule.name !== 'Mobile Visitors' && rule.name !== 'Homepage Visitors');
    rules.push({name: 'Other...', description: '?', editable: true});
    return rules;
  }).property('model.site.rules'),

  selectedRule: (function () {
    let selectedRuleId;
    if (!(selectedRuleId = this.get('model.rule_id'))) {
      return null;
    }
    return this.get('ruleOptions').find(rule => rule.id === selectedRuleId);
  }).property('model.rule_id', 'model.site.rules'),

  selectedRuleOriginal: (function () {
    let selectedRuleId = this.get('model.rule_id');
    return this.get('ruleOptionsOriginal').find(rule => rule.id === selectedRuleId);
  }).property('model.rule_id', 'model.site.rules'),

  //-----------  Step Settings  -----------#

  step: 4,
  prevStep: 'design',
  nextStep: false,


  targetingSelectionInProgress: false,

  applyRoute(routeName) {
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
          /*if (!__in__(this.get('model.rule'), ((() => {
              let result = [];
              for (let name in customRules) {
                let rule = customRules[name];
                result.push(rule);
              }
              return result;
            })()))) {
            this.associateRuleToModel(null);
          }*/
          this.set('model.preset_rule_name', 'Saved');
          break;
        default:
          this.associateRuleToModel(null);
      }
      this.set('targetingSelectionInProgress', false);

      if (trackEditorFlow) {
        return InternalTracking.track_current_person('Editor Flow', {
          step: 'Choose Targeting Type',
          targeting: this.get(routeName)
        });
      }
    }
  },

  showUpgradeModal(newRoute) {
    if (newRoute === 'targeting.index' || newRoute === 'targeting' || newRoute === 'targeting.everyone' || this.get('canTarget')) {
      return false;
    } else {
      if (trackEditorFlow) {
        InternalTracking.track_current_person('Editor Flow', {
          step: 'Choose Targeting Type - Upgrade Modal',
          targeting: newRoute
        });
      }
      this.send('openUpgradeModal', newRoute);
      return true;
    }
  },

  afterModel: (function () {
    let cookieSettings = this.get('model.settings.cookie_settings');
    if (_.isEmpty(cookieSettings)) {
      let elementType = this.get('model.type');
      if (elementType === 'Modal' || elementType === 'Takeover') {
        cookieSettings = {
          duration: 0,
          success_duration: 0
        };
      } else {
        cookieSettings = {
          duration: 0,
          success_duration: 0
        };
      }

      return this.set('model.settings.cookie_settings', cookieSettings);
    }
  }).observes('model'),

  isTopBarStyle: Ember.computed.alias('applicationController.isTopBarStyle'),

  //-----------  Actions  -----------#

  actions: {

    resetRuleDropdown(ruleData = {}) {
      this.set('targetingSelectionInProgress', true);
      if (ruleData.id === undefined) {
        this.associateRuleToModel(null);
      } else {
        this.associateRuleToModel(ruleData);
        this.navigateRoute('targeting.saved');
      }
    },

    openUpgradeModal(successRoute = 'targeting') {
      let controller = this;
      controller.send('resetRuleDropdown');

      let options = {
        site: controller.get('model.site'),
        successCallback() {
          controller.set('model.site.capabilities', this.site.capabilities);
          controller.send('trackUpgrade');
          return controller.send('navigateRoute', successRoute);
        },
        upgradeBenefit: 'create custom-targeted rules'
      };
      return new UpgradeAccountModal(options).open();
    },

    openRuleModal(ruleData = {}) {
      const isNewRule = _.isEmpty(ruleData);
      ruleData.siteID = window.siteID;
      let controller = this;

      let options = {
        ruleData,
        successCallback() {
          ruleData = this;
          let updatedRule = controller.get('model.site.rules').find(rule => rule.id === ruleData.id);

          if (updatedRule) {
            Ember.set(updatedRule, 'conditions', ruleData.conditions);
            Ember.set(updatedRule, 'description', ruleData.description);
            Ember.set(updatedRule, 'name', ruleData.name);
            Ember.set(updatedRule, 'match', ruleData.match);
            Ember.set(updatedRule, 'priority', ruleData.priority);
          } else { // we created a new rule
            controller.get('model.site.rules').push(ruleData);
          }

          controller.associateRuleToModel(ruleData);
          return controller.notifyPropertyChange('model.site.rules');
        },
        close() {
          isNewRule && controller.send('resetRuleDropdown', ruleData);
        }
      };

      return new RuleModal(options).open();
    },

    // remove resetRuleDropdownOriginal, openRuleModalOriginal and openUpgradeModalOriginal
    // if/when conclude the a/b test "Targeting UI Variation 2016-06-13" with 'variant'
    // revert this controller to the previous version if we conclude with 'original'

    resetRuleDropdownOriginal(ruleData = {}) {
      if (ruleData.id === undefined) {
        let firstRule = this.get('model.site.rules')[0];
        if (!firstRule) {
          firstRule = {id: null};
        }
        return this.set('model.rule_id', firstRule.id);
      }
    },

    openRuleModalOriginal(ruleData) {
      if (trackEditorFlow) {
        InternalTracking.track_current_person('Editor Flow', {
          step: 'Edit Targeting',
          goal: this.get('model.element_subtype'),
          style: this.get('model.type')
        });
      }
      if (!this.get('canUseRuleModal')) {
        return this.send('openUpgradeModalOriginal', ruleData);
      }

      ruleData.siteID = window.siteID;
      let controller = this;

      let options = {
        ruleData,
        successCallback() {
          ruleData = this;
          let updatedRule = controller.get('model.site.rules').find(rule => rule.id === ruleData.id);

          if (updatedRule) {
            Ember.set(updatedRule, 'conditions', ruleData.conditions);
            Ember.set(updatedRule, 'description', ruleData.description);
            Ember.set(updatedRule, 'name', ruleData.name);
            Ember.set(updatedRule, 'match', ruleData.match);
            Ember.set(updatedRule, 'priority', ruleData.priority);
          } else {
            // we created a new rule
            controller.get('model.site.rules').push(ruleData);
          }

          controller.set('model.rule_id', ruleData.id);
          return controller.notifyPropertyChange('model.site.rules');
        },
        close() {
          return controller.send('resetRuleDropdownOriginal', ruleData);
        }
      };

      return new RuleModal(options).open();
    },

    openUpgradeModalOriginal(ruleData = {}) {
      let controller = this;
      controller.send('resetRuleDropdownOriginal', ruleData);

      let options = {
        site: controller.get('model.site'),
        successCallback() {
          controller.set('model.site.capabilities', this.site.capabilities);
          return controller.send('trackUpgrade');
        },
        upgradeBenefit: 'create custom-targeted rules'
      };
      return new UpgradeAccountModal(options).open();
    }
  }
});

function __in__(needle, haystack) {
  return haystack.indexOf(needle) >= 0;
}
