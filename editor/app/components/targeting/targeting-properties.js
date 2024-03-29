/* globals UpgradeAccountModal, RuleModal */

import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  applicationSettings: Ember.inject.service(),
  modelLogic: Ember.inject.service(),

  rules: function () {
    return this.get('model.site.rules').map(rule => {
      return _.merge(rule, {
        isPaid: (this.get('cannotTarget') && (rule.name !== 'Everyone' && rule.name !== 'Mobile Visitors'))
      });
    });
  }.property('model.site.rules'),

  associateRuleToModel(rule) {
    this.get('modelLogic').setRule(rule);
  },

  canTarget: function () {
    return this.get('model.site.capabilities.custom_targeted_bars');
  }.property('model.site.capabilities.custom_targeted_bars'),

  cannotTarget: Ember.computed.not('canTarget'),

  selectedRule: function () {
    this.set('model.show_thankyou',false);
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

  openUpgradeModal(rule) {
    const that = this;
    that.send('initiateSelection');

    const options = {
      site: that.get('model.site'),
      successCallback() {
        that.set('model.site.capabilities', this.site.capabilities);
      },
      upgradeBenefit: 'enable more targeting features, upgrade your subscription for',
      amplitudeSource: rule,
    };
    new UpgradeAccountModal(options).open();
  },

  days: function () {
    return  [
      { label: 'Display after every page load', duration: 0},
      { label: '1 day', duration: 1 },
      { label: '2 days', duration: 2 },
      { label: '3 days', duration: 3 },
      { label: '4 days', duration: 4 },
      { label: '5 days', duration: 5 },
      { label: '6 days', duration: 6 },
      { label: '7 days', duration: 7 },
      { label: '8 days', duration: 8 },
      { label: '9 days', duration: 9 },
      { label: '10 days', duration: 10 },
      { label: '15 days', duration: 15 },
      { label: '20 days', duration: 20 },
      { label: '30 days', duration: 30 },
      { label: '60 days', duration: 60 },
      { label: '90 days', duration: 90 },
      { label: '120 days', duration: 120 },
      { label: 'Never display again', duration: 150 }
    ];
  }.property(),

  selectedSuccessDuration: function () {
    const duration = this.get('model.settings.cookie_settings.success_duration');
    const days = this.get('days');
    return days.find(option => option.duration === duration) || days[3];
  }.property('model.settings.cookie_settings.success_duration'),

  selectedDissmissDuration: function () {
    const duration = this.get('model.settings.cookie_settings.duration');
    const days = this.get('days');
    return this.get('days').find(option => option.duration === duration) || days[3];
  }.property('model.settings.cookie_settings.duration'),

  shouldShowDissmissDuration: function () {
    if(this.get('model.type') === 'Modal') {
      return true;
    } else if(this.get('model.type') === 'Takeover') {
      return true;
    } else { return this.get('model.closable'); }
  }.property('model.closable'),

  shouldShowSuccessDuration: function () {
    return this.get('model.element_subtype') !== 'announcement';
  }.property('model.type'),

  actions: {
    selectSuccessDuration (option) {
      this.set('model.settings.cookie_settings.success_duration', option.duration);
    },

    selectDissmissDuration (option) {
      this.set('model.settings.cookie_settings.duration', option.duration);
    },

    selectRule (rule) {
      if (rule && rule.isPaid) {
        this.openUpgradeModal(rule.name);
        return;
      }

      if (rule === 'Custom') {
        this.associateRuleToModel(null);
        this.set('model.preset_rule_name', rule);
        this.send('openRuleModal', {});
        return;
      }

      if (rule) {
        this.associateRuleToModel(rule);
        this.set('model.preset_rule_name', rule);
      }
    },

    openRuleModal(ruleData = {}) {
      if (this.get('cannotTarget')) {
        const rule = "Custom Rule";
        this.openUpgradeModal(rule);
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
