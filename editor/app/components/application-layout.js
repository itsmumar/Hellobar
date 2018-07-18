import Ember from 'ember';
import { VIEW_DESKTOP, VIEW_TABLET, VIEW_MOBILE } from '../constants';

export default Ember.Component.extend({
  classNames: ['editor-wrapper'],
  classNameBindings: ['isMobile', 'isTablet', 'isDesktop', 'isCallGoal', 'isFullscreen'],

  bus: Ember.inject.service(),
  palette: Ember.inject.service(),
  fullscreenSwitcher: Ember.inject.service(),
  viewMode: VIEW_DESKTOP,

  isMobile: Ember.computed.equal('viewMode', VIEW_MOBILE),
  isTablet: Ember.computed.equal('viewMode', VIEW_TABLET),
  isDesktop: Ember.computed.equal('viewMode', VIEW_DESKTOP),

  isFullscreen: Ember.computed.alias('fullscreenSwitcher.isFullscreen'),

  didRender() {
    Ember.run.next(() => this.get('bus').trigger('hellobar.core.application.initialized'));
  },

  //-----------  Click Action  -----------#

  click(obj) {
    const isCanvas = obj.target.localName === 'canvas';
    const isColorSelect = $(obj.target).closest('.color-select-wrapper').length;

    if (!isCanvas && !isColorSelect) {
      this.set('palette.focusedColor', null);
    }
  }
});
