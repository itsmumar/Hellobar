/* globals noUiSlider */

import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['range-slider'],

  sliderEvents: Ember.A(['update']),

  min: 0,
  max: 100,
  start: 0,
  default: 0,

  leftLabel: null,
  rightLabel: null,

  context: Ember.computed(function () {
    return this;
  }),

  // ----- Component lifecycle methods -----

  didInsertElement() {
    const startValue = this.start || this.default;
    const el = this.$('.js-slider')[0];
    noUiSlider.create(el, {
      start: [startValue],
      connect: [true, false],
      range: {
        min: this.min,
        max: this.max
      }
    });
    const slider = el.noUiSlider;
    this.set('slider', slider);
    this.sliderEvents.forEach(event => {
        if (!Ember.isEmpty(this.get(event))) {
          return slider.on(event, (/* values, handle*/) => {
              let value = this.get('slider').get();
              value = value ? parseInt(value).toString() : '0';
              this.updateHandleValue(value);
              return this.sendAction(event, value);
            }
          );
        }
      }
    );
    this.updateLayout();
  },

  willDestroyElement() {
    if (this.slider) {
      this.sliderEvents.forEach(event => {
          return this.slider.off(event);
        }
      );
      this.slider.destroy();
    }
  },


  // ----- DOM updating methods -----

  updateLayout() {
    const $slider = this.$('.js-slider');
    const offsetWidth = (el) => {
      const clone = el.clone().appendTo('body');
      const offsetWidth = clone.get(0).offsetWidth;
      clone.remove();
      return offsetWidth;
    };

    const $ll = this.$('.js-left-label');
    if ($ll.length > 0) {
      $slider.css('margin-left', offsetWidth($ll) + 15);
    }
    const $rl = this.$('.js-right-label');
    if ($rl.length > 0) {
      $slider.css('margin-right', offsetWidth($rl) + 15);
    }
  },

  updateHandleValue(value) {
    this.$('.noUi-handle').text(value);
  }
});
