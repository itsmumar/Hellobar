import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  _events: {},

  subscribe(eventName, callback) {
    if (!this._events[eventName]) {
      this._events[eventName] = [];
    }
    this._events[eventName].push(callback);
  },

  unsubscribe(eventName, callback) {
    this._events[eventName] = _.without(this._events[eventName], callback);
  },

  trigger(eventName, params) {
    const callbacks = this._events[eventName];
    _.each(callbacks, callback => {
      setTimeout(() => callback(params), 0)
    });
  }
});

