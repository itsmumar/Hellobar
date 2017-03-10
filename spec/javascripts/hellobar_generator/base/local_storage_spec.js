//= require hellobar_script/hellobar.base

var context = describe;

describe("HB", function () {
  describe(".getLocalStorageData", function() {
    context("data is present", function () {
      context("data expired", function () {
        it("deletes data", function () {
          var testData = { value : "shorter data", expiration : "Fri Aug 05 1966 00:00:00 GMT-0500 (CDT)" };
          window.localStorage.setItem("test", JSON.stringify(testData));
          HB.getLocalStorageData('test')

          expect(window.localStorage.getItem("test")).toEqual(null);
        });

        it("returns a null", function () {
          var testData = { value : "shorter data", expiration : "Fri Aug 05 1966 00:00:00 GMT-0500 (CDT)" };
          window.localStorage.setItem("test", JSON.stringify(testData));

          expect(HB.getLocalStorageData('test')).toEqual(null);
        });
      });

      context("data did not expire", function () {
        it("returns data", function () {
          var testData = { value : "this is NOT a test, and my name is Bizarro!" , expiration : "Tue Aug 05 2966 00:00:00 GMT-0500 (CDT)" };
          window.localStorage.setItem("testo", JSON.stringify(testData));

          expect(HB.getLocalStorageData('testo')).toEqual("this is NOT a test, and my name is Bizarro!");
        });
      });
    });

    context("data is not present", function () {
      it("returns a null", function () {
        window.localStorage.clear()
        expect(HB.getLocalStorageData("testo")).toEqual(null);
      });
    });
  });

  describe(".gc", function() {
    context("data saved in localStorage", function () {
      beforeAll( function() {
        var testData = { value : "this is NOT a test, and my name is Bizarro!" , expiration : "Tue Aug 05 2966 00:00:00 GMT-0500 (CDT)" };
        window.localStorage.setItem("testo", JSON.stringify(testData));
      });

      it("returns data in localStorage", function () {
        expect(HB.gc("testo")).toEqual("this is NOT a test, and my name is Bizarro!");
      });

      it("does not read data from cookies", function () {
        document.cookie = "testo=fake_nooo";
        expect(HB.gc("testo")).not.toEqual("fake_nooo");
      });
    });

    context("data not saved in localStorage", function () {
      it("reads data from cookies", function () {
        window.localStorage.clear();
        document.cookie = "testo=real_nooo";
        expect(HB.gc("testo")).toEqual("real_nooo");
      });
    });
  });

  describe(".sc", function() {
    it("saves data with expiration to localStorage", function () {
      HB.sc("seriousKey", "seriousValue", 30);
      expect(HB.gc("seriousKey")).toEqual("seriousValue");
    });
  });
});
