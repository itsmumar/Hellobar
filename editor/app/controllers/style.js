import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  bus: Ember.inject.service(),
  inlineEditing: Ember.inject.service(),

  applicationController: Ember.inject.controller('application'),

  //-----------  Step Settings  -----------#

  step: 2,
  prevStep: 'settings',
  nextStep: 'design',

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

  canUseCustomHtml:  function () {
    return this.get('model.site.capabilities.custom_html') === true;
  }.property('model.site.capabilities.custom_html'),

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

  shouldShowCustomThemeInfo: function() {
    return this._shouldShowThemeInfoForElementType('Custom');
  }.property('themeSelectionInProgress', 'elementTypeSelectionInProgress', 'model.type'),

  onlyTopBarStyleIsAvailable: Ember.computed.equal('model.element_subtype', 'call'),
  notOnlyTopBarStyleIsAvailable: Ember.computed.not('onlyTopBarStyleIsAvailable'),

  elementTypeSelectionInProgress: false,
  userSelectedElementTypeExplicitly: false,
  seeingElementFirstTime: true,

  applyRoute (routeName) {
    const routeByElementType = (elementType, elementId) => {
      switch (elementType) {
        case 'Custom':
          return 'style.custom';
        case 'Takeover':
          return 'style.takeover';
        case 'Slider':
          return 'style.slider';
        case 'Modal':
          return 'style.modal';
        case 'Bar':
          return (!this.userSelectedElementTypeExplicitly && !elementId && this.get('notOnlyTopBarStyleIsAvailable')) ? null : 'style.bar';
        default:
          return null;
      }
    };
    if (_.endsWith(routeName, '.index')) {
      // We hit the index route. Redirect if required
      const newRouteName = routeByElementType(this.get('model.type'), this.get('model.id'));
      if (newRouteName) {
        this.transitionToRoute(newRouteName);
      } else {
        this.set('elementTypeSelectionInProgress', true);
      }
    } else {
      // We hit route for given element type. Update model accordingly
      switch (routeName) {
        case 'style.modal':
          this.set('model.type', 'Modal');
          break;
        case 'style.custom':
          this.set('model.type', 'Custom');
          break;
        case 'style.slider':
          this.set('model.type', 'Slider');
          break;
        case 'style.takeover':
          this.set('model.type', 'Takeover');
          break;
        default:
          this.set('model.type', 'Bar');
      }
      this.set('elementTypeSelectionInProgress', false);
      this.set('userSelectedElementTypeExplicitly', true);
      if (trackEditorFlow) {
        return InternalTracking.track_current_person('Editor Flow', {
          step: 'Style Settings',
          goal: this.get('model.element_subtype')
        });
      }
    }
  },

  trackStyleView: (function () {
    if (trackEditorFlow && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person('Editor Flow', {
        step: 'Choose Style',
        goal: this.get('model.element_subtype')
      });
    }
  }).observes('model').on('init'),

  onElementTypeChanged: (function () {
    let elementType = this.get('model.type');
    if (elementType == 'Custom' || this.get('isEditing')) {
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    } else {
      this.get('bus').trigger('hellobar.core.rightPane.show', {
        componentName: 'theming/theme-tile-grid',
        componentOptions: { elementType }
      });
    }
    this.get('inlineEditing').initializeInlineEditing(elementType);
  }).observes('model.type'),

  onHtmlChanged: (function () {
    this.get('applicationController').renderPreview()
  }).observes('model.settings.url'),


  //--- Theme change handling moved from design-controller ---
  themeChanged: Ember.observer('currentThemeName', function () {
      return Ember.run.next(this, function () {
          return this.setProperties({
            'model.image_placement': this.getImagePlacement()
          });
        }
        //'model.use_default_image' : false
      );
    }
  ),

  getImagePlacement() {
    let positionIsSelectable = this.get('currentTheme.image.position_selectable');
    let imageIsbackground = (this.get('model.image_placement') === 'background');
    let positionIsEmpty = Ember.isEmpty(this.get('model.image_placement'));
    if (!positionIsSelectable) {
      return this.get('currentTheme.image.position_default');
    } else if (imageIsbackground || positionIsEmpty) {
      return this.get('currentTheme.image.position_default');
    } else {
      return this.get('model.image_placement');
    }
  },

  elementTypeListCssClasses: (function () {
    let classes = ['step-link-wrapper'];
    !this.get('elementTypeSelectionInProgress') && (classes.push('is-selected'));
    return classes.join(' ');
  }).property('elementTypeSelectionInProgress'),

  //-------------------------------------------------------------

  isModalType: (function () {
    return this.get('model.type') === 'Modal';
  }).property('model.type'),

  actions: {

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
