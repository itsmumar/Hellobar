hellobar.defineModule('inspect',
  ['hellobar', 'elements', 'elements.rules', 'base.site', 'base.metainfo'],
  function (hellobar, elements, rules, site, metainfo) {
    const elementsOnPage = () => elements.inspect().elementsOnPage();
    const allElementModels = () => rules.inspect().allElementModels();
    const allRules = () => rules.inspect().allRules();
    const elementColumns = [
      'id', 'subtype', 'type', 'template_name', 'theme_id', 'placement',
      'notification_delay', 'closable', 'show_branding', 'background_color',
      'link_color', 'text_color', 'button_color', 'primary_color',
      'trigger_color'
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
        const info = getInfo();

        console.info(`${metainfo.info()} for site#${info.siteId} ${info.siteUrl}`);

        console.groupCollapsed('allElementModels:');
        console.table(allElementModels(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('elementsOnPage:');
        console.table(elementsOnPage(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('allRules:');

        allRules().forEach((rule, index) => {
          console.log(`Rule ${index}, matchType: ${rule.matchType}`);

          rule.conditions.forEach((condition, index) => {
            console.log(`* Condition ${index}:`);
            console.log(`  - operand: "${condition.operand}"`);
            console.log(`  - segment: "${condition.segment}"`);

            if (Array.isArray(condition.value)) {
              console.log('  - values: "' + condition.value.join('", "') + '"');
            } else {
              console.log(`  - value: "${condition.value}"`);
            }
          });

          if (Array.isArray(rule.siteElements) && rule.siteElements.length > 0) {
            console.log('Site Elements:');
            console.table(rule.siteElements, elementColumns);

            elementsOnPage().forEach((elementOnPage, index) => {
              rule.siteElements.forEach((siteElement, index) => {
                if (elementOnPage.id === siteElement.id) {
                  console.log(`*********** siteElement ${siteElement.id} is ACTIVE on this page ***********`);
                }
              });
            });
          } else {
            console.log('No siteElements.');
          }

          console.log('---------------------------------------------------------------');
        });

        console.groupEnd();
      },
      all: () => getInfo()
    };
  });
