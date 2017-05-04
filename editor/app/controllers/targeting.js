import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({
  queryParams: ['showDropdown'],
  showDropdown: false,

  applicationController: Ember.inject.controller('application'),
  applicationSettings: Ember.computed.alias('applicationController.applicationSettings.settings'),

  targetingUiVariant: (() => window.targetingUiVariant).property('model'),

  trackTargetingView: function () {
    if (this.get('applicationSettings.track_editor_flow') && !Ember.isEmpty(this.get('model'))) {
      InternalTracking.track_current_person('Editor Flow', {step: 'Targeting Step'});
    }
  }.observes('applicationSettings', 'model').on('init'),

  //-------------- Helpers ----------------#

  defaultRules: function () {
    const rules = this.get('model.site.rules').filter(rule => rule.editable === false);
    return rules.reduce(function (hash, rule) {
        hash[rule.name] = rule;
        return hash;
      }, {});
  }.property(),

  customRules: function () {
    return this.get('model.site.rules').filter(rule => rule.editable === true);
  }.property('model.site.rules'),

  hasCustomRules: function () {
    return this.get('customRules').length > 0;
  }.property('model.site.rules'),

  associateRuleToModel(rule) {
    this.set('model.rule_id', rule && rule.id);
    this.set('model.rule', rule);
  },

  navigateRoute(newRoute) {
    this.transitionToRoute(newRoute);
  },

  targetingListCssClasses: function() {
    let classes = ['step-link-wrapper'];
    !this.get('targetingSelectionInProgress') && (classes.push('is-selected'));
    return classes.join(' ');
  }.property('targetingSelectionInProgress'),

  //-----------  Original UI Support  -----------#
  // remove these functions and all code paths where targetingUiVariant == false and/or fucntion names match *Original
  // if/when conclude the a/b test "Targeting UI Variation 2016-06-13" with 'variant'
  // revert this controller to the previous version if we conclude with 'original'

  trackUpgrade() {
    if (this.get('applicationSettings.track_editor_flow')) {
      InternalTracking.track_current_person('Editor Flow', {
        step: 'Choose Targeting Type - Converted to Pro',
        ui: this.get('targetingUiVariant') ? 'variant' : 'original'
      });
    }
  },


  canUseRuleModal: function () {
    return this.get('model.site.capabilities.custom_targeted_bars');
  }.property('model.site.capabilities.custom_targeted_bars'),

  popNewRuleModal: function () {
    if (!this.get('targetingUiVariant') && !this.get('model.rule_id')) {
      this.send('openRuleModal', {});
    }
  }.observes('model.rule_id'),

  showAfterConvertOptions: [
    {value: true, label: 'Continue showing even after the visitor responds'},
    {value: false, label: 'Stop showing after the visitor provides a response'}
  ],

  hideShowAfterConvertOptions: Ember.computed.equal('model.element_subtype', 'announcement'),

  //-----------  New/Edit Rule Modal  -----------#

  canTarget: function () {
    return this.get('model.site.capabilities.custom_targeted_bars');
  }.property('model.site.capabilities.custom_targeted_bars'),

  ruleOptions: function () {
    let rules = this.get('model.site.rules').slice().filter(rule => rule.editable === true);
    rules.unshift({name: 'Choose a saved rule...', description: '?', editable: true});
    return rules;
  }.property('model.site.rules'),

  ruleOptionsOriginal: function () {
    let rules = this.get('model.site.rules').slice();
    rules = rules.filter(rule => rule.name !== 'Mobile Visitors' && rule.name !== 'Homepage Visitors');
    rules.push({name: 'Other...', description: '?', editable: true});
    return rules;
  }.property('model.site.rules'),

  selectedRule: function () {
    let selectedRuleId;
    if (!(selectedRuleId = this.get('model.rule_id'))) {
      return null;
    }
    return this.get('ruleOptions').find(rule => rule.id === selectedRuleId);
  }.property('model.rule_id', 'model.site.rules'),

  selectedRuleOriginal: function () {
    let selectedRuleId = this.get('model.rule_id');
    return this.get('ruleOptionsOriginal').find(rule => rule.id === selectedRuleId);
  }.property('model.rule_id', 'model.site.rules'),

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
  },

  showUpgradeModal(newRoute) {
    if (newRoute === 'targeting.index' || newRoute === 'targeting' || newRoute === 'targeting.everyone' || this.get('canTarget')) {
      return false;
    } else {
      if (this.get('applicationSettings.track_editor_flow')) {
        InternalTracking.track_current_person('Editor Flow', {
          step: 'Choose Targeting Type - Upgrade Modal',
          targeting: newRoute
        });
      }
      this.send('openUpgradeModal', newRoute);
      return true;
    }
  },

  afterModel: function () {
    let cookieSettings = this.get('model.settings.cookie_settings');
    if (_.isEmpty(cookieSettings)) {
      const elementType = this.get('model.type');
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

      this.set('model.settings.cookie_settings', cookieSettings);
    }
  }.observes('model'),

  isTopBarStyle: Ember.computed.alias('applicationController.isTopBarStyle'),

  rulePopUpOptions: function(ruleData, isNewRule) {
    const controller = this;

    const options = {
      ruleData,
      successCallback() {
        controller.ruleModal = null;
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
        controller.notifyPropertyChange('model.site.rules');
      },
      close() {
        controller.ruleModal = null;
        controller.transitionToRoute('targeting.index', { queryParams: { showDropdown: 'true' } });
        isNewRule && controller.send('resetRuleDropdown', ruleData);
      }
    };

    return options;
  },

  //-----------  Actions  -----------#

  actions: {

    closeDropdown() {
      this.set('targetingSelectionInProgress', false);
    },

    resetRuleDropdown(ruleData = {}) {
      this.set('targetingSelectionInProgress', true);
      if (ruleData.id !== undefined) {
        this.associateRuleToModel(ruleData);
        this.navigateRoute('targeting.saved');
      }
    },

    openUpgradeModal(successRoute = 'targeting') {
      const controller = this;
      controller.send('resetRuleDropdown');

      const options = {
        site: controller.get('model.site'),
        successCallback() {
          controller.set('model.site.capabilities', this.site.capabilities);
          controller.send('trackUpgrade');
          controller.send('navigateRoute', successRoute);
        },
        upgradeBenefit: 'create custom-targeted rules'
      };
      new UpgradeAccountModal(options).open();
    },

    openRuleModal(ruleData = {}) {
      if (this.ruleModal) return;

      const isNewRule = _.isEmpty(ruleData);
      ruleData.siteID = window.siteID;

      this.ruleModal = new RuleModal(this.rulePopUpOptions(ruleData, isNewRule));
      this.ruleModal.open();
    }
  }
});
