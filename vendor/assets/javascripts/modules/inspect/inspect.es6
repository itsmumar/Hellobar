hellobar.defineModule('inspect',
  ['hellobar', 'elements', 'elements.rules', 'base.site', 'base.metainfo', 'contentUpgrades'],
  function (hellobar, elements, rules, site, metainfo, contentUpgrades) {
    const elementsOnPage = () => elements.inspect().elementsOnPage();
    const allElementModels = () => rules.inspect().allElementModels();
    const allRules = () => rules.inspect().allRules();
    const allContentUpgrades = () => contentUpgrades.configuration().contentUpgrades();
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
        rules: allRules(),
        activeRules: elementsOnPage().map((element) => element.rule),
        rulesWithElements: allRules().filter((rule) => rule.siteElements.length > 0),
        rulesWithoutElements: allRules().filter((rule) => rule.siteElements.length == 0),
        contentUpgrades: allContentUpgrades()
      }
    };

    const printRule = (info, rule, index) => {
      let label = info.activeRules.filter((activeRule) => activeRule == rule).length > 0 ? 'ACTIVE' : 'INACTIVE'

      console.log(`[${label}] Rule ${index}, matchType: ${rule.matchType}`);

      rule.conditions.forEach((condition, index) => {
        console.log(`* Condition ${index}:`);
        console.log(`  - segment: "${condition.segment}"`);
        console.log(`  - operand: "${condition.operand}"`);

        if (Array.isArray(condition.value)) {
          console.log('  - values: "' + condition.value.join('", "') + '"');
        } else {
          console.log(`  - value: "${condition.value}"`);
        }
      });

      if (rule.siteElements.length > 0) {
        console.log('Site Elements:');
        console.table(rule.siteElements, elementColumns);

        info.elementsOnPage.forEach((elementOnPage, index) => {
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
    }

    return {
      printAll: () => {
        const info = getInfo();

        console.info(`${metainfo.info()} for site#${info.siteId} ${info.siteUrl}`);

        console.groupCollapsed('elementsOnPage:');
        console.table(elementsOnPage(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('activeRules:');
        info.activeRules.forEach((rule, index) => printRule(info, rule, index));
        console.groupEnd();

        console.groupCollapsed('allElementModels:');
        console.table(allElementModels(), elementColumns);
        console.groupEnd();

        console.groupCollapsed('rulesWithElements:');
        info.rulesWithElements.forEach((rule, index) => printRule(info, rule, index));
        console.groupEnd();

        console.groupCollapsed('rulesWithoutElements:');
        info.rulesWithoutElements.forEach((rule, index) => printRule(info, rule, index));
        console.groupEnd();
      },
      all: () => getInfo()
    };
  });
