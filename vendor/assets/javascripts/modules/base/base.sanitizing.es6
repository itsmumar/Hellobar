hellobar.defineModule('base.sanitizing', [], function() {

  // TODO -> base.sanitizing
  // Takes each string value in the siteElement and escapes HTML < > chars
  // with the matching symbol
  function sanitize(siteElement, whitelist) {
    for (var k in siteElement){
      if (siteElement.hasOwnProperty(k) && siteElement[k]) {
        if (siteElement[k].replace && !(whitelist && (whitelist.indexOf(k) >= 0))) {
          siteElement[k] = siteElement[k].replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g, '&quot;');
        } else if(!Array.isArray(siteElement[k])) {
          siteElement[k] = sanitize(siteElement[k]);
        }
      }
    }
    return siteElement;
  }

  return {
    sanitize
  };

});
