import _ from 'lodash/lodash';
import Ember from 'ember';

const TYPE_PERCENT = '%';
const TYPE_PIXEL = 'px';
const TYPES = [TYPE_PERCENT, TYPE_PIXEL];

export default Ember.Component.extend({
  classNames: ['number-input'],

  type: TYPE_PIXEL,

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

  incrementPercent: function () {
    if (this.get('value') >= 100) {
      return;
    }

    this.incrementProperty('value');
  },

  incrementPixel: function () {
    this.incrementProperty('value');
  },

  decrementPercent: function () {
    if (this.get('value') <= 0) {
      return;
    }
    this.decrementProperty('value');
  },

  decrementPixel: function () {
    if (this.get('value') <= 0) {
      return;
    }
    this.decrementProperty('value');
  },

  doAction: function (action) {
    switch(this.get('type')) {
      case TYPE_PERCENT:
        this[`${ action }Percent`]();
        break;
      case TYPE_PIXEL:
        this[`${ action }Pixel`]();
        break;
    }
  },

  delayAction (action, delay = 200) {
    const timeout = setTimeout(() => {
      this.repeatAction(action);
    }, delay);

    this.set('timeout', timeout);
  },

  repeatAction (action, delay = 50) {
    const interval = setInterval(() => {
      this.doAction(action);
    }, delay);

    this.set('interval', interval);
  },

  actions: {
    increment () {
      this.doAction('increment');
      this.delayAction('increment');
    },

    decrement () {
      this.doAction('decrement');
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
