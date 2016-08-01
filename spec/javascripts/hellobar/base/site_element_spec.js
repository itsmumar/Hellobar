//= require hellobar.base
//= require site_elements/site_element
var context = describe;

describe("siteElement", function() {
  describe("siteElement.checkForDisplaySettings", function() {
    beforeEach(function() {
      iframe_window = {className: "my-cool-class"};
      iframe_window.style = jasmine.createSpy('style');
      siteElement = new HB.SiteElement({w: iframe_window, view_condition: ""});
      spyOn(HB, "viewed")
    });

    it("records a view", function () {
      siteElement.checkForDisplaySetting();
      expect(HB.viewed).toHaveBeenCalled();
    });

    it("does not record a view when don't record view is set", function () {
      siteElement.dontRecordView = true;
      siteElement.checkForDisplaySetting();
      expect(HB.viewed).not.toHaveBeenCalled();
    });
  });

  describe("siteElement.onClosed", function() {
    context("callbacks", function() {
      beforeEach(function() {
        spyOn(HB, 'trigger');
        siteElement.onClosed();
      });

      it("triggers the elementDismissed callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('elementDismissed');
      });

      it("triggers the converted callback", function() {
        expect(HB.trigger).toHaveBeenCalledWith('closed', siteElement);
      });
    });

  });
});
