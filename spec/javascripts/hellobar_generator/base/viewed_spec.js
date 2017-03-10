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
      subtype: "traffic"
    }

    siteElement = new HB.SiteElement(siteElementData);
    HB.loadCookies();
  });


  describe("HB.viewed", function() {
    it("Sends data to the tracking server", function () {
      spyOn(HB, 's');

      HB.viewed(siteElement);
      expect(HB.s).toHaveBeenCalled;
    });

    context("callbacks", function() {
      beforeEach(function() {
        spyOn(HB, 'trigger');
        HB.viewed(siteElement);
      });

      it("triggers the siteElementShown callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('siteElementShown', jasmine.any(Object));
      });

      it("triggers the shown callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('shown', jasmine.any(Object));
      });
    });

  });
});
