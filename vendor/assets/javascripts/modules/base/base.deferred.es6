hellobar.defineModule('base.deferred', [], function () {

  class Promise {
    constructor() {
      this._resolved = false;
      this._result = undefined;
      this._callbacks = [];
    }

    then(callback) {
      this._callbacks.push(callback);
      this._resolved && this._runCallbacks();
    }

    _runCallbacks() {
      var runCallback = (index, arg) => {
        if (index >= this._callbacks.length) {
          this._result = arg;
          this._callbacks = [];
          return;
        }
        const callback = this._callbacks[index];
        if (callback instanceof Promise) {
          callback.then((promiseResult) => {
            runCallback(index+1, promiseResult);
          });
        } else {
          const syncResult = callback(arg);
          runCallback(index+1, syncResult);
        }
      };
      this._callbacks.length > 0 && runCallback(0, this._result);
    }

    resolve(result) {
      if (!this._resolved) {
        this._resolved = true;
        this._runCallbacks();
      }
    }
  }

  function deferred() {
    const promise = new Promise();
    return {
      promise: () => promise,
      resolve(result) {
        promise.resolve(result);
        return this;
      }
    };
  }

  deferred.all = (promises) => {
    const allDeferred = deferred();
    let resolvedCount = 0;
    let results = [];
    const resolve = () => allDeferred.resolve(results);
    promises.forEach((promise, index) => promise.then((result) => {
      resolvedCount++;
      results[index] = result;
      (resolvedCount >= promises.length) && resolve();
    }));
    return allDeferred.promise();
  };

  deferred.constant = (value) => deferred().resolve(value).promise();

  deferred.Promise = Promise;

  return deferred;

});
