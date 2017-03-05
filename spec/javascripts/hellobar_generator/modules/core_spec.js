//= require modules/core

describe('HelloBar Core', function () {

  it('supports module definition', function () {
    hellobar.defineModule('useless', [], function () {
      return {
        uselessMethod: function () {
        }
      }
    });
    expect(hellobar('useless')).toBeDefined();
    expect(hellobar('useless').uselessMethod).toBeDefined();
    expect(hellobar('useless').usefulMethod).toBeUndefined();
  });

  it('performs dependency management', function () {
    hellobar.defineModule('add', [], function () {
      return function (x, y) {
        return x + y;
      };
    });
    hellobar.defineModule('subtract', [], function () {
      return function (x, y) {
        return x - y;
      };
    });
    hellobar.defineModule('calculate', ['add', 'subtract'], function (add, subtract) {
      return function (initial, valueToAdd, valueToSubtract) {
        return subtract(add(initial, valueToAdd), valueToSubtract);
      };
    });
    expect(hellobar('calculate')(20, 10, 1)).toEqual(29);
  });
});
