//= require hellobar_script/hellobar.base
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

      it("returns true when the current value does not include expected value", function() {
        expect(HB.applyOperand("bizarre", "does_not_include", "bar")).toEqual(true);
      });

      it("returns false when the current value includes current value", function() {
        expect(HB.applyOperand("*bar*", "does_not_include", "bar")).toEqual(false);
      });
    });

    context("operand is \"every\"", function() {
      it("returns true for every 2 against value 6", function() {
        expect(HB.applyOperand(6, "every", 2)).toEqual(true);
      });

      it("returns true for every 3 against value 27", function() {
        expect(HB.applyOperand(27, "every", 3)).toEqual(true);
      });

      it("returns true for every 1 against any value", function() {
        expect(HB.applyOperand(1, "every", 1)).toEqual(true);
        expect(HB.applyOperand(2, "every", 1)).toEqual(true);
        expect(HB.applyOperand(3, "every", 1)).toEqual(true);
        expect(HB.applyOperand(1123, "every", 1)).toEqual(true);
      });

      it("returns true for every 4 against value 11", function() {
        expect(HB.applyOperand(11, "every", 4)).toEqual(false);
      });
    });

    context("operand is \"less_than_or_equal\"", function() {
      it("returns true for condition 5 against value 3", function () {
        expect(HB.applyOperand(3, "less_than_or_equal", 5)).toEqual(true);
      });

      it("returns true for condition 5 against value 5", function () {
        expect(HB.applyOperand(5, "less_than_or_equal", 5)).toEqual(true);
      });

      it("returns true for condition -9 against value -15", function () {
        expect(HB.applyOperand(-15, "less_than_or_equal", -9)).toEqual(true);
      });

      it("returns false for condition 0 against value 5", function () {
        expect(HB.applyOperand(5, "less_than_or_equal", 0)).toEqual(false);
      });
    });

    context("operand is \"greater_than_or_equal\"", function() {
      it("returns false for condition 5 against value 3", function () {
        expect(HB.applyOperand(3, "greater_than_or_equal", 5)).toEqual(false);
      });

      it("returns true for condition 5 against value 5", function () {
        expect(HB.applyOperand(5, "greater_than_or_equal", 5)).toEqual(true);
      });

      it("returns false for condition -9 against value -15", function () {
        expect(HB.applyOperand(-15, "greater_than_or_equal", -9)).toEqual(false);
      });

      it("returns true for condition 0 against value 5", function () {
        expect(HB.applyOperand(5, "greater_than_or_equal", 0)).toEqual(true);
      });
    });

    context("operand is \"between\" or \"is_between\"", function() {
      it("returns true for condition [5, 10] against value 7", function () {
        expect(HB.applyOperand(7, "between", [5, 10])).toEqual(true);
      });

      it("returns true for condition [5, 10] against value 5", function () {
        expect(HB.applyOperand(5, "between", [5, 10])).toEqual(true);
      });

      it("returns true for condition [5, 10] against value 10", function () {
        expect(HB.applyOperand(10, "is_between", [5, 10])).toEqual(true);
      });

      it("returns false for condition [-5, 5] against value -6", function () {
        expect(HB.applyOperand(-6, "between", [-5, 5])).toEqual(false);
      });

      it("returns false for condition [-5, 5] against value 7", function () {
        expect(HB.applyOperand(7, "is_between", [-5, 5])).toEqual(false);
      });
    });
  });

  describe(".applyOperands", function() {
    context("operand is \"is\"", function() {
      it("matches strings", function() {
        var result = HB.applyOperands("/foo/bar", "is", ["bza", "/foo/bar"]);
        expect(result).toEqual(true);
      });

      it("doesn't match unequal strings (with wild card)", function() {
        var result = HB.applyOperands("foo/sadfsf/afsdf", "is", ["/foo/*/bar", "not/foo/sadfsf/afsdf", "meow"]);
        expect(result).toEqual(false);
      });

      it("returns false when the value is not present", function () {
        expect(HB.applyOperands(undefined, "is", ["qwert", "asd"])).toEqual(false);
      });

      it("returns false when the expected value is empty", function () {
        expect(HB.applyOperands("q", "is", [])).toEqual(false);
      });

      it("returns true when the expected value is not an array but still matches current value", function () {
        expect(HB.applyOperands("qwe", "is", "qwe")).toEqual(true);
      });
    });

    context("operand is \"includes\"", function() {
      it("matches strings", function () {
        var result = HB.applyOperands("/foo/bar", "includes", ["baz", "bar"]);
        expect(result).toEqual(true);
      });

      it("matches strings with a wild card", function () {
        var result = HB.applyOperands("sadf/bar", "includes", ["qwerty", "as*df", "a*/bar"]);
        expect(result).toEqual(true);
      });
    });

    context("operand is \"does_not_include\"", function() {
      it("returns true when the value is not present", function() {
        expect(HB.applyOperands(undefined, "does_not_include", [""])).toEqual(true);
      });

      it("returns true when current value does not include any of expected values", function() {
        expect(HB.applyOperands("bar", "does_not_include", ["baz", "buzz", "bza"])).toEqual(true);
      });

      it("returns false when one of the expected values matches current value", function() {
        expect(HB.applyOperands("beer-bar", "does_not_include", ["baz", "bar", "bza"])).toEqual(false);
      });
    });
  });
});
