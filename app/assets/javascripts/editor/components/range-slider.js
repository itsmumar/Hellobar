HelloBar.RangeSliderComponent = Ember.Component.extend({

  classNames: ['range-slider'],

  sliderEvents: Ember.A(['update']),

  min: 0,
  max: 100,
  start: 0,

  leftLabel: null,
  rightLabel: null,

  context: Ember.computed(function() { return this; }),

  // ----- Component lifecycle methods -----

  didInsertElement() {
    let startValue = this.start || this.min;
    let el = this.$('.js-slider')[0];
    noUiSlider.create(el, {
      start: [startValue],
      connect: [true, false],
      range: {
        min: this.min,
        max: this.max
      }
    });
    let slider = el.noUiSlider;
    this.set('slider', slider);
    this.sliderEvents.forEach(event => {
      if (!Ember.isEmpty(this.get(event))) {
        return slider.on(event, (values, handle) => {
          let value = this.get('slider').get();
          value = value ? parseInt(value).toString() : '0';
          this.updateHandleValue(value);
          return this.sendAction(event, value);
        }
        );
      }
    }
    );
    return this.updateLayout();
  },

  willDestroyElement() {
    if (this.slider) {
      this.sliderEvents.forEach(event => {
        return this.slider.off(event);
      }
      );
      return this.slider.destroy();
    }
  },


  // ----- DOM updating methods -----

  updateLayout() {
    let $slider = this.$('.js-slider');
    let $ll = this.$('.js-left-label');
    if ($ll.length > 0) {
      $slider.css('margin-left', $ll[0].offsetWidth + 15);
    }
    let $rl = this.$('.js-right-label');
    if ($rl.length > 0) {
      return $slider.css('margin-right', $rl[0].offsetWidth + 15);
    }
  },

  updateHandleValue(value) {
    return this.$('.noUi-handle').text(value);
  }
});


