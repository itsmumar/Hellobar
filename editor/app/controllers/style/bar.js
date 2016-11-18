import Ember from 'ember';

import AfterConvertOptions from '../mixins/after-convert-options-mixin';
import HasPlacement from '../mixins/has-placement-mixin';
import HasTriggerOptions from '../mixins/has-trigger-options-mixin';

export default Ember.Controller.extend(HasPlacement, HasTriggerOptions, AfterConvertOptions, {

    placementOptions: [
      {value: 'bar-top', label: 'Top'},
      {value: 'bar-bottom', label: 'Bottom'}
    ],

    canWiggle: (function () {
      return this.get("model.element_subtype") === "traffic" || this.get("model.element_subtype") === "email";
    }).property("model.element_subtype"),

    pushesText: (function () {
      if (this.get('selectedPlacement') === 'bar-top') {
        return 'Pushes page down';
      } else {
        return 'Pushes page up';
      }
    }).property('selectedPlacement'),

    adoptedBarSize: (function () {
      let size = this.get('model.size');
      switch (size) {
        case 'large':
          return 50;
        case 'regular':
          return 30;
        default:
          return parseInt(size);
      }
    }).property('model.size'),

    actions: {
      barSizeUpdated(value) {
        return this.set('model.size', value);
      }
    }
  }
);
