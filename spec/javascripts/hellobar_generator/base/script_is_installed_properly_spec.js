//= require hellobar_script/hellobar.base
var context = describe;

describe("HB", function() {
  describe(".scriptIsInstalledProperly()", function() {
    it("returns true when the user is on the the site", function() {
      window.HB_SITE_URL = "http://www.correct.com";
      var loc = { hostname: "www.correct.com" };
      spyOn(HB, 'getLocation').and.returnValue(loc);

      expect(HB.scriptIsInstalledProperly()).toEqual(true);
    });

    it("returns false when the user is on a completely different site", function() {
      window.HB_SITE_URL = "http://www.correct.com";
      var loc = { hostname: "http://www.different.com" };
      spyOn(HB, 'getLocation').and.returnValue(loc);

      expect(HB.scriptIsInstalledProperly()).toEqual(false);
    });

    it("returns true for any ip addresses", function() {
      window.HB_SITE_URL = "http://www.correct.com";
      var loc = { hostname: "192.168.1.1" };
      spyOn(HB, 'getLocation').and.returnValue(loc);

      expect(HB.scriptIsInstalledProperly()).toEqual(true);
    });

    it("returns true for localhost", function() {
      window.HB_SITE_URL = "http://www.correct.com";
      var loc = { hostname: "localhost" };
      spyOn(HB, 'getLocation').and.returnValue(loc);

      expect(HB.scriptIsInstalledProperly()).toEqual(true);
    });

    it("returns true regardless of protocol", function() {
      window.HB_SITE_URL = "http://www.correct.com";
      var loc = { hostname: "https://www.correct.com" };
      spyOn(HB, 'getLocation').and.returnValue(loc);

      expect(HB.scriptIsInstalledProperly()).toEqual(true);
    });
  });
});
