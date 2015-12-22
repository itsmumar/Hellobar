//= require site_elements/site_element
//= require hellobar.base
var context = describe;

describe("HB", function() {
  var siteElement;
  var HB_ORANGE = "e8562a";
  var WHITE = "fff";

  beforeEach(function() {
    siteElement = new HB.SiteElement({
      settings: {url: ""},
      template_name: "bar_traffic"
    });
  });


  describe(".adifySiteElement", function() {
    it("sets the primary color to Hello Bar orange", function () {
      siteElement.primary_color = WHITE;
      HB.adifySiteElement(siteElement);
      expect(siteElement.primary_color).toEqual(HB_ORANGE);
    });

    it("sets the background color to Hello Bar orange", function () {
      siteElement.background_color = WHITE;
      HB.adifySiteElement(siteElement);
      expect(siteElement.background_color).toEqual(HB_ORANGE);
    });

    it("forces the template to traffic", function () {
      siteElement.template_name = "bar_email";
      HB.adifySiteElement(siteElement);
      expect(siteElement.template_name).toEqual("bar_traffic");
    });

    it("removes any caption", function () {
      siteElement.caption = "this is a caption";
      HB.adifySiteElement(siteElement);
      expect(siteElement.caption).toEqual("");
    });

    it("removes any image", function () {
      siteElement.image_url = "http://images.com/image1.jpg";
      HB.adifySiteElement(siteElement);
      expect(siteElement.image_url).toEqual(null);
    });

    it("sets text color to white", function () {
      siteElement.text_color = "aabbcc";
      HB.adifySiteElement(siteElement);
      expect(siteElement.text_color).toEqual(WHITE);
    });

    it("sets button color to white", function () {
      siteElement.button_color = "aabbcc";
      HB.adifySiteElement(siteElement);
      expect(siteElement.button_color).toEqual(WHITE);
    });

    it("sets font to open sans", function () {
      siteElement.font = "helvetica";
      HB.adifySiteElement(siteElement);
      expect(siteElement.font).toEqual("'Open Sans',sans-serif");
    });

    it("sets the headline", function () {
      siteElement.headline = "abc";
      HB.adifySiteElement(siteElement);
      expect(siteElement.headline).toEqual('Make money from wasted space on your site: Use Hello Bar.');
    });

    it("sets the link_text", function () {
      siteElement.link_text = "abc";
      HB.adifySiteElement(siteElement);
      expect(siteElement.link_text).toEqual('Get Started');
    });

    it("sets the link url", function () {
      siteElement.settings = {url: "asdf"};
      HB.adifySiteElement(siteElement);
      expect(siteElement.settings.url).toEqual("https://www.hellobar.com");
    });

    context("element is a Bar", function() {
      beforeEach(function() {
        siteElement.template_name = "bar_traffic";
      });

      it("sets the secondary color to white", function () {
        siteElement.secondary_color = "aabbcc";
        HB.adifySiteElement(siteElement);
        expect(siteElement.secondary_color).toEqual(WHITE);
      });

      it("sets the link color to orange", function () {
        siteElement.link_color = "aabbcc";
        HB.adifySiteElement(siteElement);
        expect(siteElement.link_color).toEqual(HB_ORANGE);
      });
    });

    context("element is not a bar", function() {
      beforeEach(function() {
        siteElement.template_name = "modal_traffic";
      });

      it("sets the secondary color to orange", function () {
        siteElement.secondary_color = "aabbcc";
        HB.adifySiteElement(siteElement);
        expect(siteElement.secondary_color).toEqual(HB_ORANGE);
      });

      it("sets the link color to white", function () {
        siteElement.link_color = "aabbcc";
        HB.adifySiteElement(siteElement);
        expect(siteElement.link_color).toEqual(WHITE);
      });
    });
  });
});
