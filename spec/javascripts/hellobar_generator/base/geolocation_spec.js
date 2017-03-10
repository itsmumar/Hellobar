//= require hellobar_script/hellobar.base
//= require sinon
var context = describe;



describe("HB", function() {
  HB_SITE_ID = 9001;
  HB_GL_URL = "ip-api.com";

  locationResponse = {
    city: "Aztlan",
    countryCode: "US",
    region: "IL",
    regionName: "Illinois",
    status: "success",
    zip: "60660"
  };

  beforeEach(function() {
    HB.loadCookies();
    document.cookie = 'hbglc_9001=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    document.cookie = 'hbv_9001=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    document.cookie = 'hbs_9001=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
  });

  afterAll(function() {
    document.cookie = 'hbglc_9001=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    document.cookie = 'hbv_9001=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
    document.cookie = 'hbs_9001=;expires=Thu, 01 Jan 1970 00:00:01 GMT;';
  });

  describe("setGeolocationData", function() {
    it("saves cookies with correct data", function() {
      HB.setGeolocationData(locationResponse);
      expect(HB.cookies.location).toEqual({
        'gl_cty' : locationResponse.city,
        'gl_ctr' : locationResponse.countryCode,
        'gl_rgn' : locationResponse.region
      });
    });

    it("saves cookies with correct expiration days for non mobile clients", function() {
      spyOn(HB, 'sc');
      HB.setGeolocationData(locationResponse);
      expect(HB.sc).toHaveBeenCalledWith("hbglc_9001", "gl_cty:Aztlan|gl_ctr:US|gl_rgn:IL", 30)
    });

    it("saves cookies with correct expiration days for mobile clients", function() {
      spyOn(HB, 'sc');
      HB.setVisitorData("dv", "mobile");
      HB.setGeolocationData(locationResponse);
      expect(HB.sc).toHaveBeenCalledWith("hbglc_9001", "gl_cty:Aztlan|gl_ctr:US|gl_rgn:IL", 1)
    });

    it("reloads cookies", function() {
      spyOn(HB, 'loadCookies');
      HB.setGeolocationData(locationResponse);
      expect(HB.loadCookies).toHaveBeencalled;

    });
  });

  describe("getGeolocationData", function() {
    context("data does not exist in cookies", function() {
      beforeEach(function() {
        spyOn(HB, 'applyRules').and.returnValue(0);
        spyOn(HB, 'showSiteElements');
        spyOn(HB, 'setGeolocationData');

        window.localStorage.clear();
        HB.cookies.location = {};
        server = sinon.fakeServer.create();
        server.respondWith(
          [
            200,
            { "Content-Type": "application/json", "Content-Length": 131 },
            JSON.stringify(locationResponse)
          ]
        );
      });

      afterEach(function() {
        server.restore();
      });

      it("passes the response to setGeolocationData", function() {
        HB.getGeolocationData("gl_cty");
        server.respond();
        expect(HB.setGeolocationData).toHaveBeenCalledWith(locationResponse)
      });

      it("makes the callback call", function() {
        HB.getGeolocationData();
        server.respond();
        expect(HB.showSiteElements).toHaveBeenCalled();
      });

      it("only makes one request when getting multiple calls", function() {
        HB.getGeolocationData();
        HB.getGeolocationData();
        server.respond();
        expect(HB.showSiteElements.calls.count()).toEqual(1);
      });
    });

    context("data exists in cookies", function() {
      beforeEach(function() {
        HB.cookies.location = {'gl_cty' : 'Atlantis'};
        spyOn(XMLHttpRequest.prototype, 'open').and.stub();
        spyOn(XMLHttpRequest.prototype, 'send').and.stub();
      });

      it("returns data from cookie", function() {
        expect(HB.getGeolocationData('gl_cty')).toEqual("Atlantis")
      });


      it("does not make a request", function() {
        HB.getGeolocationData('gl_cty');
        expect(XMLHttpRequest.prototype.open).not.toHaveBeenCalled();
      });
    });
  });
});
