//= require modules/core
//= require modules/base/base.cdn

describe('Module base.cdn', function () {
  var module;

  beforeEach(function () {
    hellobar.finalize();
    module = hellobar('base.cdn', {
      dependencies: {}
    });
  });

  function createSandboxIFrame() {
    var iframe = document.createElement('iframe');
    document.body.appendChild(iframe);
    return iframe;
  }

  it('supports JS inclusion', function () {
    var iframe = createSandboxIFrame();
    var scriptCount = iframe.contentDocument.getElementsByTagName('script').length;
    var linkCount = iframe.contentDocument.getElementsByTagName('link').length;
    module.addJs('//cdnjs.cloudflare.com/ajax/libs/lodash.js/4.17.4/lodash.min.js', iframe.contentDocument);
    expect(iframe.contentDocument.getElementsByTagName('script').length).toEqual(scriptCount + 1);
    expect(iframe.contentDocument.getElementsByTagName('link').length).toEqual(linkCount);
    iframe.remove();
  });

  it('supports CSS inclusion', function () {
    var iframe = createSandboxIFrame();
    var scriptCount = iframe.contentDocument.getElementsByTagName('script').length;
    var linkCount = iframe.contentDocument.getElementsByTagName('link').length;
    module.addCss('//cdnjs.cloudflare.com/ajax/libs/meyer-reset/2.0/reset.min.css', iframe.contentDocument);
    expect(iframe.contentDocument.getElementsByTagName('script').length).toEqual(scriptCount);
    expect(iframe.contentDocument.getElementsByTagName('link').length).toEqual(linkCount + 1);
    iframe.remove();
  });

});
