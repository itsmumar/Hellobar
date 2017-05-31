import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({
  availableThemes: Ember.computed.alias('applicationSettings.settings.available_themes'),
  applicationSettings: Ember.inject.service(),

  defaultGenericTheme() {
    return _.find(this.get('availableThemes'), (theme) => theme.type === 'generic');
  }
});
