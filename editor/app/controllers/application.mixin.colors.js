import Ember from 'ember';

// GLOBALS: one object (https://github.com/One-com/one-color)

export default Ember.Mixin.create({

  colorPalette: [],
  focusedColor: null,

  setSiteColors: function () {

    const brightness = (color) => {
      let rgb = Ember.copy(color);
      [0, 1, 2].forEach((i) => {
        let val = rgb[i] / 255;
        rgb[i] = val < 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
      });
      return ((0.2126 * rgb[0]) + (0.7152 * rgb[1]) + (0.0722 * rgb[2]));
    };

    if (this.get('model.id') || window.elementToCopyID) {
      return;
    }

    const colorPalette = this.get('colorPalette');
    const dominantColor = this.get('dominantColor');

    if (Ember.isEmpty(colorPalette) || Ember.isEmpty(dominantColor)) {
      return;
    }

    //----------- Primary Color  -----------#

    let primaryColor = dominantColor;

    for (let i = 0; i < colorPalette.length; i++) {
      const color = colorPalette[i];
      if (Math.abs(color[0] - color[1]) > 10 || Math.abs(color[1] - color[2]) > 10 || Math.abs(color[0] - color[2]) > 10) {
        primaryColor = color;
        break;
      }
    }

    this.set('model.background_color', one.color(primaryColor).hex().replace('#', ''));

    //----------- Other Colors  -----------#

    const white = 'ffffff';
    const black = '000000';

    if (brightness(primaryColor) < 0.5) {
      this.setProperties({
        'model.text_color': white,
        'model.button_color': white,
        'model.link_color': one.color(primaryColor).hex().replace('#', '')
      });
    } else {
      colorPalette.sort((a, b) => {
          return brightness(a) - brightness(b);
        }
      );

      const darkest = brightness(colorPalette[0]) >= 0.5 ? black : one.color(colorPalette[0]).hex().replace('#', '');

      this.setProperties({
        'model.text_color': darkest,
        'model.button_color': darkest,
        'model.link_color': white
      });
    }
  }.observes('colorPalette')

});