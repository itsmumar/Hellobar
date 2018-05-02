//= require modules/elements/elements.gdpr

describe('Module elements.gdpr', function () {
  var module;

  beforeEach(function () {
    hellobar.finalize();

    var dependencies = {
      'base.templating': jasmine.createSpyObj('base.templating', ['render']),
      'base.site': true,
      'base.dom': true
    };

    module = hellobar('elements.gdpr', {
      dependencies: dependencies
    });


    dependencies['base.templating'].render.and.returnValue("-TEMPLATE-");
  });

  it('successfully creates and removes elements', function () {
    var html = `
      <div id="hellobar-modal">
        <div class="hb-text-wrapper">
          <div class="hb-headline-text"></div>
        </div>
        <div class="hb-input-wrapper">
          <div class="hb-fields-form">
            <a class="hb-cta"><div class="hb-text-holder"></div></a>
          </div>
        </div>
      </div>
    `;

    document.body.insertAdjacentHTML('beforeend', html);

    var siteElement = {
      contentDocument () {
        return document.body.querySelector('#hellobar-modal')
      },

      model () {
        return this
      }
    };

    var targetSiteElement = document.body.querySelector('.hb-headline-text');
    var callback = jasmine.createSpy('callback');

    module.displayCheckboxes(siteElement, targetSiteElement, callback);
    document.body.querySelector('.hb-cta').click();

    expect(document.body.querySelector('.hb-text-holder').textContent).toEqual('Submit');
    expect(document.body.querySelector('.hb-headline-text').textContent).toEqual('-TEMPLATE-');
    expect(callback).toHaveBeenCalled();
  });

});
