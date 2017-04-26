//= require modules/core
//= require modules/debug

describe('Module debug', () => {
  let module, elementColumns, allElements, elementsOnPage, allRules;

  beforeEach(() => {
    hellobar.finalize();
    allElements = [{id: 1}, {id: 2}];
    elementsOnPage = [{id: 1}];
    allRules = [{id: 3}];
    elementColumns = [
      'id', 'subtype', 'type', 'template_name', 'theme_id', 'placement', 'closable', 'show_branding',
      'background_color', 'link_color', 'text_color', 'button_color', 'primary_color', 'trigger_color'
    ];

    module = hellobar('debug', {
      dependencies: {
        elements: {
          inspect: () => jasmine.createSpyObj('elements', { elementsOnPage: elementsOnPage })
        },
        'elements.rules': {
          inspect: () => jasmine.createSpyObj('elements.rules', { allElements: allElements, allRules: allRules })
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

  describe('info()', () => {
    it('returns object with debug info', () => {
      const expected = {
        version: '9ca6c58b392a4cb879753e097667205a32e516ec',
        timestamp: '2017-04-07 13:05:33 UTC',
        siteId: 999,
        siteUrl: 'http://example.com',
        allElements: allElements,
        elementsOnPage: elementsOnPage,
        allRules: allRules
      }
      expect(module.info()).toEqual(expected);
    });

    it('prints info to console', () => {
      const spy = spyOn(console, 'info')
      module.print()
      expect(spy).toHaveBeenCalled();
    });

    it('prints allElements to console', () => {
      const spy = spyOn(console, 'table')
      module.print()
      expect(spy).toHaveBeenCalledWith(allElements, elementColumns);
    });
  })
});
