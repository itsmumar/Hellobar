import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['preview-area'],

  inlineEditing: Ember.inject.service(),
  imaging: Ember.inject.service(),

  model: null,
  isMobile: null,

  didInsertElement() {
    HBEditor.addPreviewInjectionListener(container => {
        this.get('inlineEditing').initializeInlineEditing(this.get('model.type'));
      }
    );
  },

  //-----------  Template Properties  -----------#

  isPushed: Ember.computed.alias('model.pushes_page_down'),
  barSize: Ember.computed.alias('model.size'),
  barPosition: Ember.computed.alias('model.placement'),
  elementType: Ember.computed.alias('model.type'),
  isCustom: Ember.computed.equal('model.type', 'Custom'),

  previewStyleString: (function () {
    return `background-image: url(${ this.get('previewImageURL') })`;
  }).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile'),

  previewImageURL: (function () {
    if (this.get('isMobile')) {
      return `${this.get('model.site_preview_image_mobile')}`;
    } else {
      return `${this.get('model.site_preview_image')}`;
    }
  }).property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile'),


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
