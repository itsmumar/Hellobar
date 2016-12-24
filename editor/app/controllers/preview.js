import Ember from 'ember';

export default Ember.Controller.extend({

  applicationController: Ember.inject.controller('application'),

  inlineEditing: Ember.inject.service(),

  init() {
    HB.addPreviewInjectionListener(container => {
        this.adjustPushHeight();
        return this.get('inlineEditing').initializeInlineEditing(this.get('model.type'));
      }
    );
  },

  //-----------  Template Properties  -----------#

  isMobile: Ember.computed.alias('applicationController.isMobile'),
  isPushed: Ember.computed.alias('model.pushes_page_down'),
  barSize: Ember.computed.alias('model.size'),
  barPosition: Ember.computed.alias('model.placement'),
  elementType: Ember.computed.alias('model.type'),
  isCustom: Ember.computed.equal('model.type', 'Custom'),


  previewStyleString: ( function () {
    if (this.get('isMobile')) {
      return `background-image:url(${this.get('model.site_preview_image_mobile')})`;
    } else {
      return `background-image:url(${this.get('model.site_preview_image')})`;
    }
  }).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile'),

  previewImageURL: ( function () {
    if (this.get('isMobile')) {
      return `${this.get('model.site_preview_image_mobile')}`;
    } else {
      return `${this.get('model.site_preview_image')}`;
    }
  }).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile'),

  //-----------  Color Intelligence  -----------#

  colorPalette: Ember.computed.alias('applicationController.colorPalette'),

  setSiteColors: ( function () {
    if (this.get('model.id') || window.elementToCopyID) {
      return false;
    }

    let colorPalette = this.get('colorPalette');
    let dominantColor = this.get('dominantColor');

    if (Ember.isEmpty(colorPalette) || Ember.isEmpty(dominantColor)) {
      return false;
    }

    //----------- Primary Color  -----------#

    let primaryColor = dominantColor;

    for (let i = 0; i < colorPalette.length; i++) {
      let color = colorPalette[i];
      if (Math.abs(color[0] - color[1]) > 10 || Math.abs(color[1] - color[2]) > 10 || Math.abs(color[0] - color[2]) > 10) {
        primaryColor = color;
        break;
      }
    }

    this.set('model.background_color', one.color(primaryColor).hex().replace('#', ''));

    //----------- Other Colors  -----------#

    let white = 'ffffff';
    let black = '000000';

    if (this.brightness(primaryColor) < 0.5) {
      return this.setProperties({
        'model.text_color': white,
        'model.button_color': white,
        'model.link_color': one.color(primaryColor).hex().replace('#', '')
      });
    } else {
      colorPalette.sort((a, b) => {
          return this.brightness(a) - this.brightness(b);
        }
      );

      let darkest = this.brightness(colorPalette[0]) >= 0.5 ? black : one.color(colorPalette[0]).hex().replace('#', '');

      return this.setProperties({
        'model.text_color': darkest,
        'model.button_color': darkest,
        'model.link_color': white
      });
    }
  }).observes('colorPalette'),

  brightness(color) {
    let rgb = Ember.copy(color);

    [0, 1, 2].forEach(function (i) {
      let val = rgb[i] / 255;
      return rgb[i] = val < 0.03928 ? val / 12.92 : Math.pow((val + 0.055) / 1.055, 2.4);
    });

    return ((0.2126 * rgb[0]) + (0.7152 * rgb[1]) + (0.0722 * rgb[2]));
  },


  adjustPushHeight() {
    let height = size => {
      switch (size) {
        case 'large':
          return '50px';
        case 'regular':
          return '30px';
        default:
          return size + 'px';
      }
    };
    let cssProperty = () => {
      switch (this.get('model.placement')) {
        case 'bar-top':
          return 'border-top-width';
        case 'bar-bottom':
          return 'border-bottom-width';
        default:
          return null;
      }
    };

    let property = cssProperty();
    if (property) {
      let css = {
        'border-top-width': '0',
        'border-bottom-width': '0'
      };
      let pushHeight = this.get('model.pushes_page_down') ? height(this.get('model.size')) : '0';
      css[property] = pushHeight;
      return $('#hellobar-preview-container .preview-image').css(css);
    }
  },

  // TODO decide when we need to call this method
  afterElementInserted() {
    function formatRGB(rgbArray) {
      rgbArray.push(1);
      return rgbArray;
    }

    let colorThief = new ColorThief();
    let image = $('.preview-image-for-colorpicker').get(0);

    return imagesLoaded(image, () => {
        let dominantColor = formatRGB(colorThief.getColor(image));
        let colorPalette = colorThief.getPalette(image, 4).map(color => formatRGB(color));

        this.set('controller.dominantColor', dominantColor);
        return this.set('controller.colorPalette', colorPalette);
      }
    );
  },

  previewContainerCssClasses: (function() {
    let classes = [];
    classes.push(this.get('barPosition'));
    classes.push(this.get('barSize'));
    classes.push(this.get('elementType'));
    this.get('isPushed') && classes.push('is-pushed');
    this.get('isMobile') && classes.push('hellobar-preview-container-mobile');
    return classes.join(' ');
  }).property('barPosition', 'barSize', 'elementType', 'isPushed', 'isMobile'),

  actions: {
    changeCustomHtmlCode(source) {
      this.setProperties({
        'model.custom_html': source.customHtml || '',
        'model.custom_css': source.customCss || '',
        'model.custom_js': source.customJs || ''
      });
    }
  }
});
