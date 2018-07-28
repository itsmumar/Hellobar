/* globals UpgradeAccountModal, RuleModal */

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

  selectedRule: null,

  init() {
    this._super();
    presetRuleNames.forEach((presetRuleName) => {
      const preparedName = presetRuleName.replace(/\s/g, '');
      this[`shouldShow${preparedName}Preset`] = Ember.computed('model.preset_rule_name', 'selectionInProgress', function () {
        return this.get('selectionInProgress') || this.get('model.preset_rule_name') === presetRuleName;
      });
    });
  },

  rules: function () {
    return this.get('model.site.rules').map(rule => {
      return _.merge(rule, {
        isPaid: this.get('cannotTarget') && rule.name !== 'Everyone'
      })
    });
  }.property('model.site.rules'),

  customRules: function () {
    return this.get('model.site.rules').filter(rule => rule.editable === true);
  }.property('model.site.rules'),

  hasCustomRules: function () {
    return this.get('customRules').length > 0;
  }.property('model.site.rules'),

  associateRuleToModel(rule) {
    this.get('modelLogic').setRule(rule);
  },

  canTarget: function () {
    return this.get('model.site.capabilities.custom_targeted_bars');
  }.property('model.site.capabilities.custom_targeted_bars'),

  cannotTarget: Ember.computed.not('canTarget'),

  selectedRule: function () {
    const ruleId = this.get('model.rule_id');
    const rules = this.get('rules');
    const selectedOption = _.find(rules, ({ id }) => id === ruleId);
    return selectedOption || rules[0];
  }.property('model.rule_id', 'rules'),

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
      },
      upgradeBenefit: 'create custom-targeted rules'
    };
    new UpgradeAccountModal(options).open();
  },

  days: function () {
    return [
      { label: '30 days', duration: 30 },
      { label: '10 days', duration: 10 }
    ];
  }.property(),

  selectedSuccessDuration: function () {
    const duration = this.get('model.success_duration');
    const days = this.get('days');
    return days.find(option => option.duration === duration) || days[0];
  }.property('model.success_duration'),

  selectedDissmissDuration: function () {
    const duration = this.get('model.duration');
    const days = this.get('days');
    return this.get('days').find(option => option.duration === duration) || days[0];
  }.property('model.duration'),

  actions: {
    selectSuccessDuration (option) {
      this.set('model.success_duration', option.duration);
    },

    selectDissmissDuration (option) {
      this.set('model.duration', option.duration);
    },

    selectRule (rule) {
      if (rule !== 'Everyone' && !this.get('canTarget')) {
        this.openUpgradeModal();
        return;
      }

      if (rule === 'Custom') {
        this.associateRuleToModel(null);
        this.set('model.preset_rule_name', rule);
        this.send('openRuleModal', {});
        return;
      }

      if (rule) {
        const rules = this.get('rules');
        this.associateRuleToModel(rules[rule]);
        this.set('model.preset_rule_name', rule);
      }
    },

    openRuleModal(ruleData = {}) {
      if (this.get('cannotTarget')) {
        this.openUpgradeModal();
        return;
      }

      if (this.ruleModal) {
        return;
      }

      const isNewRule = _.isEmpty(ruleData);
      ruleData.siteID = window.siteID;

      this.ruleModal = new RuleModal(this.rulePopUpOptions(ruleData, isNewRule));
      this.ruleModal.open();
    }
  }
});
