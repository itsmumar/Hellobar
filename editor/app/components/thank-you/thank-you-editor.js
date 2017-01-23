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
      function setValue() {
        component.set('afterSubmitOptionSelected', selection);
        component.set('model.settings.after_email_submit_action', selection.value);
      }
      if (selection.isPro) {
        let left;
        new UpgradeAccountModal({
          site: this.get('model.site'),
          upgradeBenefit: (left = selection.key === 'redirect') != null ? left : {'redirect to a custom url': 'customize your thank you text'},
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
