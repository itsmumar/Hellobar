/* globals ConfirmModal */

import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  theming: Ember.inject.service(),
  bus: Ember.inject.service(),

  themeSelectionInProgress: false,

  style: Ember.computed.alias('model.type'),

  currentTheme: Ember.computed.alias('theming.currentTheme'),
  currentThemeName: Ember.computed.alias('theming.currentThemeName'),

  isAlert: Ember.computed.equal('style', 'Alert'),
  isBar: Ember.computed.equal('style', 'Bar'),
  isModal: Ember.computed.equal('style', 'Modal'),
  isSlider: Ember.computed.equal('style', 'Slider'),
  isTakeover: Ember.computed.equal('style', 'Takeover'),

  onlyTopBarStyleIsAvailable: Ember.computed.equal('model.element_subtype', 'call'),
  notOnlyTopBarStyleIsAvailable: Ember.computed.not('onlyTopBarStyleIsAvailable'),

  actions: {
    select(style) {
      this.set('style', style);
    }
  }
});
