/* globals UpgradeAccountModal */

import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['thank-you-editor'],

  afterSubmitOptionSelected: null,

  afterSubmitOptions: function () {
    return [{
      value: 0,
      key: 'default_message',
      label: 'Show default message',
      isPaid: false
    }, {
      value: 1,
      key: 'custom_message',
      label: 'Show a custom message',
      isPaid: !this.get('model.site.capabilities.custom_thank_you_text')
    }, {
      value: 2,
      key: 'redirect',
      label: 'Redirect the visitor to a url',
      isPaid: !this.get('model.site.capabilities.after_submit_redirect')
    }];
  }.property('model.site.capabilities.custom_thank_you_text', 'model.site.capabilities.after_submit_redirect'),

  _isOptionSelectedEqualGivenKey(key) {
    const afterSubmitOptionSelected = this.get('afterSubmitOptionSelected');
    return afterSubmitOptionSelected && afterSubmitOptionSelected.key === key;
  },

  showCustomMessage: function() {
    return this._isOptionSelectedEqualGivenKey('custom_message');
  }.property('afterSubmitOptionSelected'),

  showRedirectUrlInput: function() {
    return this._isOptionSelectedEqualGivenKey('redirect');
  }.property('afterSubmitOptionSelected'),

  didInsertElement() {
    Ember.run.next(() => {
      const valueFromModel = this.get('model.settings.after_email_submit_action');
      const options = this.get('afterSubmitOptions');
      const selectedOption = _.find(options, (option) => option.value === valueFromModel);
      if (selectedOption) {
        this.set('afterSubmitOptionSelected', selectedOption);
      } else {
        const defaultOption = options[0];
        this.set('afterSubmitOptionSelected', defaultOption);
        this.set('model.settings.after_email_submit_action', defaultOption.value);
      }
    });
  },

  actions: {
    changeAfterSubmitValue(selection) {
      const component = this;
      const setValue = () => {
        this.set('afterSubmitOptionSelected', selection);
        this.set('model.settings.after_email_submit_action', selection.value);
      };
      function chooseUpgradeBenefit() {
        const map = {
          'redirect': 'unlock the next level of Hello Bar, upgrade your subscription for www.example.com',
          'custom_message': 'unlock the next level of Hello Bar, upgrade your subscription for www.example.com'
        };
        return map[selection.key] || '';
      }
      if (selection.isPaid) {
        new UpgradeAccountModal({
          site: this.get('model.site'),
          upgradeBenefit: chooseUpgradeBenefit(),
          successCallback() {
            component.set('model.site.capabilities', this.site.capabilities);
            setValue();
          }
        }).open();
      } else {
        setValue();
      }
    }

  }

});
