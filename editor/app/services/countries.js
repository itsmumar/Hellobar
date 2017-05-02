import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({
  applicationSettings: Ember.inject.service(),
  all: Ember.computed.alias('applicationSettings.settings.country_codes')
});
