/* globals one, ColorPicker */

import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  /**
   * @property
   */
  color: null,

  classNames: ['color-input'],
  classNameBindings: ['inFocus', 'isSelecting'],

  palette: Ember.inject.service(),
  recentColors: Ember.computed.alias('palette.recentColors'),
  siteColors: Ember.computed.alias('palette.colorPalette'),
  focusedColor: Ember.computed.alias('palette.focusedColor'),

  inFocus: false,
  isSelecting: false,

  click (event) {
    if (this.$(event.target).is('.color-preview')) {
      this.toggleProperty('inFocus');
    }
  },

  didRender () {
    $(document).on('click', this.closeColorPreview.bind(this));
  },

  willDestroyElement () {
    $(document).off('click', this.closeColorPreview.bind(this));
  },

  closeColorPreview (event) {
    if (this.get('inFocus') && !this.$(event.target).is('.color-preview') && !this.$(event.target).is('rect')) {
      this.set('inFocus', false);
    }
  },

  //-----------  Background Styling  -----------#

  cssStyle: function () {
    if (!this.get('color')) {
      return;
    }

    const color = one.color(this.get('color'));
    if (color && color.hex()) {
      return Ember.String.htmlSafe(`background-color: ${color.hex()}`);
    }
  }.property('color'),

  //-----------  RGB Observer  -----------#

  didInsertElement() {
    const defaultColor = 'ffffff';
    const color = this.get('color');
    if (!color) {
      this.set('color', defaultColor);
    }

    this.throttledSetRGB = _.throttle(() => {
      this.setRGB();
    }, 100);
    this.debouncedSetHex = _.debounce(() => {
      this.setHex();
    }, 150);
    this.debouncedUpdateRecent = _.debounce(() => {
      this.updateRecent();
    }, 100);
    this.setRGB();
  },

  rgbObserver: function () {
    if (this.throttledSetRGB) {
      this.throttledSetRGB();
    }
  }.observes('color'),

  setRGB() {
    // Only work with full colors, also, strip out any hash marks pasted in
    let hex = this.get('color');
    if (hex.length < 6) {
      return;
    } else if (hex.length > 6) {
      hex = hex.replace('#', '');
      hex = hex.substring(0, 6);
      this.set('color', hex);
    }

    let rgb = this.getRGB();

    this.set('rVal', parseInt(rgb[1], 16));
    this.set('gVal', parseInt(rgb[2], 16));
    this.set('bVal', parseInt(rgb[3], 16));
  },

  //-----------  Hex/RGB Conversion  -----------#

  getRGB() {
    let hex = this.get('color');
    let shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
    hex = hex.replace(shorthandRegex, (m, r, g, b) => r + r + g + g + b + b
    );
    let result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result || ['ffffff', 'ff', 'ff', 'ff'];
  },

  hexObserver: function () {
    if (this.debouncedSetHex) {
      this.debouncedSetHex();
    }
  }.observes('rVal', 'gVal', 'bVal', 'hexVal'),

  setHex() {
    const r = parseInt(this.get('rVal'));
    const g = parseInt(this.get('gVal'));
    const b = parseInt(this.get('bVal'));

    const gradRGB = this.get('rgb');
    const inputRGB = {r, g, b};

    if (JSON.stringify(gradRGB) !== JSON.stringify(inputRGB)) {
      const hex = ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
      this.gradient.setHex(`#${hex}`);
    }
  },

  //-----------  Wrap Color Gradient  -----------#

  setupGradient: function () {
    const obj = this;

    ColorPicker.fixIndicators(
      obj.$('.slider-indicator')[0],
      obj.$('.gradient-indicator')[0]
    );

    this.gradient = new ColorPicker(
      obj.$('.slider')[0],
      obj.$('.gradient')[0],

      function (hex, hsv, rgb, pickerCoordinate, sliderCoordinate) {
        ColorPicker.positionIndicators(
          obj.$('.slider-indicator')[0],
          obj.$('.gradient-indicator')[0],
          sliderCoordinate,
          pickerCoordinate
        );

        obj.set('color', hex.substring(1));
        return obj.set('rgb', rgb);
      }
    );

    return this.gradient.setHex(`#${this.get('color')}`);
  }.on('didInsertElement'),

  //-----------  Push 'Recent' Changes to Controller  -----------#

  updateRecent() {
    let color = this.get('color');
    let recent = this.get('recentColors');

    if (recent.indexOf(color) <= -1) {
      recent.shiftObject();
      recent.pushObject(this.get('color'));
      this.set('recentColors', recent);
    }
  },

  recentObserver: function () {
    if (this.debouncedUpdateRecent) {
      this.debouncedUpdateRecent();
    }
  }.observes('color'),

  //-----------  Screenshot Eye-Dropper  -----------#

  eyeDropper: function () {
    if (this.get('isSelecting')) {
      return $('.preview-image-for-colorpicker').dropperTrios({
        selector: $('.preview-image-for-colorpicker'),
        clickCallback: color => {
          this.set('color', color);
          this.sendAction('eyeDropperSelected');
          this.set('isSelecting', false);
          $('.preview-image-for-colorpicker').dropperClean();
        }
      });
    } else {
      $('.preview-image-for-colorpicker').dropperClean();
    }
  }.observes('isSelecting').on('didInsertElement'),

  togglePreview: function () {
    const siteSecret = hellobar('base.site').secret();
    if (this.get('isSelecting')) {
      // Hide the preview frame for Modal and Takeovers so that they can select colors
      return $(`\#${siteSecret}-container.HB-Takeover, \#${siteSecret}-container.HB-Modal`).fadeOut();
    } else {
      // Show the Modal and Takeover in case it was hidden
      return $(`\#${siteSecret}-container.HB-Takeover, \#${siteSecret}-container.HB-Modal`).fadeIn();
    }
  }.observes('isSelecting'),

  //-----------  Actions  -----------#

  resetOnDestruction: function () {
    $('.preview-image-for-colorpicker').dropperClean();
    this.set('isSelecting', false);
    this.togglePreview();
  }.on('willDestroyElement'),

  actions: {
    toggleSelecting() {
      this.toggleProperty('isSelecting');
    }
  }
});
