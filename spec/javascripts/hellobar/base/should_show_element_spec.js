//= require hellobar.base
//= require site_elements/site_element
var context = describe;

describe("HB", function() {
  var siteElement;

  beforeEach(function() {
    var siteElementData = {
      id: 123456,
      settings: { url: "" },
      template_name: "bar_traffic",
      type: "Modal",
      subtype: "traffic",
      show_after_convert: false
    }

    siteElement = new HB.SiteElement(siteElementData);
    HB.loadCookies();
  });


  describe("HB.shouldShowElement", function() {
    context("element has not yet been viewed", function() {
      beforeEach(function() {
        spyOn(HB, 'didDismissThisHB').and.returnValue(false);
      });

      it("returns true", function () {
        expect(HB.shouldShowElement(siteElement)).toEqual(true);
      });

      it("returns false if it's click to call and device is not mobile", function () {
        siteElement.subtype = "call";
        spyOn(HB, 'getVisitorData').and.returnValue("desktop");
        expect(HB.shouldShowElement(siteElement)).toEqual(false);
      });
    });

    context("element has been converted", function() {
      beforeEach(function() {
        spyOn(HB, 'didConvert').and.returnValue(true);
      });

      context("element was updated since it was last viewed", function() {
        it("returns true", function () {
          spyOn(HB, 'getSiteElementData').and.returnValue(100);
          siteElement.updated_at = Date.now();
          siteElement.show_after_convert = false;
          expect(HB.shouldShowElement(siteElement)).toEqual(true);
        });
      });

      context("element was not updated since it was last viewed", function() {
        beforeEach(function () {
          HB.setSiteElementData(siteElement.id, "lv", Date.now() / 1000);
          siteElement.updated_at = Date.now() - 1000000;
        });

        context("show_after_convert is false", function() {
          it("returns false", function () {
            siteElement.show_after_convert = false;
            expect(HB.shouldShowElement(siteElement)).toEqual(false);
          });
        });
      });
    });

    context("previous element has been dismissed", function() {
      beforeEach(function() {
        spyOn(HB, 'didDismissHB').and.returnValue(true);
      });

      context("element was updated since it was last viewed", function() {
        it("returns true", function () {
          spyOn(HB, 'getSiteElementData').and.returnValue(100);
          siteElement.updated_at = Date.now();
          siteElement.show_after_convert = false;
          expect(HB.shouldShowElement(siteElement)).toEqual(true);
        });
      });

      context("element was not updated since it was last viewed", function() {
        beforeEach(function () {
          HB.setSiteElementData(siteElement.id, "lv", Date.now() / 1000);
          siteElement.updated_at = Date.now() - 1000000;
        });

        context("show_after_convert is false", function() {
          it("returns false", function () {
            siteElement.show_after_convert = false;
            expect(HB.shouldShowElement(siteElement)).toEqual(false);
          });
        });
      });
    });

    context("element has been viewed", function() {
      beforeEach(function() {
        spyOn(HB, 'didDismissThisHB').and.returnValue(true);
      });

      context("element was updated since it was last viewed", function() {
        it("returns true", function () {
          spyOn(HB, 'getSiteElementData').and.returnValue(100);
          siteElement.updated_at = Date.now();
          siteElement.show_after_convert = false;
          expect(HB.shouldShowElement(siteElement)).toEqual(true);
        });
      });

      context("element was not updated since it was last viewed", function() {
        beforeEach(function () {
          HB.setSiteElementData(siteElement.id, "lv", Date.now() / 1000);
          siteElement.updated_at = Date.now() - 1000000;
        });

        context("show_after_convert is false", function() {
          it("returns false", function () {
            siteElement.show_after_convert = false;
            expect(HB.shouldShowElement(siteElement)).toEqual(false);
          });
        });
      });
    });
  });
});