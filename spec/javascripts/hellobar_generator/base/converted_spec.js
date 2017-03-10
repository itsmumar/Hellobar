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


  describe("HB.converted", function() {
    it("Sends data to the tracking server", function () {
      spyOn(HB, 's');

      HB.converted(siteElement);
      expect(HB.s).toHaveBeenCalled;
    });

    context("callbacks", function() {
      beforeEach(function() {
        spyOn(HB, 'trigger');
        HB.converted(siteElement);
      });

      it("triggers the conversion callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('conversion', jasmine.any(Object));
      });

      it("triggers the converted callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('converted', jasmine.any(Object));
      });
    });

  });
});
