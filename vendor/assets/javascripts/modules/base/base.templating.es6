hellobar.defineModule('elements.bar', ['base.preview'], function (preview) {

  let templates = {};

  // TODO -> base.templating
  // TODO replace setTemplate with module configuration
// Sets the template HTML. Note if you override getTemplate this will have
// no affect
  function setTemplate(type, html) {
    templates[type] = html;
  }

  // TODO -> base.templating
  function getTemplateByName(templateName) {
    return templates[templateName];
  }

  // TODO -> base.templating
  // Renders the html template for the siteElement by calling HB.parseTemplateVar for
  // each {{...}} entry in the template
  function renderTemplate(html, siteElement) {
    return html.replace(/\{\{(.*?)\}\}/g, function (match, value) {
      return parseTemplateVar(value, siteElement);
    });
  }

  // TODO -> base.templating (should be inner)
  // Parses the value passed in in {{...}} for a template (which basically does an eval on it)
  function parseTemplateVar(value, siteElement) {
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
    setTemplate,
    getTemplateByName,
    renderTemplate
  };

});


