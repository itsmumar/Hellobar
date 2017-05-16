import Ember from 'ember';

export default Ember.Component.extend({

  // TODO REFACTOR init these properties
  isMobile: null,
  isFullscreen: null,
  shouldShowMobileDesktopSwitch: null,

  /*shouldShowMobileDesktopSwitch: function() {
    return this.get('isTopBarStyle') && !this.get('isCallType');
  }.property('isTopBarStyle', 'isCallType')*/

  tagName: 'nav',

  classNames: ['step-navigation', 'links-wrapper']

});
