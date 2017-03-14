//= require hellobar_script/hellobar.base

describe("HB.paramsFromString", function() {
  it("supports ASCII encoded strings", function() {
    var string = "https://www.visitorpasssolutions.com/Blog/BlogView.asp?BlogId=40968122&CategoryID=0&title=Security+crisis+in+the+workplace+%96+tips+for+before%2C+during%2C+and+after";
    var params = HB.paramsFromString(string);

    var expectedParams = {
      BlogId: '40968122',
      CategoryID: '0',
      title: 'Security+crisis+in+the+workplace+%96+tips+for+before%2C+during%2C+and+after'
    };

    expect(params).toEqual(expectedParams);
  });
});
