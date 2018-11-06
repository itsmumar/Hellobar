import Ember from 'ember';
import _ from 'lodash/lodash';
import { VIEW_DESKTOP, VIEW_TABLET, VIEW_MOBILE } from '../../constants';

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

  bus: Ember.inject.service(),
  inlineEditing: Ember.inject.service(),
  imaging: Ember.inject.service(),
  preview: Ember.inject.service(),
  theming: Ember.inject.service(),
  fonts: Ember.inject.service(),
  froalaFonts: Ember.inject.service(),

  availableFonts: Ember.computed.alias('fonts.availableFonts'),
  isNotElementSelected: Ember.computed.equal('model.type', null),
  isNotGoalSelected: Ember.computed.equal('model.element_subtype', null),

  _shouldSkipPreviewUpdate: false,


  didInsertElement() {
    this.get('preview').addPreviewInjectionListener(() => {
      this.get('inlineEditing').initializeInlineEditing(this.get('model.type'));
    });
    this.get('bus').subscribe('hellobar.core.preview.render', () => {
      this.renderPreview();
    });
    if (this.get('model')) {
      Ember.run.next(() => {
        this.renderPreview();
      });
    }
  },

  //-----------  Template Properties  -----------#

  isPushed: Ember.computed.alias('model.pushes_page_down'),
  barSize: Ember.computed.alias('model.size'),
  barPosition: Ember.computed.alias('model.placement'),
  elementType: Ember.computed.alias('model.type'),

  previewStyleString: (function () {
    return `background-image: url(${ this.get('previewImageURL') })`;
  }).property('previewImageURL'),

  previewImageURL: function () {
    switch (this.get('viewMode')) {
      case VIEW_DESKTOP:
        return `${this.get('model.site_preview_image')}`;
      case VIEW_TABLET:
        return `${this.get('model.site_preview_image_tablet')}`;
      case VIEW_MOBILE:
        return `${this.get('model.site_preview_image_mobile')}`;
      default:
        return `${this.get('model.site_preview_image')}`;
    }
  }.property('viewMode', 'model.site_preview_image', 'model.site_preview_image_mobile', 'model.site_preview_image_tablet'),


  previewContainerCssClasses: function () {
    let classes = [];

    classes.push(this.get('barPosition'));
    classes.push(this.get('barSize'));
    if(this.get('elementType')) {
      classes.push(this.get('elementType').toLowerCase());
    }
    if (this.get('isPushed')) {
      classes.push('is-pushed');
    }
    if (this.get('isMobile')) {
      classes.push('hellobar-preview-container-mobile');
    }

    return classes.join(' ');
  }.property('barPosition', 'barSize', 'elementType', 'isPushed', 'isMobile'),

  componentBackground: function () {
    const backgroundColor = '#f1f0f0';

    if (this.get('isMobile')) {
      const phoneImageUrl = this.get('imaging').imagePath('iphone-bg.png');
      return `${backgroundColor} url(${phoneImageUrl}) center center no-repeat`;
    } else {
      return backgroundColor;
    }
  }.property('isMobile'),

  // ----- Preview updating triggers

  onModelUpdated: function () {
    this.set('model.isSaved', false);
    this.renderPreview();
  }.observes(
    'model',
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
    'model.cta_border_color',
    'model.cta_border_width',
    'model.cta_border_radius',
    'model.cta_height',
    'model.caption',
    'model.content',
    'model.closable',
    'model.element_subtype',
    'model.email_placeholder',
    'model.font_id',
    'model.headline',
    'model.image_placement',
    'model.image_opacity',
    'model.image_url',
    'model.image_overlay_color',
    'model.image_overlay_opacity',
    'model.link_color',
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
    'model.show_optional_caption',
    'model.show_optional_content',
    'model.show_branding',
    'model.sound',
    'model.size',
    'model.text_color',
    'model.theme_id',
    'model.trigger_color',
    'model.trigger_icon_color',
    'model.type',
    'model.use_question',
    'model.use_default_image',
    'model.view_condition',
    'model.wiggle_button',
    'model.text_field_border_color',
    'model.text_field_border_width',
    'model.text_field_border_radius',
    'model.text_field_text_color',
    'model.text_field_background_color',
    'model.text_field_background_opacity',
    'model.text_field_font_size',
    'model.text_field_font_family',
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
    const currentTheme = this.get('theming.currentTheme');
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
        thank_you_text: 'Thanks for signing up!',
        wiggle_button: this.get('model.wiggle_button'),
        wiggle_wait: 0,
        font: font.value,
        fonts: this.get('froalaFonts').googleFonts(),
        google_font: font.google_font,
        theme: currentTheme,
        branding_url: 'https://www.hellobar.com?sid=preview'
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
