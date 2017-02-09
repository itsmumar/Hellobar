import Ember from 'ember';

/**
 * @class ValidationMessage
 * Message to be displayed for validation purposes.
 */
export default Ember.Component.extend({

  validation: Ember.inject.service(),

  classNames: ['validation-message'],

  /**
   * @property {string} Field name that current message is related to.
   * The field name corresponds to name specified in validation service add() call.
   */
  fieldName: null,

  /**
   * @property {string} Validation unique name which given field belongs to.
   */
  validationName: null,

  /**
   * @property {string} Message text to display.
   * Initial value is null, then the value is updated during validation process.
   */
  text: null,

  didInsertElement() {
    Ember.run.next(() => {
      this.get('validation').registerMessage(this);
    });
  },

  willDestroyElement() {
    this.get('validation').unregisterMessage(this);
  }

});
