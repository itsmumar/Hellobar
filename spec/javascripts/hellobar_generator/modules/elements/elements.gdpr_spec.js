//= require modules/elements/elements.gdpr

describe('Module elements.gdpr', function () {
  var module;
  var template;

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

    template = `
      <div class="gdpr-consent-form">
        <input type="checkbox" name="hb-gdpr-terms-checkbox">
        <input type="checkbox" name="hb-gdpr-consent-checkbox">
      </div>
    `;

    dependencies['base.templating'].render.and.returnValue(template);

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
  });

  afterEach(function () {
    document.body.querySelector('#hellobar-modal').remove();
  })

  it('displays gdpr form', function (done) {
    var siteElement = {
      enable_gdpr: true,
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

    var checkboxes = targetSiteElement
      .querySelectorAll('[name="hb-gdpr-terms-checkbox"], [name="hb-gdpr-consent-checkbox"]');
    checkboxes[0].click();
    checkboxes[1].click();

    document.body.querySelector('.hb-cta').click();

    expect(document.body.querySelector('.hb-text-holder').textContent).toEqual('Submit');
    setTimeout(function () {
      expect(callback).toHaveBeenCalled();
      done();
    }, 500)
  });

  it('does not display gdpr form if gdpr is not enabled', function () {
    var siteElement = {
      enable_gdpr: false,
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
    expect(callback).toHaveBeenCalled();
  });
});
