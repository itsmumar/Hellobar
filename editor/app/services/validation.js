import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  _standardValidators: {
    'required': function(objectToValidate, valuePath) {
      return Ember.get(objectToValidate, valuePath) ? null : 'This field is required';
    }
  },

  _validations: {},

  add(validationName, rules) {
    if (this._validations[validationName]) {
      this.remove(validationName);
    }
    const fields = {};
    this._validations[validationName] = {
      rules,
      fields
    };
  },

  remove(validationName) {
    delete this._validations[validationName];
  },

  validate(validationName, objectToValidate) {
    const validation = this._validations[validationName];
    let failedRules = [];
    _.each(validation.rules, (rule) => {
      const { validator, fieldName } = rule;
      const valuePath = rule.valuePath || fieldName;
      const validatorFunction = () => {
        if (_.isString(validator)) {
          const standardValidatorFunction = this._standardValidators[validator];
          if (standardValidatorFunction) {
            return standardValidatorFunction;
          } else {
            console.warn(`Cannot find ${validator} validator`);
          }
        } else if (_.isFunction(validator)) {
          return validator;
        } else {
          console.warn('Unknown validator type', validator);
        }
        return () => null;
      };

      const errorMessageText = validatorFunction()(objectToValidate, valuePath);
      if (errorMessageText) {
        failedRules.push(rule);
      }
      const messageComponents = _.get(validation, `fields.${fieldName}.messageComponents`);
      _.each(messageComponents, (component) => {
        component.set('text', errorMessageText);
      });
    });
    return new Ember.RSVP.Promise((resolve, reject) => {
      _.isEmpty(failedRules) ? resolve() : reject(failedRules);
    });
  },

  _findFieldByComponentAndRun(messageComponent, callback) {
    if (messageComponent) {
      const validationName = messageComponent.get('validationName');
      const fieldName = messageComponent.get('fieldName');
      const validation = this._validations[validationName];
      if (validation) {
        const field = (validation.fields[fieldName] = validation.fields[fieldName] || {});
        callback(field);
      } else {
        console.warn(`registerMessage: validation ${validationName} not found.`);
      }
    }
  },

  registerMessage(messageComponent) {
    this._findFieldByComponentAndRun(messageComponent, (field) => {
      const messageComponents = (field.messageComponents = field.messageComponents || []);
      messageComponents.push(messageComponent);
    });
  },

  unregisterMessage(messageComponent) {
    this._findFieldByComponentAndRun(messageComponent, (field) => {
      field.messageComponents = _.without(field.messageComponents, messageComponent);
    });
  }

});
