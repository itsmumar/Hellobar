import Ember from 'ember';

const allStyles = ['Bar', 'Modal', 'Slider', 'Takeover', 'Custom', 'Alert'];

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

  isCustom: Ember.computed.equal('style', 'Custom'),
  currentTheme: Ember.computed.alias('theming.currentTheme'),
  currentThemeName: Ember.computed.alias('theming.currentThemeName'),
  isEditing: Ember.computed.bool('model.id'),

  init() {
    this._super();
    this.set('selectionInProgress', !this.get('style'));
    this.set('themeSelectionInProgress', false);
    allStyles.forEach((style) => {
      this[`shouldShow${style}ThemeInfo`] = Ember.computed('themeSelectionInProgress',
        'selectionInProgress',
        'style',
        function () {
          return this.get(`canUse${style}Style`) !== false &&
            this.get('style') === style && !this.get('themeSelectionInProgress') && !this.get('selectionInProgress');
        });
      this[`shouldShow${style}`] = Ember.computed('selectionInProgress', 'style', function () {
        return this.get(`canUse${style}Style`) !== false &&
          (this.get('style') === style || this.get('selectionInProgress'));
      });

    });

    this.get('bus').subscribe('hellobar.core.rightPane.show', (params) => {
        if (params.componentName === 'preview/containers/theming/theme-tile-grid') {
          this.set('themeSelectionInProgress', true);
        }
      }
    );
    this.get('bus').subscribe('hellobar.core.rightPane.hide', (params) => {
        this.set('themeSelectionInProgress', false);
      }
    );
  },

  canUseCustomStyle: Ember.computed.alias('model.site.capabilities.custom_html'),
  canUseAlertStyle: Ember.computed.alias('model.site.capabilities.alert_bars'),

  onlyTopBarStyleIsAvailable: Ember.computed.equal('model.element_subtype', 'call'),
  notOnlyTopBarStyleIsAvailable: Ember.computed.not('onlyTopBarStyleIsAvailable'),

  elementTypeSelectionInProgress: false,
  userSelectedElementTypeExplicitly: false,

  manageRightPaneOnElementTypeChanged: function () {
    let elementType = this.get('model.type');
    if (elementType == 'Custom' || this.get('isEditing')) {
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
      if (!this.get('selectionInProgress')) {
        return;
      }
      this.set('style', style);
      this.set('selectionInProgress', false);
    },

    initiateSelection() {
      this.set('selectionInProgress', true);
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
          that.get('bus').trigger('hellobar.core.rightPane.show', {
            componentName: 'preview/containers/theming/theme-tile-grid',
            componentOptions: {
              elementType: that.get('model.type')
            }
          });
        }

      };
      confirmModal = new ConfirmModal(modalOptions);
      return confirmModal.open();
    }
  }

});
