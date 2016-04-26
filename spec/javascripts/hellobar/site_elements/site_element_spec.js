//= require hellobar.base
//= require site_elements/site_element

var context = describe;

describe("SiteElement", function() {
  describe("#imageFor", function() {
    siteElement = null;
    beforeEach(function() {
      siteElement = new HB.SiteElement({});
    });

    context("when location matches image placement", function() {
      it("returns div element", function() {
        siteElement.image_url = "myCoolURL";
        siteElement.image_placement = "top";
        expectedDiv = "<div class='hb-image-wrapper top'><img class='uploaded-image' src=myCoolURL /></div>"
        expect(siteElement.imageFor(['top'])).toEqual(expectedDiv);
      });
    });

    context("when location does not match image placement", function() {
      it("returns empty string", function() {
        siteElement.image_url = "myCoolURL";
        siteElement.image_placement = "top";
        expect(siteElement.imageFor(['bottom'])).toEqual('');
      });

      it("returns empty string when indexOf returns undefined", function() {
        siteElement.image_url = "myCoolURL";
        imageLocation = ['bottom']
        imageLocation.indexOf = function(string) {
          return undefined;
        }

        siteElement.image_placement = "top";
        expect(siteElement.imageFor(imageLocation)).toEqual('');
      });
    });
  });

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

  describe("#converted", function() {
    it("calls converted on HB with correct params", function() {
      siteElement = new HB.SiteElement({});
      spyOn(HB, "converted");

      siteElement.converted();

      expect(HB.converted).toHaveBeenCalledWith(siteElement);
    });
  });
});
