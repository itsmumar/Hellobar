import Ember from 'ember';
import _ from 'lodash/lodash';

/**
 * @class ValidationSummary
 * Shows overall information about all validation checks
 */
export default Ember.Component.extend({

  classNames: ['validation-summary'],
  classNameBindings: ['shouldShowSummary:visible'],

  /**
   * @property {array} Messages from miscellaneous input components
   */
  validationMessages: null,

  /**
   * @property {string} Heading text (description of validation context)
   */
  header: null,

  shouldShowSummary: function () {
    return !_.isEmpty(this.get('validationMessages'));
  }.property('validationMessages'),

  summaryText: function() {
    return (this.get('validationMessages') || []).join(' ');
  }.property('validationMessages')

});
