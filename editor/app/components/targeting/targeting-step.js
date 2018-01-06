/* globals InternalTracking, UpgradeAccountModal, RuleModal */

import Ember from 'ember';
import _ from 'lodash/lodash';

const presetRuleNames = ['Everyone', 'Mobile Visitors', 'Homepage Visitors', 'Custom', 'Saved'];

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  applicationSettings: Ember.inject.service(),
  modelLogic: Ember.inject.service(),

  selectionInProgress: null,

  init() {
    this._super();
    this.set('selectionInProgress', !this.get('model.preset_rule_name'));
    presetRuleNames.forEach((presetRuleName) => {
      const preparedName = presetRuleName.replace(/\s/g, '');
      this[`shouldShow${preparedName}Preset`] = Ember.computed('model.preset_rule_name', 'selectionInProgress', function () {
        return this.get('selectionInProgress') || this.get('model.preset_rule_name') === presetRuleName;
      });
    });
  },

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
    this.get('modelLogic').setRule(rule);
  },

  trackUpgrade() {
    if (this.get('applicationSettings.settings.track_editor_flow')) {
      InternalTracking.track_current_person('Editor Flow', {
        step: 'Choose Targeting Type - Converted to Pro',
        ui: this.get('targetingUiVariant') ? 'variant' : 'original'
      });
    }
  },

  canTarget: function () {
    return this.get('model.site.capabilities.custom_targeted_bars');
  }.property('model.site.capabilities.custom_targeted_bars'),

  cannotTarget: Ember.computed.not('canTarget'),

  ruleOptions: function () {
    let rules = this.get('model.site.rules').slice().filter(rule => rule.editable === true);
    rules.unshift({name: 'Choose a saved rule...', description: '', editable: false});
    return rules || [];
  }.property('model.site.rules'),

  selectedRule: function () {
    const ruleId = this.get('model.rule_id');
    const options = this.get('ruleOptions');
    const selectedOption = _.find(options, (option) => option.id === ruleId);
    return selectedOption || options[0];
  }.property('model.rule_id', 'ruleOptions'),

  rulePopUpOptions: function (ruleData, isNewRule) {
    const that = this;

    const options = {
      ruleData,
      site: this.get('model.site'),
      successCallback() {
        that.ruleModal = null;
        ruleData = this;
        let updatedRule = that.get('model.site.rules').find(rule => rule.id === ruleData.id);

        if (updatedRule) {
          Ember.set(updatedRule, 'conditions', ruleData.conditions);
          Ember.set(updatedRule, 'description', ruleData.description);
          Ember.set(updatedRule, 'name', ruleData.name);
          Ember.set(updatedRule, 'match', ruleData.match);
        } else { // we created a new rule
          that.get('model.site.rules').push(ruleData);
        }

        that.notifyPropertyChange('model.site.rules');

        that.associateRuleToModel(ruleData);
        that.set('selectionInProgress', false);
      },
      close(cancel = true) {
        that.ruleModal = null;

        // reset to previous rule if we are cancelling
        if (cancel && isNewRule) {
          that.send('initiateSelection', ruleData);
        }
      }
    };

    return options;
  },

  shouldShowSavedRuleList: function() {
    return !this.get('selectionInProgress') && this.get('model.preset_rule_name') === 'Saved';
  }.property('model.preset_rule_name', 'selectionInProgress'),

  openUpgradeModal() {
    const that = this;
    that.send('initiateSelection');

    const options = {
      site: that.get('model.site'),
      successCallback() {
        that.set('model.site.capabilities', this.site.capabilities);
        that.send('trackUpgrade');
      },
      upgradeBenefit: 'create custom-targeted rules'
    };
    new UpgradeAccountModal(options).open();
  },

  actions: {

    select(presetRuleName) {
      if (!this.get('selectionInProgress')) {
        return;
      }
      if (presetRuleName !== 'Everyone' && !this.get('canTarget')) {
        this.openUpgradeModal();
        return;
      }

      if (presetRuleName === 'Custom') {
        this.associateRuleToModel(null);
        this.set('model.preset_rule_name', presetRuleName);
        this.send('openRuleModal', {});
      } else if (presetRuleName) {
        const defaultRules = this.get('defaultRules');
        this.associateRuleToModel(defaultRules[presetRuleName]);
        this.set('model.preset_rule_name', presetRuleName);
      }

      this.set('selectionInProgress', false);
    },

    initiateSelection(ruleData = {}) {
      this.set('selectionInProgress', true);

      if (ruleData.id !== undefined) {
        this.associateRuleToModel(ruleData);
      }
    },

    openRuleModal(ruleData = {}) {
      if (this.ruleModal) {
        return;
      }

      const isNewRule = _.isEmpty(ruleData);
      ruleData.siteID = window.siteID;

      this.ruleModal = new RuleModal(this.rulePopUpOptions(ruleData, isNewRule));
      this.ruleModal.open();
    },

    selectTargetingRule(rule) {
      this.set('model.rule_id', rule.id);
    }
  }

});
