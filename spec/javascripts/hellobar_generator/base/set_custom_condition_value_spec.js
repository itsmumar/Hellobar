//= require hellobar_script/hellobar.base
var context = describe;

describe("HB", function() {
  beforeEach(function() {
    HB.loadCookies();
    HB.siteElementsOnPage = [];
  });

  describe(".setCustomConditionValue", function() {
    it("delegates to setVisitorData", function () {
      spyOn(HB, 'setVisitorData');
      spyOn(HB, 'showSiteElements');
      HB.setCustomConditionValue("ABC", 123);
      expect(HB.setVisitorData).toHaveBeenCalledWith("ABC", 123);
    });

    context("there are no elements on the page", function () {
      it("calls HB.showSiteElements", function () {
        spyOn(HB, 'showSiteElements');
        HB.setCustomConditionValue("ABC", 123);
        expect(HB.showSiteElements).toHaveBeenCalled();
      });
    });

    context("there is at least one site element on the page", function () {
      it("calls HB.showSiteElements", function () {
        HB.siteElementsOnPage = ["not empty array"];
        spyOn(HB, 'showSiteElements');
        HB.setCustomConditionValue("ABC", 123);
        expect(HB.showSiteElements).not.toHaveBeenCalled();
      });
    });
  });
});
