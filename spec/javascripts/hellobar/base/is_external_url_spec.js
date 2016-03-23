//= require hellobar.base

describe("HB", function() {
  describe("isExternalURL", function() {
    it("detects external url", function () {
      spyOn(HB, "currentURL").and.returnValue("http://hellobar.com/path/to/asset")
      expect(HB.isExternalURL("http://nothellobar.com/path/to/other/asset")).toEqual(true)
    });

    it("detects internal url", function () {
      spyOn(HB, "currentURL").and.returnValue("http://hellobar.com/path/to/asset")
      expect(HB.isExternalURL("http://hellobar.com/path/to/other/asset")).toEqual(false)
    });
  });
});
