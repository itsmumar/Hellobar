//= require hellobar_script/hellobar.base
var context = describe;

describe("HB.timeConditionTrue", function() {
  var condition = {
    segment: 'tc',
    value: [12,30]
  };

  context("operand is before", function() {
    beforeEach(function() {
      condition.operand = 'before';
    });

    it("returns true when the current site time is before the condition time", function() {
      var currentTime = new Date("April 09, 1985 12:29:00");
      spyOn(HB, 'nowInTimezone').and.returnValue(currentTime);

      expect(HB.timeConditionTrue(condition)).toEqual(true);
    });

    it("returns false when the current site time is equal to the condition time", function() {
      var currentTime = new Date("April 09, 1985 12:30:00");
      spyOn(HB, 'nowInTimezone').and.returnValue(currentTime);

      expect(HB.timeConditionTrue(condition)).toEqual(false);
    });

    it("returns false when the current site time is after the condition time", function() {
      var currentTime = new Date("April 09, 1985 12:31:00");
      spyOn(HB, 'nowInTimezone').and.returnValue(currentTime);

      expect(HB.timeConditionTrue(condition)).toEqual(false);
    });
  });

  context("operand is after", function() {
    beforeEach(function() {
      condition.operand = 'after';
    });

    it("returns false when the current site time is before the condition time", function() {
      var currentTime = new Date("April 09, 1985 12:29:00");
      spyOn(HB, 'nowInTimezone').and.returnValue(currentTime);

      expect(HB.timeConditionTrue(condition)).toEqual(false);
    });

    it("returns false when the current site time is equal to the condition time", function() {
      var currentTime = new Date("April 09, 1985 12:30:00");
      spyOn(HB, 'nowInTimezone').and.returnValue(currentTime);

      expect(HB.timeConditionTrue(condition)).toEqual(false);
    });

    it("returns true when the current site time is after the condition time", function() {
      var currentTime = new Date("April 09, 1985 12:31:00");
      spyOn(HB, 'nowInTimezone').and.returnValue(currentTime);

      expect(HB.timeConditionTrue(condition)).toEqual(true);
    });
  });
});
