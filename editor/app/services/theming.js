import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({
  availableThemes() {
    return window.availableThemes ? window.availableThemes : [];
  },

  defaultGenericTheme() {
    return _.find(this.availableThemes(), (theme) => theme.type === 'generic');
  }
});
