import Ember from 'ember';

const TYPE_PERCENT = '%';
const TYPE_PIXEL = 'px';
const TYPE_SECOND = 's';
const TYPES = [TYPE_PERCENT, TYPE_PIXEL, TYPE_SECOND];
const CTA_MIN_MAX_HEIGHT = {'Bar': [20, 100], 'Alert': [20,50], 'Slider': [20,50], 'Modal': [20,110], 'Takeover': [20,110]};

export default Ember.Component.extend({
  classNames: ['number-input'],

  type: TYPE_PIXEL,
  max: 100,
  min: 0,

  label: function () {
    const type = this.get('type');

    if (TYPES.indexOf(type) === -1) {
      throw new Error(`wrong number input type: ${ type }`);
    }

    return type;
  }.property('value'),

  formattedValue: function () {
    return `${ this.get('value') }${ this.get('label') }`;
  }.property('value'),

  increment: function () {

    if (this.get('value') >= this.get('max')) {
      return;
    }
    const elementType = this.parentView.parentView.attrs.model.value.type;
    console.log(elementType);
    const elementStyleName = this.get('name');
    if(elementType.length > 0 && typeof elementStyleName !== "undefined") {
      var maxSize = CTA_MIN_MAX_HEIGHT[elementType][1]
      if(elementType == 'Bar') {
        maxSize = this.get('bar_size') - 10;
      };
      if(this.get('value') > maxSize || this.get('value') < CTA_MIN_MAX_HEIGHT[elementType][0]) {
        return;
      }
    }

    this.incrementProperty('value');
  },

  decrement: function () {
    if (this.get('value') <= this.get('min')) {
      return;
    }
    this.decrementProperty('value');
  },

  delayAction (action, delay = 200) {
    const timeout = setTimeout(() => {
      this.repeatAction(action);
    }, delay);

    this.set('timeout', timeout);
  },

  repeatAction (action, delay = 50) {
    const interval = setInterval(() => {
      this[action]();
    }, delay);

    this.set('interval', interval);
  },

  actions: {
    increment () {
      this.increment();
      this.delayAction('increment');
    },

    decrement () {
      this.decrement();
      this.delayAction('decrement');
    },

    resetTimers () {
      const interval = this.get('interval');
      const timeout = this.get('timeout');

      if (interval) {
        clearInterval(interval);
        this.set('interval', null);
      }

      if (timeout) {
        clearTimeout(timeout);
        this.set('timeout', null);
      }
    }
  }
});
