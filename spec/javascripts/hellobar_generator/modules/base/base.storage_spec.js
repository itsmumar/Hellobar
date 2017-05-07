//= require modules/base/base.storage

describe('Module base.storage', function () {

  var module;

  beforeEach(function () {
    module = hellobar('base.storage');
  });

  it('returns undefined for non-existent key', function () {
    expect(module.getValue('non-existent')).toBeUndefined();
  });

  it('sets and gets the values', function () {
    module.setValue('string-value', 'HelloBar');
    expect(module.getValue('string-value')).toEqual('HelloBar');
  });

  it('sets and gets complex objects', function () {
    var object = {name: 'HelloBar'};
    module.setValue('object-value', object);
    expect(module.getValue('object-value')).toEqual(object);
  });

  it('supports expiration with explicitly specified Date', function () {
    var pastDate = new Date('2016-01-01');
    module.setValue('expired-value', 'I am expired', pastDate);
    expect(module.getValue('expired-value')).toBeUndefined();
  });

  it('supports expiration with day count specified', function () {
    module.setValue('expired-value', 'I am expired', -1);
    expect(module.getValue('expired-value')).toBeUndefined();
  });
});
