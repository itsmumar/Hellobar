import Ember from 'ember';

// GLOBALS: one object (https://github.com/One-com/one-color), ColorThief
const one = window.one;
const ColorThief = window.ColorThief;

/**
 * @class Palette
 * Encapsulates color set used in editor
 */
export default Ember.Service.extend({

  coloring: Ember.inject.service(),

  /**
   * Focused color (used in color selection)
   */
  focusedColor: null,

  /**
   * Recent colors used by user
   */
  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff'],

  /**
   * Colors detected from the site
   */
  siteColors: [],

  /**
   * Dominant site color
   */
  dominantColor: null,

  setSiteColors(modelHolder) {
    const colorPalette = this.get('siteColors');
    const dominantColor = this.get('dominantColor');

    if (Ember.isEmpty(colorPalette) || Ember.isEmpty(dominantColor)) {
      return;
    }

    //----------- Primary Color  -----------#

    const primaryColor = dominantColor;
    modelHolder.set('model.background_color', one.color(primaryColor).hex().replace('#', ''));

    //----------- Other Colors  -----------#

    const white = 'ffffff';
    const black = '000000';

    if (this.get('coloring').brightness(primaryColor) < 0.5) {
      const bright = one.color(primaryColor).hex().replace('#', '');

      modelHolder.setProperties({
        'model.text_color': white,
        'model.button_color': white,
        'model.link_color': bright,
        'model.trigger_color': bright,
        'model.trigger_icon_color': white
      });
    } else {
      colorPalette.sort((a, b) => this.get('coloring').brightness(a) - this.get('coloring').brightness(b));

      const darkest = this.get('coloring').brightness(colorPalette[0]) >= 0.5 ? black : one.color(colorPalette[0]).hex().replace('#', '');

      modelHolder.setProperties({
        'model.text_color': darkest,
        'model.button_color': darkest,
        'model.link_color': white,
        'model.trigger_color': darkest,
        'model.trigger_icon_color': white
      });
    }
  },

  detectColorPalette(modelHolder) {
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
      this.set('siteColors', colorPalette);

      if (!modelHolder.get('model.id') && !window.elementToCopyID && modelHolder.get('model.theme_id') === 'autodetect') {
        Ember.run.next(() => this.setSiteColors(modelHolder));
      }
    });
  }

});
