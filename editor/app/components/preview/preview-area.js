import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  /**
   * @property {boolean} If the preview should work in mobile mode
   */
  isMobile: null,

  classNames: ['preview-area'],

  inlineEditing: Ember.inject.service(),
  imaging: Ember.inject.service(),
  preview: Ember.inject.service(),
  fonts: Ember.inject.service(),

  availableFonts: Ember.computed.alias('fonts.availableFonts'),

  _shouldSkipPreviewUpdate: false,

  didInsertElement() {
    this.get('preview').addPreviewInjectionListener(() => {
      this.get('inlineEditing').initializeInlineEditing(this.get('model.type'));
    });
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

  previewImageURL: function () {
    if (this.get('isMobile')) {
      return `${this.get('model.site_preview_image_mobile')}`;
    } else {
      return `${this.get('model.site_preview_image')}`;
    }
  }.property('isMobile', 'model.site_preview_image', 'model.site_preview_image_mobile'),


  previewContainerCssClasses: function () {
    let classes = [];

    classes.push(this.get('barPosition'));
    classes.push(this.get('barSize'));
    classes.push(this.get('elementType').toLowerCase());

    this.get('isPushed') && classes.push('is-pushed');
    this.get('isMobile') && classes.push('hellobar-preview-container-mobile');

    return classes.join(' ');
  }.property('barPosition', 'barSize', 'elementType', 'isPushed', 'isMobile'),

  componentBackground: function () {
    const backgroundColor = '#f6f6f6';

    if (this.get('isMobile')) {
      const phoneImageUrl = this.get('imaging').imagePath('iphone-bg.png');
      return `${backgroundColor} url(${phoneImageUrl}) center center no-repeat`;
    } else {
      return backgroundColor;
    }
  }.property('isMobile'),

  // ----- Preview updating triggers

  onModelUpdated: function () {
    this.renderPreview();
  }.observes(
    'model.answer1',
    'model.answer1caption',
    'model.answer1link_text',
    'model.answer1response',
    'model.answer2',
    'model.answer2caption',
    'model.answer2link_text',
    'model.answer2response',
    'model.background_color',
    'model.border_color',
    'model.button_color',
    'model.caption',
    'model.closable',
    'model.element_subtype',
    'model.email_placeholder',
    'model.font_id',
    'model.headline',
    'model.image_placement',
    'model.image_url',
    'model.link_color',
    'model.link_style',
    'model.link_text',
    'model.name_placeholder',
    'model.notification_delay',
    'model.phone_country_code',
    'model.phone_number',
    'model.placement',
    'model.pushes_page_down',
    'model.question',
    'model.remains_at_top',
    'model.settings.buffer_message',
    'model.settings.buffer_url',
    'model.settings.collect_names',
    'model.settings.fields_to_collect',
    'model.settings.link_url',
    'model.settings.message_to_tweet',
    'model.settings.pinterest_description',
    'model.settings.pinterest_full_name',
    'model.settings.pinterest_image_url',
    'model.settings.pinterest_url',
    'model.settings.pinterest_user_url',
    'model.settings.twitter_handle',
    'model.settings.url_to_like',
    'model.settings.url_to_plus_one',
    'model.settings.url_to_share',
    'model.settings.url_to_tweet',
    'model.settings.url',
    'model.settings.use_location_for_url',
    'model.show_after_convert',
    'model.show_branding',
    'model.sound',
    'model.size',
    'model.text_color',
    'model.theme_id',
    'model.trigger_color',
    'model.type',
    'model.use_question',
    'model.view_condition',
    'model.wiggle_button',
    'model.custom_html',
    'model.custom_css',
    'model.custom_js',
    'isFullscreen',
    'isMobile'
  ),

  onAnimatedChanged: function () {
    this.renderPreview();
  }.observes('model.animated'),

  // ----- Skipping update

  requestPreviewUpdateSkipping() {
    this._shouldSkipPreviewUpdate = true;
  },

  // ----- Preview rendering functions

  renderPreview(withDelay = true) {
    if (this._shouldSkipPreviewUpdate) {
      this._shouldSkipPreviewUpdate = false;
    } else {
      return Ember.run.debounce(this, this._doRenderPreview, withDelay ? 500 : 0);
    }
  },

  _doRenderPreview(withAnimations = false) {
    const getFont = () => {
      const fontId = this.get('model.font_id');
      return _.find(this.get('availableFonts'), font => font.id === fontId);
    };
    const font = getFont();
    const currentTheme = this.get('currentTheme');
    let previewElement = $.extend({}, this.get('model'), {
        animated: withAnimations && this.get('model.animated'),
        hide_destination: true,
        open_in_new_window: this.get('model.open_in_new_window'),
        primary_color: this.get('model.background_color'),
        pushes_page_down: this.get('model.pushes_page_down'),
        remains_at_top: this.get('model.remains_at_top'),
        secondary_color: this.get('model.button_color'),
        show_border: false,
        size: this.get('model.size'),
        subtype: this.get('model.element_subtype'),
        tab_side: 'right',
        template_name: (this.get('model.type') || 'bar').toLowerCase() + '_' + (this.get('model.element_subtype') || 'traffic'),
        thank_you_text: 'Thank you for signing up!',
        wiggle_button: this.get('model.wiggle_button'),
        wiggle_wait: 0,
        font: font.value,
        google_font: font.google_font,
        theme: currentTheme,
        branding_url: 'http://www.hellobar.com?sid=preview'
      }
    );

    previewElement = JSON.parse(JSON.stringify(previewElement));

    const elements = hellobar('elements');
    if (elements.removeAllSiteElements) {
      this.get('inlineEditing').cleanup();
      elements.removeAllSiteElements();
      elements.createAndAddToPage(previewElement);
    }
  }

});
