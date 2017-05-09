//= require modules/base/base.metainfo

describe('Module base.metainfo', () => {
  let module;

  beforeEach(() => {
    hellobar.finalize();

    module = hellobar('base.metainfo', {
      dependencies: {},
      configurator: (configuration) => {
        configuration.version("9ca6c58b392a4cb879753e097667205a32e516ec");
        configuration.timestamp("2017-04-07 13:05:33 UTC");
      }
    });
  });

  describe('info()', () => {
    it('returns a string with version and timestamp', () => {
      expect(module.info()).toEqual('version 9ca6c58b392a4cb879753e097667205a32e516ec was generated at 2017-04-07 13:05:33 UTC');
    });
  });

  describe('version()', () => {
    it('returns version', () => {
      expect(module.version()).toEqual('9ca6c58b392a4cb879753e097667205a32e516ec');
    });
  });

  describe('timestamp()', () => {
    it('returns timestamp', () => {
      expect(module.timestamp()).toEqual('2017-04-07 13:05:33 UTC');
    });
  })
});
