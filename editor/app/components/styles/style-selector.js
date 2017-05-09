import Ember from 'ember';

export default Ember.Component.extend({

  bus: Ember.inject.service(),
  inlineEditing: Ember.inject.service(),

  themeSelectionInProgress: false,

  init() {
    this.get('bus').subscribe('hellobar.core.bar.themeChanged', params => {
        this.set('model.theme_id', params.themeId);
        if (!this.get('model.type')) {
          this.set('model.type', params.elementType);
        }
        this.set('userSelectedElementTypeExplicitly', true);
        Ember.run.next(() => {
          this.applyRoute('style.index');
        });
      }
    );
    this.get('bus').subscribe('hellobar.core.rightPane.show', params => {
        if (params.componentName === 'theming/theme-tile-grid') {
          this.set('themeSelectionInProgress', true);
        }
      }
    );
    this.get('bus').subscribe('hellobar.core.rightPane.hide', params => {
        this.set('themeSelectionInProgress', false);
      }
    );
  },

  isCustom: Ember.computed.equal('model.type', 'Custom'),
  currentTheme: Ember.computed.alias('applicationController.currentTheme'),
  currentThemeName: Ember.computed.alias('applicationController.currentThemeName'),
  isEditing: Ember.computed.bool('model.id'),

  _shouldShowThemeInfoForElementType(elementType) {
    return this.get('model.type') === elementType
      && !this.get('themeSelectionInProgress')
      && !this.get('elementTypeSelectionInProgress');
  },

  canUseCustomHtml: Ember.computed.alias('model.site.capabilities.custom_html'),
  canUseAlertElementType: Ember.computed.alias('model.site.capabilities.alert_bars'),

  shouldShowBarThemeInfo: function() {
    return this._shouldShowThemeInfoForElementType('Bar');
  }.property('themeSelectionInProgress', 'elementTypeSelectionInProgress', 'model.type'),

  shouldShowModalThemeInfo: function() {
    return this._shouldShowThemeInfoForElementType('Modal');
  }.property('themeSelectionInProgress', 'elementTypeSelectionInProgress', 'model.type'),

  shouldShowSliderThemeInfo: function() {
    return this._shouldShowThemeInfoForElementType('Slider');
  }.property('themeSelectionInProgress', 'elementTypeSelectionInProgress', 'model.type'),

  shouldShowTakeoverThemeInfo: function() {
    return this._shouldShowThemeInfoForElementType('Takeover');
  }.property('themeSelectionInProgress', 'elementTypeSelectionInProgress', 'model.type'),

  shouldShowAlertThemeInfo: function() {
    return this._shouldShowThemeInfoForElementType('Alert');
  }.property('themeSelectionInProgress', 'elementTypeSelectionInProgress', 'model.type'),

  shouldShowCustomThemeInfo: function() {
    return this._shouldShowThemeInfoForElementType('Custom');
  }.property('themeSelectionInProgress', 'elementTypeSelectionInProgress', 'model.type'),

  onlyTopBarStyleIsAvailable: Ember.computed.equal('model.element_subtype', 'call'),
  notOnlyTopBarStyleIsAvailable: Ember.computed.not('onlyTopBarStyleIsAvailable'),

  elementTypeSelectionInProgress: false,
  userSelectedElementTypeExplicitly: false,
  seeingElementFirstTime: true,

  actions: {

    closeDropdown() {
      this.set('elementTypeSelectionInProgress', false);
    },

    changeStyle() {
      this.set('elementTypeSelectionInProgress', true);
      return false;
    },

    changeTheme() {
      const controller = this;
      let confirmModal = null;
      const modalOptions = {
        title: 'Are you sure you want to change the theme?',
        text: 'We will save the content and style of your current theme before the update',
        confirmBtnText: 'Yes, Change The Theme',
        cancelBtnText: 'No, Keep The Theme',
        showCloseIcon: true,
        confirm() {
          confirmModal.close();
          controller.get('bus').trigger('hellobar.core.rightPane.show', {
            componentName: 'theming/theme-tile-grid',
            componentOptions: {
              elementType: controller.get('model.type')
            }
          });
        }

      };
      confirmModal = new ConfirmModal(modalOptions);
      return confirmModal.open();
    }
  }

});
