//= require hellobar_script/hellobar.base

describe("HB", function() {
  var ipad = "Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B137 Safari/601.1";
  var iphone = "Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1";
  var androidTablet = "Mozilla/5.0 (Linux; Android 4.3; Nexus 7 Build/JSS15Q) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Safari/537.36"
  var android = "Mozilla/5.0 (Linux; Android 4.2.2; GT-I9505 Build/JDQ39) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.76 Mobile Safari/537.36"
  var chrome = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.103 Safari/537.36"


  describe(".device", function() {
    it("detects ipad", function () {
      spyOn(HB, "getUserAgent").and.returnValue(ipad);
      expect(HB.device()).toEqual("tablet");
    });

    it("detects android tablet", function () {
      spyOn(HB, "getUserAgent").and.returnValue(androidTablet);
      expect(HB.device()).toEqual("tablet");
    });

    it("detects android phone", function () {
      spyOn(HB, "getUserAgent").and.returnValue(android);
      expect(HB.device()).toEqual("mobile");
    });

    it("detects iphone phone", function () {
      spyOn(HB, "getUserAgent").and.returnValue(iphone);
      expect(HB.device()).toEqual("mobile");
    });

    it("detects desktop browser", function () {
      spyOn(HB, "getUserAgent").and.returnValue(chrome);
      expect(HB.device()).toEqual("computer");
    });
  });
});
