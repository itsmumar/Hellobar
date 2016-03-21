//= require hellobar.base
var context = describe;

describe("HB", function() {
  describe("HBQ", function() {
    context("HB_READY is a function", function() {
      beforeEach(function() {
        HB_READY = jasmine.createSpy('someFunction');
      });

      afterEach(function() {
        HB_READY = undefined;
      });

      it("calls HB_READY", function() {
        HBQ();
        expect(HB_READY).toHaveBeenCalled();
      });
    });

    context("HB_READY is not defined", function() {
      it("does not try to call HB_READY", function() {
        expect(HBQ).not.toThrow();
      });
    });
  });
});
