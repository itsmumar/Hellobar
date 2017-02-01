//= require hellobar.base
//= require site_elements/site_element

var context = describe;

describe("SiteElement", function() {
  describe("#checkForDisplaySettings", function() {
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

  describe("#onClosed", function() {
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

  describe("#imageFor", function() {
    siteElement = null;
    beforeEach(function() {
      siteElement = new HB.SiteElement({});
    });

    context("when location matches image placement", function() {
      it("returns div element", function() {
        siteElement.image_url = "myCoolURL";
        siteElement.image_placement = "top";
        expectedDiv = '<div class="hb-image-wrapper top"><div class="hb-image-holder hb-editable-block hb-editable-block-image"><img class="uploaded-image" src="myCoolURL" /></div></div>'
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

  describe("#getBrightness", function() {
    var siteElement = new HB.SiteElement({});
    var precision = 3;
    //These values are not some standard.
    //They were calculated by our "getBrightness" function when it was created, so we should expect them in output
    var map = {
      "": NaN,
      "fff": NaN,
      "ffffff": 1,
      "000000": 0,
      "888888": .246,
      "eeeeee": .855,
      "B34242": .139,
      "5AB342": .348,
      "155B62": .085
    };
    map[undefined] = NaN;

    for (var input in map) {
      var output = map[input];

      it("should return " + output + " for #" + input, (function(input, output) {
        return function() {
          if (isNaN(output))
            expect(siteElement.getBrightness(input)).toBeNaN();
          else
            expect(siteElement.getBrightness(input)).toBeCloseTo(output, precision);
        }
      })(input, output));
    }
  });

  describe("#brightnessClass", function() {
    var siteElement = new HB.SiteElement({});
    var light = "light",
        dark = "dark";
    //map of values that we consider to be light or dark
    var map = {
      "": light, //default value is light
      "ffffff": light,
      "000000": dark,
      "888888": dark,
      "999999": light,
      "5AB342": light,
      "EB593C": light,
      "CB4E35": dark,
      "4D8589": dark
    };

    for (var input in map) {
      var output = map[input];

      it("value #" + input + " is considered as " + output, (function(input, output) {
        return function() {
          siteElement.background_color = input;
          expect(siteElement.brightnessClass()).toBe(output);
        }
      })(input, output));
    }
  });
});
