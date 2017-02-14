import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['preview-area'],

  applicationController: Ember.inject.controller('application'),
  inlineEditing: Ember.inject.service(),
  imaging: Ember.inject.service(),

  model: null,

  isMobile: null,

  init() {
    this._super(...arguments);
    console.log('init called');
    console.log($);
    console.log($('.preview-image'));

    // this.hideLoadingMessage();
    $('.preview-image').on('load', function() {
      console.log('loaded');
      $('.loading-message').addClass('hidden');
    });
  },

  didInsertElement() {
    HB.addPreviewInjectionListener(container => {
        this.get('inlineEditing').initializeInlineEditing(this.get('model.type'));
      }
    );

    Ember.run.next(() => {
      this.detectColorPalette();

      // assume we can hide loading message when Preview component is loaded
      // setTimeout(this.hideLoadingMessage, 1500);
    });
  },

  //-----------  Template Properties  -----------#

  isPushed: Ember.computed.alias('model.pushes_page_down'),
  barSize: Ember.computed.alias('model.size'),
  barPosition: Ember.computed.alias('model.placement'),
  elementType: Ember.computed.alias('model.type'),
  isCustom: Ember.computed.equal('model.type', 'Custom'),

  previewStyleString: (function () {
    if (this.get('isMobile')) {
      return `background-image:url(${this.get('model.site_preview_image_mobile')})`;
    } else {
      return `background-image:url(${this.get('model.site_preview_image')})`;
    }
  }).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile'),

  previewImageURL: (function () {
    if (this.get('isMobile')) {
      return `${this.get('model.site_preview_image_mobile')}`;
    } else {
      return `${this.get('model.site_preview_image')}`;
    }
  }).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile'),

  //-----------  Color Intelligence  -----------#

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

  hideLoadingMessage () {
    // $('#hellobar-preview-container .loading-message').addClass('hidden');

    // hide loading message when preview image has loaded
    // $('.preview-image').on('load', function () {
  },

  previewContainerCssClasses: (function () {
    let classes = [];
    classes.push(this.get('barPosition'));
    classes.push(this.get('barSize'));
    classes.push(this.get('elementType').toLowerCase());
    this.get('isPushed') && classes.push('is-pushed');
    this.get('isMobile') && classes.push('hellobar-preview-container-mobile');
    return classes.join(' ');
  }).property('barPosition', 'barSize', 'elementType', 'isPushed', 'isMobile'),

  componentBackground: function () {
    const backgroundColor = '#f6f6f6';
    if (this.get('isMobile')) {
      const phoneImageUrl = this.get('imaging').imagePath('iphone-bg.png');
      return `${backgroundColor} url(${phoneImageUrl}) center center no-repeat`;
    } else {
      return backgroundColor;
    }
  }.property('isMobile')

});
