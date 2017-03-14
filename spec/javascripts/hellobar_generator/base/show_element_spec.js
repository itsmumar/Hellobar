//= require hellobar_script/hellobar.base

describe("HB", function() {
  var element;

  beforeEach(function() {
    element = document.createElement("div");
    document.body.appendChild(element);
  });

  afterEach(function() {
    document.body.removeChild(element);
  });

  describe(".showElement", function() {
    it("sets the elements display to inline", function () {
      element.style.display = "hidden";
      HB.showElement(element);
      expect(element.style.display).toEqual("inline");
    });

    it("sets the elements display to the second parameter", function () {
      element.style.display = "hidden";
      HB.showElement(element, 'block');
      expect(element.style.display).toEqual("block");
    });
  });
});
