//= require modules/core
//= require modules/inspect

describe('Module inspect', () => {
  let module, elementColumns, allElementModels, elementsOnPage, rules;

  beforeEach(() => {
    hellobar.finalize();
    allElementModels = [{id: 1}, {id: 2}];
    elementsOnPage = [{id: 1}];
    rules = [{id: 3}];
    elementColumns = [
      'id', 'subtype', 'type', 'template_name', 'theme_id', 'placement', 'closable', 'show_branding',
      'background_color', 'link_color', 'text_color', 'button_color', 'primary_color', 'trigger_color'
    ];

    module = hellobar('inspect', {
      dependencies: {
        elements: {
          inspect: () => jasmine.createSpyObj('elements', { elementsOnPage: elementsOnPage })
        },
        'elements.rules': {
          inspect: () => jasmine.createSpyObj('elements.rules', { allElementModels: allElementModels, allRules: rules })
        },
        'base.site': jasmine.createSpyObj('base.site', { siteId: 999, siteUrl: 'http://example.com' }),
        'base.metainfo': jasmine.createSpyObj('base.metainfo', {
          version: '9ca6c58b392a4cb879753e097667205a32e516ec',
          timestamp: '2017-04-07 13:05:33 UTC',
          info: 'version 9ca6c58b392a4cb879753e097667205a32e516ec was generated at 2017-04-07 13:05:33 UTC'
        })
      }
    });
  });

  describe('all()', () => {
    it('returns object with info', () => {
      const expected = {
        version: '9ca6c58b392a4cb879753e097667205a32e516ec',
        timestamp: '2017-04-07 13:05:33 UTC',
        siteId: 999,
        siteUrl: 'http://example.com',
        elements: allElementModels,
        elementsOnPage: elementsOnPage,
        rules: rules
      }
      expect(module.all()).toEqual(expected);
    });
  });

  describe('printAll()', () => {
    it('prints info to console', () => {
      const spy = spyOn(console, 'info')
      module.printAll()
      expect(spy).toHaveBeenCalledWith(
        'version 9ca6c58b392a4cb879753e097667205a32e516ec was generated at 2017-04-07 13:05:33 UTC for site#999 http://example.com'
      );
    });

    it('prints allElementModels to console', () => {
      const spy = spyOn(console, 'table')
      module.printAll()
      expect(spy).toHaveBeenCalledWith(allElementModels, elementColumns);
    });

    it('prints elementsOnPage to console', () => {
      const spy = spyOn(console, 'table')
      module.printAll()
      expect(spy).toHaveBeenCalledWith(elementsOnPage, elementColumns);
    });

    it('prints elementsOnPage to console', () => {
      const spy = spyOn(console, 'table')
      module.printAll()
      expect(spy).toHaveBeenCalledWith(rules);
    });
  });
});
