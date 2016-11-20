import Ember from 'ember';
import _ from 'lodash/lodash';

function newRegistrationId() {
  return 'component' + _.uniqueId();
}

const registrationAttribute = 'data-registration-id';

export default Ember.Service.extend({

  _components: {},

  register(component) {
    const registrationId = newRegistrationId();
    component.$().attr(registrationAttribute, registrationId);
    this._components[registrationId] = component;
  },

  getByRegistrationId(registrationId) {
    return this._components[registrationId];
  },

  getByDomSelector(domSelector) {
    const registrationId = $(domSelector).first().attr(registrationAttribute);
    return registrationId ? this.getByRegistrationId(registrationId) : null;
  }

});
