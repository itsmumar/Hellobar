//= require hellobar_script/hellobar.base

describe("HB", function() {
    describe(".filterMostRelevantRules()", function() {
        it("should return empty array for empty array passed in", function() {
            var output = HB.filterMostRelevantRules([]);
            expect(output).toEqual([]);
        });

        it("should return same array for array with single value", function() {
            var input = [{foo: "bar"}];
            var output = HB.filterMostRelevantRules(input);
            expect(output).toEqual(input);
        });

        it("'all' rules: rule with 1 condition is more relevant than rule with no conditions", function() {
            var a = {matchType: "all", conditions: []};
            var b = {matchType: "all", conditions: [1]};
            var output = HB.filterMostRelevantRules([a, b]);
            expect(output).toEqual([b]);
        });

        it("'all' rules: rule with 2 conditions is more relevant than rule with 1 condition", function() {
            var a = {matchType: "all", conditions: [1]};
            var b = {matchType: "all", conditions: [1, 2]};
            var c = {matchType: "all", conditions: [3]};
            var output = HB.filterMostRelevantRules([a, b, c]);
            expect(output).toEqual([b]);
        });

        it("'all' rules: should return all rules having same maximum number of conditions", function() {
            var a = {matchType: "all", conditions: [1, 2, 3]};
            var b = {matchType: "all", conditions: [4, 5]};
            var c = {matchType: "all", conditions: [6, 7, 8]};
            var d = {matchType: "all", conditions: []};
            var output = HB.filterMostRelevantRules([a, b, c, d]);
            expect(output).toEqual([a, c]);
        });

        it("'any' rules: rule with 1 condition is more relevant than rule with no conditions", function() {
            var a = {matchType: "any", conditions: [1]};
            var b = {matchType: "any", conditions: []};
            var output = HB.filterMostRelevantRules([a, b]);
            expect(output).toEqual([a]);
        });

        it("'any' rules: rule with 1 condition is more relevant than rule with 2 conditions", function() {
            var a = {matchType: "any", conditions: [1, 2]};
            var b = {matchType: "any", conditions: [1]};
            var output = HB.filterMostRelevantRules([a, b]);
            expect(output).toEqual([b]);
        });

        it("'any' rules: rule with 2 condition is more relevant than rules with more conditions", function() {
            var a = {matchType: "any", conditions: [1, 2, 3]};
            var b = {matchType: "any", conditions: [1, 2]};
            var c = {matchType: "any", conditions: []};
            var d = {matchType: "any", conditions: [1, 2, 3, 4]};
            var output = HB.filterMostRelevantRules([a, b, c, d]);
            expect(output).toEqual([b]);
        });

        it("'any' rules: should return all rules having same minimum number of conditions", function() {
            var a = {matchType: "any", conditions: [1, 2, 3]};
            var b = {matchType: "any", conditions: [1, 2, 3, 4, 5]};
            var c = {matchType: "any", conditions: []};
            var d = {matchType: "any", conditions: [1, 2, 3, 4]};
            var e = {matchType: "any", conditions: [1, 2, 3]};
            var output = HB.filterMostRelevantRules([a, b, c, d, e]);
            expect(output).toEqual([a, e]);
        });

        it("'all/any' rules: 'any' rule with 1 condition is more relevant than 'all' rule with no conditions", function() {
            var a = {matchType: "all", conditions: []};
            var b = {matchType: "any", conditions: [1]};
            var output = HB.filterMostRelevantRules([a, b]);
            expect(output).toEqual([b]);
        });

        it("'all/any' rules: should return both 'all' and 'any' rules having no conditions", function() {
            var a = {matchType: "all", conditions: []};
            var b = {matchType: "any", conditions: []};
            var output = HB.filterMostRelevantRules([a, b]);
            expect(output).toEqual([a, b]);
        });

        it("'all/any' rules: should return both 'all' and 'any' rules having 1 condition", function() {
            var a = {matchType: "all", conditions: []};
            var b = {matchType: "any", conditions: []};
            var c = {matchType: "all", conditions: [1]};
            var d = {matchType: "any", conditions: [1]};
            var output = HB.filterMostRelevantRules([a, b, c, d]);
            expect(output).toEqual([c, d]);
        });

        it("'all/any' rules: 'all' rule is more relevant than 'any' rule having more than 1 condition", function() {
            var a = {matchType: "all", conditions: [1, 2]};
            var b = {matchType: "any", conditions: []};
            var c = {matchType: "all", conditions: [1]};
            var d = {matchType: "any", conditions: [1, 2]};
            var output = HB.filterMostRelevantRules([a, b, c, d]);
            expect(output).toEqual([a]);
        });

        it("'all/any' rules: should return all 'all' rules having same maximum number of conditions and no 'any' rules", function() {
            var a = {matchType: "any", conditions: [1]};
            var b = {matchType: "any", conditions: [1, 2, 3]};
            var c = {matchType: "all", conditions: [1, 2, 3]};
            var d = {matchType: "all", conditions: [1]};
            var e = {matchType: "all", conditions: [2, 3, 4]};
            var output = HB.filterMostRelevantRules([a, b, c, d, e]);
            expect(output).toEqual([c, e]);
        });
    });

    describe(".filterMostRelevantElements()", function() {
        it("should return empty array for an empty array", function() {
            var output = HB.filterMostRelevantElements([]);
            expect(output).toEqual([]);
        });

        it("should return same array for an array with a single element", function() {
            var a = {rule: {}};
            var output = HB.filterMostRelevantElements([a]);
            expect(output).toEqual([a]);
        });

        it("should return conditional element rather than element shown to everyone", function() {
            var a = {
                rule: {matchType: "all", conditions: []}
            };
            var b = {
                rule: {matchType: "all", conditions: [1]}
            };
            var output = HB.filterMostRelevantElements([a, b]);
            expect(output).toEqual([b]);
        });

        it("should return the most relevant elements", function() {
            var a = {
                rule: {matchType: "all", conditions: []}
            };
            var b = {
                rule: {matchType: "all", conditions: [1, 2]}
            };
            var c = {
                rule: {matchType: "any", conditions: [1]}
            };
            var d = {
                rule: {matchType: "any", conditions: [1, 2]}
            };
            var e = {
                rule: {matchType: "all", conditions: [1, 2]}
            };
            var output = HB.filterMostRelevantElements([a, b, c, d, e]);
            expect(output).toEqual([b, e]);
        });
    });
});
