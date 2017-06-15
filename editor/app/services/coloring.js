import Ember from 'ember';

/**
 * @class Coloring
 * Encapsulates all the magical logic related to color computations
 */
export default Ember.Service.extend({

  /**
   * Calculates brightness of the given color.
   * @param color {array} RGB/RGBA color components as array
   * @returns {number} real number from 0 to 1
   */
  brightness(color) {
    const rgb = Ember.copy(color);
    [0, 1, 2].forEach((i) => {
      const val = rgb[i] / 255;
      rgb[i] = val < 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
    });
    return ((0.2126 * rgb[0]) + (0.7152 * rgb[1]) + (0.0722 * rgb[2]));
  }

});
