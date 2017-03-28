hellobar.defineModule('elements.bar', [], function() {

  // TODO can we move this to elements.class.bar?

  // TODO -> elements.bars
  function barSizeCssClass(size) {
    if (size === 'large' || size === 'regular') {
      return size;
    }
    var sizeAsInt = parseInt(size);
    if (sizeAsInt < 40) {
      return 'regular';
    } else if (sizeAsInt >= 40 && sizeAsInt < 70) {
      return 'large';
    } else {
      return 'x-large';
    }
  }

  // TODO -> elements.bars
  function barHeight(size) {
    switch (size) {
      case 'large':
        return '50px';
      case 'regular':
        return '30px';
      default:
        return size + 'px';
    }
  }

  const module = {
    initialize: () => null
  };

  return module;

});
