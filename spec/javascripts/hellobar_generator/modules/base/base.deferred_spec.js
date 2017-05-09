//= require modules/base/base.deferred

describe('Module base.deferred', function () {
  var module;

  beforeEach(function () {
    hellobar.finalize();
    module = hellobar('base.deferred', {
      dependencies: {}
    });
  });

  it('provides a function that returns a deferred object', function () {
    expect(typeof module).toEqual('function');
    var deferred = module();
    expect(typeof deferred).toEqual('object');
  });

  it('supports asynchronous resolving and calls callback', function (done) {
    function longRunningOperation() {
      var deferred = module();
      setTimeout(function () {
        deferred.resolve('correct-result');
      }, 50);
      return deferred.promise();
    }

    longRunningOperation().then(function (result) {
      expect(result).toEqual('correct-result');
      done();
    });
  });

  it('supports chaining of callbacks and they called in correct order', function (done) {
    var callOrder = [1, 2, 3];
    module().resolve().promise().then(function () {
      var number = callOrder.shift();
      expect(number).toEqual(1);
    }).then(function () {
      var number = callOrder.shift();
      expect(number).toEqual(2);
    }).then(function () {
      var number = callOrder.shift();
      expect(number).toEqual(3);
      expect(callOrder.length).toEqual(0);
      done();
    });
  });

  it('supports multi-step result passing', function (done) {
    module().resolve(1).promise().then(function (n) {
      return n + 1;
    }).then(function (n) {
      return n + 2
    }).then(function (n) {
      expect(n).toEqual(4);
      done();
    });
  });

  it('supports promise joining', function (done) {
    var promise0 = module().resolve().promise().then(function () {
      return 0;
    });
    var promise1 = module().resolve().promise().then(function () {
      return 1;
    });
    var promise2 = module().resolve().promise().then(function () {
      return 2;
    });
    module.all([promise0, promise1, promise2]).then(function (results) {
      expect(results[0]).toEqual(0);
      expect(results[1]).toEqual(1);
      expect(results[2]).toEqual(2);
      done();
    });
  });

  it('provides shorthand syntax for deferred constant values', function (done) {
    module.constant('constant-value').then(function (value) {
      expect(value).toEqual('constant-value');
      done();
    });
  });

});
