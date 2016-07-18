//= require hellobar.base
var context = describe;

describe("HB.geoLocationConditionTrue", function() {
  var condition = {
    segment: 'gl_ctr',
    value: "US"
  };

  context("operand is", function() {
    beforeEach(function() {
      condition.operand = 'is';
    });

    it("returns true when the current country is the condition's country", function() {
      var currentCountry = "US";
      spyOn(HB, 'getSegmentValue').and.returnValue(currentCountry);

      expect(HB.geoLocationConditionTrue(condition)).toEqual(true);
    });

    it("returns false when the current country is not the condition's country", function() {
      var currentCountry = "UY";
      spyOn(HB, 'getSegmentValue').and.returnValue(currentCountry);

      expect(HB.geoLocationConditionTrue(condition)).toEqual(false);
    });

    it("returns false when the current country is undefined", function() {
      var currentCountry = undefined;
      spyOn(HB, 'getSegmentValue').and.returnValue(currentCountry);

      expect(HB.geoLocationConditionTrue(condition)).toEqual(false);
    });
  });

  context("operand is_not", function() {
    beforeEach(function() {
      condition.operand = 'is_not';
    });

    it("returns false when the current country is the condition's country", function() {
      var currentCountry = "US";
      spyOn(HB, 'getSegmentValue').and.returnValue(currentCountry);

      expect(HB.geoLocationConditionTrue(condition)).toEqual(false);
    });

    it("returns true when the current country is not the condition's country", function() {
      var currentCountry = "UY";
      spyOn(HB, 'getSegmentValue').and.returnValue(currentCountry);

      expect(HB.geoLocationConditionTrue(condition)).toEqual(true);
    });

    it("returns false when the current country is undefined", function() {
      var currentCountry = undefined;
      spyOn(HB, 'getSegmentValue').and.returnValue(currentCountry);

      expect(HB.geoLocationConditionTrue(condition)).toEqual(false);
    });
  });
});
