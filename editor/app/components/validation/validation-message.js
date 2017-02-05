import Ember from 'ember';

export default Ember.Component.extend({

  validation: Ember.inject.service(),

  classNames: ['validation-message'],

  /**
   * @property {string}
   */
  fieldName: null,

  /**
   * @property {string}
   */
  validationName: null,

  /**
   * @property {string}
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
