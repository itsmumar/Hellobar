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

  shouldShowMobileDesktopSwitch: function() {
    return this.get('style') === 'Bar' && this.get('goal') !== 'call';
  }.property('goal', 'style'),

  tagName: 'nav',

  classNames: ['step-navigation', 'links-wrapper']

});
