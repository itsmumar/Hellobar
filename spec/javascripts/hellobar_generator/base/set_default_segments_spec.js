//= require hellobar_script/hellobar.base
var context = describe;

describe("HB", function() {
  var element;
  var HOUR = 60 * 60 * 1000;

  beforeEach(function() {
    HB.loadCookies();
  });

  describe(".setDefaultSegments", function() {
    it("sets the number of number of sessions to 0 on the first visit", function () {
      HB.setDefaultSegments();
      expect(HB.getVisitorData("ns")).toEqual(0);
    });

    context("last visit was over an hour ago", function () {
      beforeEach(function() {
        var d = new Date(); // Last visit was 1.5 hours ago
        d.setHours(d.getHours() - 1);
        d.setMinutes(d.getMinutes() - 30);
        HB.setVisitorData('lv', (d.getTime())/1000);
      });

      it("increases the number of sessions", function () {
        HB.setVisitorData('ns', 1)
        HB.setDefaultSegments();
        expect(HB.getVisitorData("ns")).toEqual(2);
      });
    });

    context("last visit was less than an hour ago", function () {
      beforeEach(function() {
        var d = new Date(); // Last visit was half an hour ago
        d.setMinutes(d.getMinutes() - 30);
        HB.setVisitorData('lv', (d.getTime())/1000);
      });

      it("does not increase the number of sessions", function () {
        HB.setVisitorData('ns', 1)
        HB.setDefaultSegments();
        expect(HB.getVisitorData("ns")).toEqual(1);
      });
    });

    context("setting the page path", function() {
      it("sets the path properly", function() {
        HB.setDefaultSegments();

        expect(HB.getVisitorData("pup")).toEqual(location.pathname);
      });
    });
  });
});
