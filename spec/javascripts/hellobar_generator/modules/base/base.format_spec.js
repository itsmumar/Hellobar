//= require modules/core
//= require modules/base/base.format

describe('Module base.format', function () {
  var module;

  beforeEach(function () {
    module = hellobar('base.format', {
      dependencies: {}
    });
  });

  describe('.normalizeUrl', function() {
    it('converts string to lowercase', function () {
      var url = module.normalizeUrl('GOOgLe.COM');
      expect(url).toEqual('google.com')
    });

    it('handles non string', function () {
      var url = module.normalizeUrl(1);
      expect(url).toEqual('1');
    });

    describe('when pathOnly is false', function () {
      it('removes www', function () {
        var url = module.normalizeUrl('www.google.com', false);
        expect(url).toEqual('google.com');
      });

      it('removes hash parameters', function () {
        var url = module.normalizeUrl('http://www.google.com/#foo', false);
        expect(url).toEqual('google.com');
      });

      it('removes https', function () {
        var url = module.normalizeUrl('https://google.com', false);
        expect(url).toEqual('google.com');
      });

      describe('when query parameters', function () {
        it('alphabetically orders the query params', function () {
          var url = module.normalizeUrl('hellobar.com/?b=second&a=first', false);
          expect(url).toEqual('hellobar.com/?a=first&b=second');
        });

        it('adds slash before query if none exists', function () {
          var url = module.normalizeUrl('http://www.hellobar.com?anything=true', false);
          expect(url).toEqual('hellobar.com/?anything=true');
        });
      });
    });

    describe('when pathOnly is true', function () {
      it('does nothing with simple relative path', function () {
        var url = module.normalizeUrl('/about', true);
        expect(url).toEqual('/about');
      });

      it('does nothing with simple relative html path', function () {
        var url = module.normalizeUrl('/about.html', true);
        expect(url).toEqual('/about.html');
      });

      it('strips the protocol and site', function () {
        var url = module.normalizeUrl('http://www.google.com/about', true);
        expect(url).toEqual('/about');
      });

      it('reorders query params', function () {
        var url = module.normalizeUrl('http://hellobar.com/about?b=second&a=first', true);
        expect(url).toEqual('/about/?a=first&b=second');
      });

      it('returns / when url is index without slash', function () {
        var url = module.normalizeUrl('http://hellobar.com', true);
        expect(url).toEqual('/');
      });

      it('returns / when url is index with slash', function () {
        var url = module.normalizeUrl('http://hellobar.com/', true);
        expect(url).toEqual('/');
      });

      it('return /? when empty query with slash', function () {
        var url = module.normalizeUrl('http://hellobar.com/?', true);
        expect(url).toEqual('/?');
      });

      it('returns /? when empty query without slash', function () {
        var url = module.normalizeUrl('http://hellobar.com?', true);
        expect(url).toEqual('/?');
      });
    });
  });

  describe('.stringLiteral', function() {
    it('returns null string for empty arg', function() {
      expect(module.stringLiteral(undefined)).toEqual('null');
    });

    it('returns quoted string for non-empty arg', function() {
      expect(module.stringLiteral('test')).toEqual('\'test\'');
    });
  });

  describe('.asBool', function() {
    it('handles falsy values', function() {
      expect(module.asBool(undefined)).toEqual(false);
      expect(module.asBool(null)).toEqual(false);
      expect(module.asBool('false')).toEqual(false);
      expect(module.asBool('0')).toEqual(false);
      expect(module.asBool(0)).toEqual(false);
      expect(module.asBool(false)).toEqual(false);
    });

    it('handles truthy values', function() {
      expect(module.asBool({})).toEqual(true);
      expect(module.asBool([])).toEqual(true);
      expect(module.asBool('some-string')).toEqual(true);
      expect(module.asBool('true')).toEqual(true);
      expect(module.asBool('1')).toEqual(true);
      expect(module.asBool(5)).toEqual(true);
      expect(module.asBool(true)).toEqual(true);
    });
  });

});
