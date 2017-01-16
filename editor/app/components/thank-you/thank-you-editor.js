import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['thank-you-editor'],

  afterSubmitOptionSelected: function() {
    const afterSubmitChoiceAsString = this.get('afterSubmitChoice');
    return _.find(this.get('afterSubmitOptions'), (option) => option.key === afterSubmitChoiceAsString);
  }.property('afterSubmitChoice', 'afterSubmitOptions'),

  afterSubmitOptions: function () {
    return [{
      value: 0,
      key: 'default_message',
      label: 'Show default message',
      isPro: false
    }, {
      value: 1,
      key: 'custom_message',
      label: 'Show a custom message',
      isPro: !this.get('model.site.capabilities.custom_thank_you_text')
    }, {
      value: 2,
      key: 'redirect',
      label: 'Redirect the visitor to a url',
      isPro: !this.get('model.site.capabilities.after_submit_redirect')
    }];
  }.property('model.site.capabilities.custom_thank_you_text', 'model.site.capabilities.after_submit_redirect'),

  setModelChoice: function () {
    const choice = this.get('afterSubmitChoice');
    const options = this.get('afterSubmitOptions');
    console.log('setModelChoice choice = ', choice, 'options = ', options);
    if (choice && options) {
      const selection = options.findBy('key', choice);
      this.set('model.settings.after_email_submit_action', selection.value);
    }
  }.observes('afterSubmitChoice', 'afterSubmitOptions'),

  showCustomMessage: Ember.computed.equal('afterSubmitChoice', 'custom_message'),
  showRedirectUrlInput: Ember.computed.equal('afterSubmitChoice', 'redirect'),

  _syncAfterSubmitChoice() {
    // Set Initial After Email Submission Choice
    const modelVal = this.get('model.settings.after_email_submit_action') || 0;
    const selection = this.get('afterSubmitOptions').findBy('value', modelVal);
    this.set('afterSubmitChoice', selection.key);
  },

  didInsertElement() {
    this._syncAfterSubmitChoice();
  },

  onModelChange: function() {
    this._syncAfterSubmitChoice();
  }.observes('model'),

  actions: {
    setModelAfterSubmitValue(selection) {
      if (selection.isPro) {
        let left;
        const controller = this;
        new UpgradeAccountModal({
          site: this.get('model.site'),
          upgradeBenefit: (left = selection.key === 'redirect') != null ? left : {'redirect to a custom url': 'customize your thank you text'},
          successCallback() {
            controller.set('model.site.capabilities', this.site.capabilities);
            controller.set('afterSubmitChoice', selection.key);
          }
        }).open();
      } else {
        this.set('afterSubmitChoice', selection.key);
      }
    }
  }

});
