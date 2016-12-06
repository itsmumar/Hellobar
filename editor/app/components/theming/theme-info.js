import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  classNames: ['theme-info'],

  /**
   * @property {object} Current theme. Required.
   */
  theme: null,

  themeName: function () {
    const theme = this.get('theme');
    return theme ? theme.name : '';
  }.property('theme'),

  actions: {
    changeTheme() {
      this.sendAction('onChangeTheme');
    }
  }

});