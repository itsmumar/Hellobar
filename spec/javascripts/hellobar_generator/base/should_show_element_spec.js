//= require hellobar_script/hellobar.base
//= require site_elements/site_element
var context = describe;

describe("HB", function() {
  var siteElement;

  beforeEach(function() {
    var siteElementData = {
      id: 123456,
      settings: {
        url: "",
        cookie_settings: {
          duration: 0,
          success_duration: 0
        }
      },
      template_name: "bar_traffic",
      type: "Modal",
      subtype: "traffic",
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
          siteElement.settings.cookie_settings = {
                                                   duration: 0,
                                                   success_duration: 0
                                                 };
          expect(HB.shouldShowElement(siteElement)).toEqual(true);
        });
      });

      context("element was not updated since it was last viewed", function() {
        beforeEach(function () {
          HB.setSiteElementData(siteElement.id, "lv", Date.now() / 1000);
          siteElement.updated_at = Date.now() - 1000000;
        });
      });
    });

    context("previous element has been dismissed", function() {
      beforeEach(function() {
        var otherElementData = {
          id: 654321,
          settings: {
            url: "",
            cookie_settings: {
              duration: 0,
              success_duration: 0
            }
          },
          template_name: "bar_traffic",
          type: "Modal",
          subtype: "traffic"
        }

        otherElement = new HB.SiteElement(otherElementData);
        HB.loadCookies();
      });

      context("when there is another element to be rendered", function() {
        it("returns true for the element that was not dismissed", function() {
          spyOn(HB, 'getSiteElementData').and.returnValue(100);
          HB.sc("HBDismissed-" + siteElement.id, true, new Date((new Date().getTime() + 1000 * 60 * 15)), "path=/");

          expect(HB.didDismissHB(otherElement)).toEqual(false);
        });
      });

      context("element was updated since it was last viewed", function() {
        it("returns true", function () {
          spyOn(HB, 'getSiteElementData').and.returnValue(100);
          siteElement.updated_at = Date.now();
          siteElement.settings.cookie_settings = {
                                                  duration: 0,
                                                  success_duration: 0
                                                };
          expect(HB.shouldShowElement(siteElement)).toEqual(true);
        });
      });

      context("element was not updated since it was last viewed", function() {
        beforeEach(function () {
          HB.setSiteElementData(siteElement.id, "lv", Date.now() / 1000);
          siteElement.updated_at = Date.now() - 1000000;
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
          siteElement.settings.cookie_settings = {
                                                   duration: 0,
                                                   success_duration: 0
                                                 };
          expect(HB.shouldShowElement(siteElement)).toEqual(true);
        });
      });

      context("element was not updated since it was last viewed", function() {
        beforeEach(function () {
          HB.setSiteElementData(siteElement.id, "lv", Date.now() / 1000);
          siteElement.updated_at = Date.now() - 1000000;
        });
      });
    });
  });
});
