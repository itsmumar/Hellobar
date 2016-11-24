import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  bus: Ember.inject.service(),
  inlineEditing: Ember.inject.service(),

  //-----------  Step Settings  -----------#

  step: 2,
  prevStep: 'settings',
  nextStep: 'design',

  themeSelectionInProgress: false,

  init() {
    this.get('bus').subscribe('hellobar.core.bar.themeChanged', params => {
        return this.set('model.theme_id', params.themeId);
      }
    );
    this.get('bus').subscribe('hellobar.core.rightPane.show', params => {
        if (params.componentName === 'theme-tile-grid') {
          return this.set('themeSelectionInProgress', true);
        }
      }
    );
    this.get('bus').subscribe('hellobar.core.rightPane.hide', params => {
        return this.set('themeSelectionInProgress', false);
      }
    );
  },

  currentTheme: (function () {
    let allThemes = availableThemes;
    let currentThemeId = this.get('model.theme_id');
    let currentTheme = _.find(allThemes, theme => currentThemeId === theme.id);
    return currentTheme;
  }).property('model.theme_id'),

  currentThemeName: (function () {
    let theme = this.get('currentTheme');
    if (theme) {
      return theme.name;
    } else {
      return '';
    }
  }).property('currentTheme'),

  shouldShowThemeInfo: (function () {
    return this.get('isModalType') && !this.get('themeSelectionInProgress');
  }).property('themeSelectionInProgress', 'isModalType'),

  //-----------  Sub-Step Selection  -----------#

  // Sets a property which tells the route to forward to a previously
  // selected child route (ie. sub-step)

  routeForwarding: false,

  setType: (function () {
    var applyRouteForwarding = () => {

      if (!this.get('model')) {
        setTimeout(applyRouteForwarding, 100);
        return;
      }

      switch (this.get('routeForwarding')) {
        case 'style.modal':
          this.set('model.type', 'Modal');
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
      if (trackEditorFlow) {
        return InternalTracking.track_current_person("Editor Flow", {
          step: "Style Settings",
          goal: this.get("model.element_subtype")
        });
      }
    };
    applyRouteForwarding();

  }).observes('routeForwarding'),

  trackStyleView: (function () {
    if (trackEditorFlow && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person("Editor Flow", {
        step: "Choose Style",
        goal: this.get("model.element_subtype")
      });
    }
  }).observes('model').on('init'),

  onElementTypeChanged: (function () {
    let elementType = this.get('model.type');
    if (elementType === 'Modal') {
      this.get('bus').trigger('hellobar.core.rightPane.show', {componentName: 'theme-tile-grid', componentOptions: {}});
    } else {
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    }
    this.get('inlineEditing').initializeInlineEditing(elementType);
  }).observes('model.type'),


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

  elementTypeListCssClasses: (function() {
    let classes = ['step-link-wrapper'];
    this.get('routeForwarding') && (classes.push('is-selected'));
    return classes.join(' ');
  }).property('routeForwarding'),

  //-------------------------------------------------------------

  isModalType: (function () {
    return this.get('model.type') === 'Modal';
  }).property('model.type'),

  actions: {

    changeStyle() {
      this.set('routeForwarding', false);
      this.transitionToRoute('style');
      return false;
    },

    changeTheme() {
      let confirmModal = null;
      let modalOptions = {
        title: 'Are you sure you want to change the theme?',
        text: 'We will save the content and style of your current theme before the update',
        confirmBtnText: 'Yes, Change The Theme',
        cancelBtnText: 'No, Keep The Theme',
        showCloseIcon: true,
        confirm() {
          confirmModal.close();
          this.get('bus').trigger('hellobar.core.rightPane.show', {
            componentName: 'theme-tile-grid',
            componentOptions: {}
          });
        }

      };
      confirmModal = new ConfirmModal(modalOptions);
      return confirmModal.open();
    }
  }
});

