// import _ from 'lodash/lodash';
// import SpectrumColorPickerComponent from 'ember-spectrum-color-picker/components/spectrum-color-picker';
import Ember from 'ember';

export default Ember.Component.extend({
  classNames: 'spectrum-color-picker',

  containerClassName: 'spectrum-color-picker-container',

  replacerClassName: 'spectrum-color-picker-replacer',

  tagName: 'input',

  color: null,

  flatMode: false,

  allowEmpty: false,

  disabled: false,

  showInput: true,

  showAlpha: false,

  showInitial: false,

  showButtons: true,

  showPalette: true,

  showPaletteOnly: false,

  palette: [
    ['#000000'], ['#ffffff'],
    ['#FF0000'], ['#777777'],
    ['#337ab7'], ['#5cb85c'],
    ['#5bc0de'], ['#f0ad4e'],
    ['#d9534f'], ['#a37ab7']
  ],

  togglePaletteOnly: false,

  showSelectionPalette: false,

  maxSelectionSize: 7,

  hideAfterPaletteSelect: false,

  preferredFormat: 'hex',

  moveFiresChange: true,

  clickoutFiresChange: true,

  chooseText: 'Apply',

  cancelText: 'Cancel',

  togglePaletteMoreText: 'More',

  togglePaletteLessText: 'Less',

  appendTo: 'body',

  localStorageKey: 'spectrum-color-picker',

  updatePalette: Ember.observer('palette', function () {
    this.$().spectrum('option', 'palette', this.get('palette'));
  }),

  updatePicker: Ember.observer('color', function () {
    this.$().spectrum('set', this.get('color'));
  }),

  updateDisabled: Ember.observer('disabled', function () {
    this.$().spectrum(this.get('disabled') ? 'disable' : 'enable');
  }),

  didInsertElement() {
    let palette = this.get('palette');
    let opts = {
      color: this.get('color'),
      flat: this.get('flatMode'),
      containerClassName: this.get('containerClassName'),
      replacerClassName: this.get('replacerClassName'),
      allowEmpty: this.get('allowEmpty'),
      disabled: this.get('disabled'),
      showInput: this.get('showInput'),
      showAlpha: this.get('showAlpha'),
      showInitial: this.get('showInitial'),
      showButtons: this.get('showButtons'),
      showPalette: this.get('showPalette'),
      showPaletteOnly: this.get('showPaletteOnly'),
      palette: (typeof(palette) === 'string') ? JSON.parse(palette) : palette,
      togglePaletteOnly: this.get('togglePaletteOnly'),
      showSelectionPalette: this.get('showSelectionPalette'),
      maxSelectionSize: this.get('maxSelectionSize'),
      hideAfterPaletteSelect: this.get('hideAfterPaletteSelect'),
      preferredFormat: this.get('preferredFormat'),
      clickoutFiresChange: this.get('clickoutFiresChange'),
      chooseText: this.get('chooseText'),
      cancelText: this.get('cancelText'),
      togglePaletteMoreText: this.get('togglePaletteMoreText'),
      togglePaletteLessText: this.get('togglePaletteLessText'),
      appendTo: this.get('appendTo'),
      localStorageKey: this.get('localStorageKey')
    };
    let self = this;
    let updateFunction = function (newColor) {
      let color = newColor ? newColor.toString() : null;
      let onChange = self.get('onChange');

      if (!self.isDestroyed) {
        color = color.replace('#', '');
        color = color.substring(0, 6);
        self.set('color', color);
      }

      color = color.replace('#', '');
      color = color.substring(0, 6);
      self.set('color', color);

      if (onChange) {
        onChange(color);
      }
    };

    opts.change = updateFunction;

    if (this.get('moveFiresChange')) {
      opts.move = updateFunction;
    }

    // Move Event
    let onMove = self.get('onMove');
    if (onMove) {
      opts.move = function (newColor) {
        onMove(newColor ? newColor.toString() : null);
      };
    }

    // Hide Event
    let onHide = self.get('onHide');
    if (onHide) {
      opts.hide = function (newColor) {
        onHide(newColor ? newColor.toString() : null);
      };
    }

    // Show Event
    let onShow = self.get('onShow');
    if (onShow) {
      opts.show = function (newColor) {
        onShow(newColor ? newColor.toString() : null);
      };
    }

    let hidePicker = () => {
      this.$().spectrum('hide');
    };

    let iframeClickHandler = () => {
      let preview = $('#hellobar-preview-container iframe').prop('contentDocument');
      $(preview).on('click', hidePicker);
    };

    // Close On Clicking iframe
    let preview = $('#hellobar-preview-container iframe').prop('contentDocument');
    $(preview).on('click', hidePicker);

    // Close On Clicking re-rendered iframe
    let container = document.getElementById('hellobar-preview-container');
    container.addEventListener('DOMNodeInserted', () => {
        setTimeout(iframeClickHandler, 10);
    });

    this.$().spectrum(opts);
  },

  willDestroyElement: function() {
    this.$().spectrum('destroy');

    // Unbind iframe Click Event
    let preview = $('#hellobar-preview-container iframe').prop('contentDocument');
    $(preview).off('click');
  }
});
