import Ember from 'ember';

console.log('bus service definition');

export default Ember.Service.extend({

  init() {
    // TODO remove this
    console.log('bus service initialized.');
  },

  _events: {},
  subscribe(eventName, callback) {
    if (!this._events[eventName]) {
      this._events[eventName] = [];
    }
    return this._events[eventName].push(callback);
  },

  unsubscribe(eventName, callback) {
    return this._events[eventName] = _.without(this._events[eventName], callback);
  },

  trigger(eventName, params) {
    let callbacks = this._events[eventName];
    if (callbacks) {
      return callbacks.forEach(callback =>
          setTimeout(() => callback(params)
            , 0)
      );
    }
  }
});

