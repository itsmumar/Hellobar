import Ember from 'ember';

import { VIEW_DESKTOP, VIEW_TABLET, VIEW_MOBILE } from '../constants';

export default Ember.Mixin.create({

  isMobile: function () {
    return this.get('viewMode') === VIEW_MOBILE;
  }.property('viewMode'),

  isTablet: function () {
    return this.get('viewMode') === VIEW_TABLET;
  }.property('viewMode'),

  isDesktop: function () {
    return this.get('viewMode') === VIEW_DESKTOP;
  }.property('viewMode'),

  viewMode: VIEW_DESKTOP,

  forceMobileBarForCall: function () {
    if (this.get('model.element_subtype') === 'call') {
      this.set('viewMode', VIEW_MOBILE);
    }
  }.observes('model.element_subtype'),

  manageMobileOnTypeAndSubtypeChange: function () {
    const elementType = this.get('model.type');
    const currentTheme = this.get('theming.currentTheme');
    const elementSubtype = this.get('model.element_subtype');
    const view = this.get('viewMode');

    if (elementType !== 'Bar' && currentTheme.type === 'generic' && elementSubtype !== 'call' && view !== VIEW_DESKTOP) {
      this.set('viewMode', VIEW_DESKTOP);
    }

    if (elementSubtype === 'call' && view !== VIEW_MOBILE) {
      this.set('viewMode', VIEW_MOBILE);
    }
  }.observes('model.element_subtype', 'model.type')

});
