hellobar.defineModule('debug',
  ['hellobar', 'elements', 'elements.rules', 'base.site', 'base.metainfo'],
  function (hellobar, elements, rules, site, metainfo) {
    const elementsOnPage = () => elements.inspect().elementsOnPage();
    const allElements = () => rules.inspect().allElements();
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
        allElements: allElements(),
        elementsOnPage: elementsOnPage(),
        allRules: allRules()
      }
    };

    return {
      print: () => {
        let info = getInfo();

        console.info(`${metainfo.info()} for site#${info.siteId} ${info.siteUrl}`);

        console.groupCollapsed('allElements:');
        console.table(allElements(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('elementsOnPage:');
        console.table(elementsOnPage(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('allRules:');
        console.table(allRules());
        console.groupEnd();
      },
      info: () => getInfo()
    };
  });
