//= require modules/base/base.serialization

describe('Module base.serialization', function() {

  var module;

  beforeEach(function() {
    module = hellobar('base.serialization');
  });

  it('serializes an object', function() {
    expect(module.serialize({one: 'door', two: 'window'})).toEqual('one:door|two:window');
  });

  it('deserializes a string', function() {
    expect(module.deserialize('one:door|two:window')).toEqual({one: 'door', two: 'window'});
  });

});
