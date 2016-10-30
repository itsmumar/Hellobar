// TODO this is a temporary solution until refactoring is done
// (we need to upgrade Ember version in order to use services and bus pattern)
HelloBar.bus = {
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
};
