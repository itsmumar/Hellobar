/* globals ConfirmModal */

import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  theming: Ember.inject.service(),
  bus: Ember.inject.service(),
  inlineEditing: Ember.inject.service(),

  themeSelectionInProgress: false,

  style: Ember.computed.alias('model.type'),

  currentTheme: Ember.computed.alias('theming.currentTheme'),
  currentThemeName: Ember.computed.alias('theming.currentThemeName'),
  isEditing: Ember.computed.bool('model.id'),

  isAlert: Ember.computed.equal('style', 'Alert'),
  isBar: Ember.computed.equal('style', 'Bar'),
  isModal: Ember.computed.equal('style', 'Modal'),
  isSlider: Ember.computed.equal('style', 'Slider'),
  isTakeover: Ember.computed.equal('style', 'Takeover'),

  init() {
    this._super();

    this.get('bus').subscribe('hellobar.core.rightPane.show', (params) => {
        if (params.componentName === 'preview/containers/theming/theme-tile-grid') {
          this.set('themeSelectionInProgress', true);
        }
      }
    );

    this.get('bus').subscribe('hellobar.core.rightPane.hide', (/* params */) => {
        this.set('themeSelectionInProgress', false);
      }
    );
  },

  onlyTopBarStyleIsAvailable: Ember.computed.equal('model.element_subtype', 'call'),
  notOnlyTopBarStyleIsAvailable: Ember.computed.not('onlyTopBarStyleIsAvailable'),

  elementTypeSelectionInProgress: false,
  userSelectedElementTypeExplicitly: false,

  manageRightPaneOnElementTypeChanged: function () {
    let elementType = this.get('model.type');
    if (this.get('isEditing')) {
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    } else {
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'preview/containers/theming/theme-tile-grid',
        componentOptions: {elementType}
      });
    }
    this.get('inlineEditing').initializeInlineEditing(elementType);
  }.observes('model.type'),


  actions: {
    select(style) {
      this.set('style', style);
      if (this.get('theming').resetThemeIfNeeded(style)) {
        this.send('showThemeGrid');
      }
    },

    showThemeGrid() {
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'preview/containers/theming/theme-tile-grid',
        componentOptions: {
          elementType: this.get('model.type')
        }
      });
    },

    changeTheme() {
      const that = this;
      let confirmModal = null;
      const modalOptions = {
        title: 'Are you sure you want to change the theme?',
        text: 'We will save the content and style of your current theme before the update',
        confirmBtnText: 'Yes, Change The Theme',
        cancelBtnText: 'No, Keep The Theme',
        showCloseIcon: true,
        confirm() {
          confirmModal.close();
          that.send('showThemeGrid');
        }
      };
      confirmModal = new ConfirmModal(modalOptions);
      return confirmModal.open();
    }
  }

});
