//= require hellobar_script/hellobar.base
var context = describe;

describe("HB", function() {
  describe(".sanitizeConditionValue", function() {
    beforeEach(function() {
      spyOn(HB, 'n');
    });

    context("when segment is not 'pu'", function() {
      it("returns the value", function() {
        var val = HB.sanitizeConditionValue("co", "USA", "GB");
        expect(val).toEqual("USA");
      });

      it("doesn't call normalize", function() {
        HB.sanitize("dv", "ios", "iOS");
        expect(HB.n).not.toHaveBeenCalled();
      });
    });

    context("when segment is 'pp'", function() {
      it("calls HB.n correct when url is absolute (http)", function() {
        var val = HB.sanitizeConditionValue(
          "pp",
          "http://google.com",
          "http://google.com"
        );

        expect(HB.n).toHaveBeenCalledWith("http://google.com", false);
      });

      it("calls HB.n correct when url is absolute (https)", function() {
        var val = HB.sanitizeConditionValue(
          "pp",
          "https://google.com",
          "https://google.com"
        );

        expect(HB.n).toHaveBeenCalledWith("https://google.com", false);
      });

      it("calls HB.n correct when url is relative", function() {
        var val = HB.sanitizeConditionValue(
          "pp",
          "https://google.com/about",
          "/about"
        );

        expect(HB.n).toHaveBeenCalledWith("https://google.com/about", true);
      });
    });

    context("when segment is 'pu'", function() {
      it("calls HB.n correct when url is absolute (http)", function() {
        var val = HB.sanitizeConditionValue(
          "pu",
          "http://google.com",
          "http://google.com"
        );

        expect(HB.n).toHaveBeenCalledWith("http://google.com", false);
      });

      it("calls HB.n correct when url is absolute (https)", function() {
        var val = HB.sanitizeConditionValue(
          "pu",
          "https://google.com",
          "https://google.com"
        );

        expect(HB.n).toHaveBeenCalledWith("https://google.com", false);
      });

      it("calls HB.n correct when url is relative", function() {
        var val = HB.sanitizeConditionValue(
          "pu",
          "https://google.com/about",
          "/about"
        );

        expect(HB.n).toHaveBeenCalledWith("https://google.com/about", true);
      });
    });
  });

  describe(".n", function() {
    it("converts string to lowercase", function() {
      var url = HB.n("GOOgLe.COM");
      expect(url).toEqual("google.com")
    });

    it("handles non string", function() {
      var url = HB.n(1);
      expect(url).toEqual("1");
    });

    context("when pathOnly is false", function() {
      it("removes www", function() {
        var url = HB.n("www.google.com", false);
        expect(url).toEqual("google.com");
      });

      it("removes hash parameters", function() {
        var url = HB.n("http://www.google.com/#foo", false);
        expect(url).toEqual("google.com");
      });

      it("removes https", function() {
        var url = HB.n("https://google.com", false);
        expect(url).toEqual("google.com");
      });

      context("when query parameters", function() {
        it("alphabetically orders the query params", function() {
          var url = HB.n("hellobar.com/?b=second&a=first", false);
          expect(url).toEqual("hellobar.com/?a=first&b=second");
        });

        it("adds slash before query if none exists", function() {
          var url = HB.n("http://www.hellobar.com?anything=true", false);
          expect(url).toEqual("hellobar.com/?anything=true");
        });
      });
    });

    context("when pathOnly is true", function() {
      it("does nothing with simple relative path", function() {
        var url = HB.n("/about", true);
        expect(url).toEqual("/about");
      });

      it("does nothing with simple relative html path", function() {
        var url = HB.n("/about.html", true);
        expect(url).toEqual("/about.html");
      });

      it("strips the protocol and site", function() {
        var url = HB.n("http://www.google.com/about", true);
        expect(url).toEqual("/about");
      });

      it("reorders query params", function() {
        var url = HB.n("http://hellobar.com/about?b=second&a=first", true);
        expect(url).toEqual("/about/?a=first&b=second");
      });

      it("returns / when url is index without slash", function() {
        var url = HB.n("http://hellobar.com", true);
        expect(url).toEqual("/");
      });

      it("returns / when url is index with slash", function() {
        var url = HB.n("http://hellobar.com/", true);
        expect(url).toEqual("/");
      });

      it("return '/?' when empty query with slash", function() {
        var url = HB.n("http://hellobar.com/?", true);
        expect(url).toEqual("/?");
      });

      it("returns '/?' when empty query without slash", function() {
        var url = HB.n("http://hellobar.com?", true);
        expect(url).toEqual("/?");
      });
    });
  });
});
