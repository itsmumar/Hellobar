//= require hellobar.base

describe("HB.paramsFromString", function() {
  it("supports ASCII encoded strings", function() {
    string = "https://www.visitorpasssolutions.com/Blog/BlogView.asp?BlogId=40968122&CategoryID=0&title=Security+crisis+in+the+workplace+%96+tips+for+before%2C+during%2C+and+after"
    params = HB.paramsFromString(string)

    expectedParams = {
      blogid: '40968122',
      categoryid: '0',
      title: 'Security+crisis+in+the+workplace+%96+tips+for+before%2C+during%2C+and+after'
    }

    expect(params).toEqual(expectedParams)
  });
});
