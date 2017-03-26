hellobar.defineModule('elements.bar', [], function () {

  // TODO -> base.templating
// Sets the template HTML. Note if you override getTemplate this will have
// no affect
  function setTemplate(type, html) {
    HB.templateHTML[type] = html;
  }


// TODO -> base.templating
// Returns the template HTML for the given siteElement. Most of the time the same
// template will be returned for the same siteElement. The values in {{}} are replaced with
// the values from the siteElement
//
// By default this just returns the HB.templateHTML variable for the given rule type
  function getTemplate(siteElement) {
    return HB.getTemplateByName(siteElement.template_name);
  }

  // TODO -> base.templating
  function getTemplateByName(templateName) {
    return HB.templateHTML[templateName];
  }

  // TODO -> base.templating
  // Renders the html template for the siteElement by calling HB.parseTemplateVar for
  // each {{...}} entry in the template
  function renderTemplate(html, siteElement) {
    return html.replace(/\{\{(.*?)\}\}/g, function (match, value) {
      return HB.parseTemplateVar(value, siteElement);
    });
  }

  // TODO -> base.templating (should be inner)
  // Parses the value passed in in {{...}} for a template (which basically does an eval on it)
  function parseTemplateVar(value, siteElement) {
    try {
      value = eval(value)
    } catch (e) {
      HB.isPreviewMode && console.log('Templating error: ', e);
    }
    if (value === undefined || value === null)
      return '';
    return value;
  }

  const module = {
    initialize: () => null
  };

  return module;

});


