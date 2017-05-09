//= require modules/base/base.dom

describe('Module base.dom', function () {
  var module;

  beforeEach(function () {
    module = hellobar('base.dom');
  });

  it('traverses through all the documents', function () {
    document.body.innerHTML = '<div><iframe></iframe><iframe></iframe></div>';
    var documentCount = 0;
    module.forAllDocuments(function () {
      documentCount++;
    });
    expect(documentCount).toEqual(3);
    document.body.innerHTML = '';
  });

  it('calls a callback when DOM is ready', function (done) {
    var spy = jasmine.createSpy('spy');
    module.runOnDocumentReady(function () {
      spy();
    });
    setTimeout(function () {
      expect(spy).toHaveBeenCalled();
      expect(spy.calls.count(), 1);
      done();
    }, 1);

  });

});
