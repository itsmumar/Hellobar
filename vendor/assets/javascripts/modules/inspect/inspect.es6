hellobar.defineModule('inspect',
  ['hellobar', 'elements', 'elements.rules', 'base.site', 'base.metainfo'],
  function (hellobar, elements, rules, site, metainfo) {
    const elementsOnPage = () => elements.inspect().elementsOnPage();
    const allElementModels = () => rules.inspect().allElementModels();
    const allRules = () => rules.inspect().allRules();
    const elementColumns = [
      'id', 'subtype', 'type', 'template_name', 'theme_id', 'placement', 'closable', 'show_branding',
      'background_color', 'link_color', 'text_color', 'button_color', 'primary_color', 'trigger_color'
    ];

    const getInfo = () => {
      return {
        version: metainfo.version(),
        timestamp: metainfo.timestamp(),
        siteId: site.siteId(),
        siteUrl: site.siteUrl(),
        elements: allElementModels(),
        elementsOnPage: elementsOnPage(),
        rules: allRules()
      }
    };

    return {
      printAll: () => {
        let info = getInfo();

        console.info(`${metainfo.info()} for site#${info.siteId} ${info.siteUrl}`);

        console.groupCollapsed('allElementModels:');
        console.table(allElementModels(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('elementsOnPage:');
        console.table(elementsOnPage(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('allRules:');
        console.table(allRules());
        console.groupEnd();
      },
      all: () => getInfo()
    };
  });
