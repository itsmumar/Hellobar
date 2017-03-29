import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['color-select'],
  classNameBindings: ['inFocus', 'isSelecting'],

  inFocus: false,
  isSelecting: false,

  //-----------  Background Styling  -----------#

  cssStyle: ( function () {
    let color = one.color(this.get('color'));
    if (color && color.hex()) {
      return Ember.String.htmlSafe(`background-color: ${color.hex()}`);
    }
  }).property('color'),

  //-----------  RGB Observer  -----------#

  didInsertElement() {
    return this.setRGB();
  },

  setRGB: Ember.throttledObserver('color', 75, function () {
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
      return this.set('bVal', parseInt(rgb[3], 16));
    }
  ),

  //-----------  Hex/RGB Conversion  -----------#

  getRGB() {
    let hex = this.get('color');
    let shorthandRegex = /^#?([a-f\d])([a-f\d])([a-f\d])$/i;
    hex = hex.replace(shorthandRegex, (m, r, g, b) => r + r + g + g + b + b
    );
    let result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    return result || ['ffffff', 'ff', 'ff', 'ff'];
  },

  setHex: Ember.debouncedObserver('rVal', 'gVal', 'bVal', 'hexVal', 150, function () {
      let r = parseInt(this.get('rVal'));
      let g = parseInt(this.get('gVal'));
      let b = parseInt(this.get('bVal'));

      let gradRGB = this.get('rgb');
      let inputRGB = {r, g, b};

      if (JSON.stringify(gradRGB) !== JSON.stringify(inputRGB)) {
        let hex = ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
        return this.gradient.setHex(`#${hex}`);
      }
    }
  ),

  //-----------  Wrap Color Gradient  -----------#

  setupGradient: ( function () {
    let obj = this;

    ColorPicker.fixIndicators(
      obj.$('.slider-indicator')[0],
      obj.$('.gradient-indicator')[0]
    );

    this.gradient = ColorPicker(
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
  }).on('didInsertElement'),

  //-----------  Push 'Recent' Changes to Controller  -----------#

  updateRecent: Ember.debouncedObserver('color', 75, function () {
      let color = this.get('color');
      let recent = this.get('recentColors');

      if (recent.indexOf(color) <= -1) {
        recent.shiftObject();
        recent.pushObject(this.get('color'));
        return this.set('recentColors', recent);
      }
    }
  ),

  //-----------  Screenshot Eye-Dropper  -----------#

  eyeDropper: ( function () {
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
  }).observes('isSelecting').on('didInsertElement'),

  togglePreview: ( function () {
    if (this.get('isSelecting')) {
      // Hide the preview frame for Modal and Takeovers so that they can select colors
      // TODO REFACTOR window.HB_PS global usage here
      return $(`\#${window.HB_PS}-container.HB-Takeover, \#${window.HB_PS}-container.HB-Modal`).fadeOut();
    } else {
      // Show the Modal and Takeover in case it was hidden
      // TODO REFACTOR window.HB_PS global usage here
      return $(`\#${window.HB_PS}-container.HB-Takeover, \#${window.HB_PS}-container.HB-Modal`).fadeIn();
    }
  }).observes('isSelecting'),

  //-----------  Component State Switching  -----------#

  observeSiblings: ( function () {
    if (this.get('inFocus') && (this.get('focusedColor') !== this.get('elementId'))) {
      this.set('isSelecting', false);
      return this.set('inFocus', false);
    }
  }).observes('focusedColor'),

  //-----------  Actions  -----------#

  resetOnDestruction: ( function () {
    $('.preview-image-for-colorpicker').dropperClean();
    this.set('isSelecting', false);
    return this.togglePreview();
  }).on('willDestroyElement'),

  actions: {

    toggleFocus() {
      if (!(this.get('inFocus') && $(`\#${this.get('elementId')} input:focus`).length)) {
        this.set('focusedColor', this.get('elementId'));
        this.set('isSelecting', false);
        return this.toggleProperty('inFocus');
      }
    },

    toggleSelecting() {
      return this.toggleProperty('isSelecting');
    }
  }
});
