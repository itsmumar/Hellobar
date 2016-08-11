//= require hellobar.base
var context = describe;

describe("HB", function() {
  describe(".applyOperand", function() {
    context("operand is equals", function() {
      it("matches strings", function() {
        var result = HB.applyOperand("/foo/bar", "equals", "/foo/bar");
        expect(result).toEqual(true);
      });

      it("matches strings with a wild card", function() {
        var result = HB.applyOperand("/foo/abc/bar", "equals", "/foo/*/bar");
        expect(result).toEqual(true);
      });

      it("doesn't match unequal strings", function() {
        var result = HB.applyOperand("blah", "equals", "/foo/bar");
        expect(result).toEqual(false);
      });

      it("doesn't match unequal strings (with wild card)", function() {
        var result = HB.applyOperand("foo/sadfsf/afsdf", "equals", "/foo/*/bar");
        expect(result).toEqual(false);
      });

      it("matches numbers", function() {
        var result = HB.applyOperand(5, "equals", 5);
        expect(result).toEqual(true);
      });

      it("matches numbers against strings", function() {
        var result = HB.applyOperand(5, "equals", "5");
        expect(result).toEqual(true);
      });

      it("matches various wild cards", function() {
        expect(HB.applyOperand("abc", "equals", "*")).toEqual(true);
        expect(HB.applyOperand("abc", "equals", "*abc")).toEqual(true);
        expect(HB.applyOperand("abcsdf", "equals", "*abc")).toEqual(false);
      });

      it("works with strings that have special regex characters", function() {
        expect(HB.applyOperand("a+?-^%#1", "equals", "a+?-^%#1")).toEqual(true);
      });

      it("works with wildcards while ignoring other special regex characters", function() {
        expect(HB.applyOperand("a+?.-^%#1", "equals", "a*1")).toEqual(true);
      });
    });

    context("operand is includes", function() {
      it("matches strings", function() {
        var result = HB.applyOperand("/foo/bar", "includes", "bar");
        expect(result).toEqual(true);
      });

      it("matches strings with a wild card", function() {
        var result = HB.applyOperand("sadf/bar", "includes", "a*/bar");
        expect(result).toEqual(true);
      });

      it("doesn't match unequal strings", function() {
        var result = HB.applyOperand("baz", "includes", "/foo/bar");
        expect(result).toEqual(false);
      });

      it("doesn't match unequal strings (with wild card)", function() {
        var result = HB.applyOperand("sadfsf/baz", "includes", "/foo/*/bar");
        expect(result).toEqual(false);
      });

      it("matches numbers", function() {
        var result = HB.applyOperand(5, "includes", 5);
        expect(result).toEqual(true);
      });

      it("matches numbers against strings", function() {
        var result = HB.applyOperand(5, "includes", "5");
        expect(result).toEqual(true);
      });

      it("matches various wild cards", function() {
        expect(HB.applyOperand("abc", "includes", "*")).toEqual(true);
        expect(HB.applyOperand("abc123", "includes", "b*12")).toEqual(true);
        expect(HB.applyOperand("123", "includes", "*abc")).toEqual(false);
      });

      it("works with strings that have special regex characters", function() {
        expect(HB.applyOperand("a+?-^%#1", "includes", "a+?-^%#1")).toEqual(true);
      });

      it("works with wildcards while ignoring other special regex characters", function() {
        expect(HB.applyOperand("a+?-.^%#1", "includes", "a*1")).toEqual(true);
      });

      it("returns false when the value is not present", function() {
        expect(HB.applyOperand(undefined, "includes", "")).toEqual(false);
      });
    });

    context("operand is does_not_include", function() {
      it("returns true when the value is not present", function() {
        expect(HB.applyOperand(undefined, "does_not_include", "")).toEqual(true);
      });
    });
  });
});