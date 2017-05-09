import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  //-----------  Step Settings  -----------#

  step: 2,
  prevStep: 'goals',
  nextStep: 'design',

  applyRoute (routeName) {
    const routeByElementType = (elementType, elementId) => {
      switch (elementType) {
        case 'Alert':
          return 'style.alert';
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
        case 'style.alert':
          this.set('model.type', 'Alert');
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
      if (this.get('applicationSettings.track_editor_flow')) {
        return InternalTracking.track_current_person('Editor Flow', {
          step: 'Style Settings',
          goal: this.get('model.element_subtype')
        });
      }
    }
  },

  // TODO -> internal tracking service
  trackStyleView: (function () {
    if (this.get('applicationSettings.track_editor_flow') && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person('Editor Flow', {
        step: 'Choose Style',
        goal: this.get('model.element_subtype')
      });
    }
  }).observes('model', 'applicationSettings').on('init'),

  // TODO -> service...
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

  // TODO -> theming service or design base component
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

  // TODO -> design component or new "image support" service
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
  }).property('elementTypeSelectionInProgress')

});
