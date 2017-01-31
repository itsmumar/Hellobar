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
    Ember.run.next(() => {
      this.detectColorPalette();
    });
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

    const property = cssProperty();
    const css = {
      'border-top-width': '0',
      'border-bottom-width': '0'
    };
    if (property) {
      const pushHeight = (this.get('model.type') === 'Bar' && this.get('model.pushes_page_down')) ? height(this.get('model.size')) : '0';
      css[property] = pushHeight;
    }
    return $('#hellobar-preview-container .preview-image').css(css);

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

        this.set('applicationController.dominantColor', dominantColor);
        this.set('applicationController.colorPalette', colorPalette);
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

});
