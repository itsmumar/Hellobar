import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {boolean}
   */
  isMobile: false,

  /**
   * @property {boolean}
   */
  isFullscreen: false,

  /**
   * @property {string}
   */
  goal: true,

  /**
   * @property {string}
   */
  style: true,

  tagName: 'nav',

  classNames: ['step-navigation', 'links-wrapper'],

  actions: {
    toggleMobile() {
      this.toggleProperty('isMobile');
    },

    toggleFullscreen() {
      this.toggleProperty('isFullscreen');
    },

    closeEditor() {
      this.sendAction('closeEditor');
    }
  }

});
