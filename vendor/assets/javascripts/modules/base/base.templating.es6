hellobar.defineModule('base.templating', ['hellobar', 'base.preview'], function (hellobar, preview) {

  let templates = {};

  const configuration = {
    addTemplate(name, html) {
      templates[name] = html;
    }
  };

  function getTemplateByName(templateName) {
    return templates[templateName];
  }

  // Renders the html template for the siteElement by calling HB.parseTemplateVar for
  // each {{...}} entry in the template
  function renderTemplate(html, context) {
    return html.replace(/\{\{(.*?)\}\}/g, function (match, value) {
      return parseTemplateVar(value, context);
    });
  }

  // Parses the value passed in in {{...}} for a template (which basically does an eval on it)
  function parseTemplateVar(value, context) {
    let siteElement = context && context.siteElement ? context.siteElement : context; // this variable is used in templates when `eval` is called

    try {
      value = eval(value);
    } catch (e) {
      preview.isActive() && console.log('Templating error: ', e);
    }
    if (value === undefined || value === null)
      return '';
    return value;
  }

  return {
    configuration: () => configuration,
    inspect: () => ({
      allTemplates: () => templates
    }),
    getTemplateByName,
    renderTemplate
  };

});
