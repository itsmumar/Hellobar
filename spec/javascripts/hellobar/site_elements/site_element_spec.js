//= require site_elements/site_element
var context = describe;

describe("SiteElement", function() {

  describe("#imagePlacementClass", function() {
    siteElement = null;
    beforeEach(function() {
      siteElement = new HB.SiteElement({});
    });

    context("when image_url is not present", function() {
      it("returns an empty string", function() {
        expect(siteElement.imagePlacementClass()).toEqual("");
      });
    });

    context("when image_url is present", function() {
      it("returns 'image-' + image_url", function() {
        siteElement.image_url = "www.something.com/blah.jpg";
        siteElement.image_placement = "left"
        expect(siteElement.imagePlacementClass()).toEqual("image-left");
      });
    });
  });
});
