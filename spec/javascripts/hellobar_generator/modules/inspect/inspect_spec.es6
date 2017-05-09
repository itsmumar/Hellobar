//= require modules/core
//= require modules/inspect

describe('Module inspect', () => {
  let module, elementColumns, allElementModels, elementsOnPage,
    rules, activeRules, rulesWithElements, rulesWithoutElements;

  beforeEach(() => {
    hellobar.finalize();
    allElementModels = [{id: 1}, {id: 2}];
    rule = {id: 4, matchType: 'all', conditions: [], siteElements: []};
    siteElement = {id: 1, notification_delay: 10, rule: rule};
    rule.siteElements.push(siteElement);
    elementsOnPage = [siteElement];
    rulesWithoutElements = [{id: 3, matchType: 'all', conditions: [], siteElements: []}];
    rulesWithElements = [rule];
    rules = rulesWithElements.concat(rulesWithoutElements);
    activeRules = [rule];
    elementColumns = [
      'id', 'subtype', 'type', 'template_name', 'theme_id', 'placement',
      'notification_delay', 'closable', 'show_branding', 'background_color',
      'link_color', 'text_color', 'button_color', 'primary_color',
      'trigger_color'
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
        rules: rules,
        activeRules: activeRules,
        rulesWithElements: rulesWithElements,
        rulesWithoutElements: rulesWithoutElements,
      };
      expect(module.all()).toEqual(expected);
    });
  });

  describe('printAll()', () => {
    it('prints info to console', () => {
      const spy = spyOn(console, 'info');

      module.printAll();

      expect(spy).toHaveBeenCalledWith(
        'version 9ca6c58b392a4cb879753e097667205a32e516ec was generated at 2017-04-07 13:05:33 UTC for site#999 http://example.com'
      );
    });

    it('prints allElementModels table in the console', () => {
      const spy = spyOn(console, 'table');

      module.printAll();

      expect(spy).toHaveBeenCalledWith(allElementModels, elementColumns);
    });

    it('prints elementsOnPage table in the console', () => {
      const spy = spyOn(console, 'table');

      module.printAll();

      expect(spy).toHaveBeenCalledWith(elementsOnPage, elementColumns);
    });

    it('prints rules and associated siteElements in the console', () => {
      const spy = spyOn(console, 'table');

      module.printAll();

      expect(spy).toHaveBeenCalledWith(rules[0].siteElements, elementColumns);
    });
  });
});
