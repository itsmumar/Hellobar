import Ember from 'ember';
import { VIEW_DESKTOP, VIEW_TABLET, VIEW_MOBILE } from '../constants';

export default Ember.Component.extend({

  classNames: ['editor-wrapper'],
  classNameBindings: ['isMobile', 'isTablet', 'isDesktop', 'isCallGoal'],

  bus: Ember.inject.service(),
  palette: Ember.inject.service(),

  isMobile: function () {
    return this.get('viewMode') === VIEW_MOBILE;
  }.property('viewMode'),

  isTablet: function () {
    return this.get('viewMode') === VIEW_TABLET;
  }.property('viewMode'),

  isDesktop: function () {
    return this.get('viewMode') === VIEW_DESKTOP;
  }.property('viewMode'),

  /**
   * @property {string}
   */
  viewMode: VIEW_DESKTOP,

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
