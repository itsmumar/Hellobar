import Ember from 'ember';

// GLOBALS: one object (https://github.com/One-com/one-color), ColorThief

export default Ember.Mixin.create({

  coloring: Ember.inject.service(),

  colorPalette: [],
  focusedColor: null,

  setSiteColors: function () {
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

    if (this.get('coloring').brightness(primaryColor) < 0.5) {
      this.setProperties({
        'model.text_color': white,
        'model.button_color': white,
        'model.link_color': one.color(primaryColor).hex().replace('#', '')
      });
    } else {
      colorPalette.sort((a, b) => this.get('coloring').brightness(a) - this.get('coloring').brightness(b));

      const darkest = this.get('coloring').brightness(colorPalette[0]) >= 0.5 ? black : one.color(colorPalette[0]).hex().replace('#', '');

      this.setProperties({
        'model.text_color': darkest,
        'model.button_color': darkest,
        'model.link_color': white
      });
    }
  },

  detectColorPalette() {
    function formatRGB(rgbArray) {
      rgbArray.push(1);
      return rgbArray;
    }

    const colorThief = new ColorThief();
    const image = $('.preview-image-for-colorpicker').get(0);

    return imagesLoaded(image, () => {
      const dominantColor = formatRGB(colorThief.getColor(image));
      const colorPalette = colorThief.getPalette(image, 4).map(color => formatRGB(color));

      this.set('dominantColor', dominantColor);
      this.set('colorPalette', colorPalette);
    });
  }


});
