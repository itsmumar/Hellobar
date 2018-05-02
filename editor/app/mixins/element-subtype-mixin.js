import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({
  isEmailSubtype: function () {
    return this.get('model.element_subtype') === 'email'
  }.property('model.element_subtype')
});
