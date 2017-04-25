hellobar.defineModule('base.metainfo',
  ['hellobar', 'elements', 'elements.rules', 'base.site'],
  function (hellobar, elements, rules, site) {
    const configuration = hellobar.createModuleConfiguration({
      version: 'string',
      timestamp: 'string'
    });

    const elementsOnPage = elements.introspect().elementsOnPage();
    const allElements = rules.introspect().allElements();
    const allRules = rules.introspect().allRules();
    const elementColumns = [
      'id', 'subtype', 'type', 'template_name', 'theme_id', 'placement', 'closable', 'show_branding',
      'background_color', 'link_color', 'text_color', 'button_color', 'primary_color', 'trigger_color'
    ];
    const getInfo = () => {
      return {
        version: configuration.version(),
        timestamp: configuration.timestamp(),
        siteId: site.siteId(),
        siteUrl: site.siteUrl(),
        allElements,
        elementsOnPage,
        allRules
      }
    };

    return {
      configuration: () => configuration,
      info: () => {
        console.clear()
        const info = getInfo();
        console.info(`version ${info.version} was generated at ${info.timestamp} for site#${info.siteId} ${info.siteUrl}`);

        console.groupCollapsed('allElements:');
        console.table(allElements, elementColumns);
        console.groupEnd();

        console.groupCollapsed('elementsOnPage:');
        console.table(elementsOnPage, elementColumns);
        console.groupEnd();

        console.groupCollapsed('allRules:');
        console.table(allRules);
        console.groupEnd();

        return info;
      }
    };
  });
