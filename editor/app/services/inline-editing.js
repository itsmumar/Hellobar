/* globals siteID */

import Ember from 'ember';
import _ from 'lodash/lodash';
import geolocationHelper from './inline-editing.geolocation-helper';

// Froala Editor license key
const froalaKey = 'UA9B8E7A3dC3E3A2B10B6B5D5E4E3A2C-7KC1KXDF1INBh1KPe2TK==';

const emojisSet = [
  {code: '1f600', desc: 'Grinning face'},
  {code: '1f601', desc: 'Grinning face with smiling eyes'},
  {code: '1f602', desc: 'Face with tears of joy'},
  {code: '1f603', desc: 'Smiling face with open mouth'},
  {code: '1f604', desc: 'Smiling face with open mouth and smiling eyes'},
  {code: '1f605', desc: 'Smiling face with open mouth and cold sweat'},
  {code: '1f606', desc: 'Smiling face with open mouth and tightly-closed eyes'},
  {code: '1f607', desc: 'Smiling face with halo'},

  {code: '1f608', desc: 'Smiling face with horns'},
  {code: '1f609', desc: 'Winking face'},
  {code: '1f60a', desc: 'Smiling face with smiling eyes'},
  {code: '1f60b', desc: 'Face savoring delicious food'},
  {code: '1f60c', desc: 'Relieved face'},
  {code: '1f60d', desc: 'Smiling face with heart-shaped eyes'},
  {code: '1f60e', desc: 'Smiling face with sunglasses'},
  {code: '1f60f', desc: 'Smirking face'},

  {code: '1f610', desc: 'Neutral face'},
  {code: '1f611', desc: 'Expressionless face'},
  {code: '1f612', desc: 'Unamused face'},
  {code: '1f613', desc: 'Face with cold sweat'},
  {code: '1f614', desc: 'Pensive face'},
  {code: '1f615', desc: 'Confused face'},
  {code: '1f616', desc: 'Confounded face'},
  {code: '1f617', desc: 'Kissing face'},

  {code: '1f618', desc: 'Face throwing a kiss'},
  {code: '1f619', desc: 'Kissing face with smiling eyes'},
  {code: '1f61a', desc: 'Kissing face with closed eyes'},
  {code: '1f61b', desc: 'Face with stuck out tongue'},
  {code: '1f61c', desc: 'Face with stuck out tongue and winking eye'},
  {code: '1f61d', desc: 'Face with stuck out tongue and tightly-closed eyes'},
  {code: '1f61e', desc: 'Disappointed face'},
  {code: '1f61f', desc: 'Worried face'},

  {code: '1f620', desc: 'Angry face'},
  {code: '1f621', desc: 'Pouting face'},
  {code: '1f622', desc: 'Crying face'},
  {code: '1f623', desc: 'Persevering face'},
  {code: '1f624', desc: 'Face with look of triumph'},
  {code: '1f625', desc: 'Disappointed but relieved face'},
  {code: '1f626', desc: 'Frowning face with open mouth'},
  {code: '1f627', desc: 'Anguished face'},

  {code: '1f628', desc: 'Fearful face'},
  {code: '1f629', desc: 'Weary face'},
  {code: '1f62a', desc: 'Sleepy face'},
  {code: '1f62b', desc: 'Tired face'},
  {code: '1f62c', desc: 'Grimacing face'},
  {code: '1f62d', desc: 'Loudly crying face'},
  {code: '1f62e', desc: 'Face with open mouth'},
  {code: '1f62f', desc: 'Hushed face'},

  {code: '1f630', desc: 'Face with open mouth and cold sweat'},
  {code: '1f631', desc: 'Face screaming in fear'},
  {code: '1f632', desc: 'Astonished face'},
  {code: '1f633', desc: 'Flushed face'},
  {code: '1f634', desc: 'Sleeping face'},
  {code: '1f635', desc: 'Dizzy face'},
  {code: '1f636', desc: 'Face without mouth'},
  {code: '1f637', desc: 'Face with medical mask'}
];

const charactersSet = [{
  title: 'Latin',
  list: [
    { 'char': '&iexcl;', desc: 'INVERTED EXCLAMATION MARK' },
    { 'char': '&cent;', desc: 'CENT SIGN' },
    { 'char': '&pound;', desc: 'POUND SIGN' },
    { 'char': '&curren;', desc: 'CURRENCY SIGN' },
    { 'char': '&yen;', desc: 'YEN SIGN' },
    { 'char': '&brvbar;', desc: 'BROKEN BAR' },
    { 'char': '&sect;', desc: 'SECTION SIGN' },
    { 'char': '&uml;', desc: 'DIAERESIS' },
    { 'char': '&copy;', desc: 'COPYRIGHT SIGN' },
    { 'char': '&trade;', desc: 'TRADEMARK SIGN' },
    { 'char': '&ordf;', desc: 'FEMININE ORDINAL INDICATOR' },
    { 'char': '&laquo;', desc: 'LEFT-POINTING DOUBLE ANGLE QUOTATION MARK' },
    { 'char': '&not;', desc: 'NOT SIGN' },
    { 'char': '&reg;', desc: 'REGISTERED SIGN' },
    { 'char': '&macr;', desc: 'MACRON' },
    { 'char': '&deg;', desc: 'DEGREE SIGN' },
    { 'char': '&plusmn;', desc: 'PLUS-MINUS SIGN' },
    { 'char': '&sup2;', desc: 'SUPERSCRIPT TWO' },
    { 'char': '&sup3;', desc: 'SUPERSCRIPT THREE' },
    { 'char': '&acute;', desc: 'ACUTE ACCENT' },
    { 'char': '&micro;', desc: 'MICRO SIGN' },
    { 'char': '&para;', desc: 'PILCROW SIGN' },
    { 'char': '&middot;', desc: 'MIDDLE DOT' }
  ]},
  {
    title: 'Greek',
    list: [
      { 'char': '&Alpha;', desc: 'GREEK CAPITAL LETTER ALPHA' },
      { 'char': '&Beta;', desc: 'GREEK CAPITAL LETTER BETA' },
      { 'char': '&Gamma;', desc: 'GREEK CAPITAL LETTER GAMMA' },
      { 'char': '&Delta;', desc: 'GREEK CAPITAL LETTER DELTA' },
      { 'char': '&Epsilon;', desc: 'GREEK CAPITAL LETTER EPSILON' },
      { 'char': '&Zeta;', desc: 'GREEK CAPITAL LETTER ZETA' },
      { 'char': '&Eta;', desc: 'GREEK CAPITAL LETTER ETA' },
      { 'char': '&Theta;', desc: 'GREEK CAPITAL LETTER THETA' },
      { 'char': '&Iota;', desc: 'GREEK CAPITAL LETTER IOTA' },
      { 'char': '&Kappa;', desc: 'GREEK CAPITAL LETTER KAPPA' }
    ]
  }
];

/**
 * Simple model adapter that performs basic inline editing data management
 */
class SimpleModelAdapter {

  constructor(modelHandler, service) {
    this.modelHandler = modelHandler;
    this.service = service;
    this.lastElementType = null;
    this.fullFeaturedHeadline = null;
    this.shortenedHeadline = null;
  }

  trackElementTypeChange(newElementType) {
    if (this.lastElementType && this.lastElementType !== 'Bar' && newElementType === 'Bar') {
      const headline = this.modelHandler.get('model.headline');
      this.fullFeaturedHeadlineBackup = headline;
      this.shortenedHeadline = this.purgeHtmlMarkup(headline);
      this.modelHandler.set('model.headline', this.shortenedHeadline);
    }

    if (this.lastElementType === 'Bar' && newElementType !== 'Bar') {
      if ((this.modelHandler.get('model.headline') === this.shortenedHeadline) && this.fullFeaturedHeadlineBackup) {
        this.modelHandler.set('model.headline', this.fullFeaturedHeadlineBackup);
        this.fullFeaturedHeadlineBackup = null;
        this.shortenedHeadline = null;
      }
    }

    return this.lastElementType = newElementType;
  }

  purgeHtmlMarkup(htmlFragment) {
    htmlFragment = htmlFragment || '';
    htmlFragment = htmlFragment.replace(/<\/p>/g, '</p> ');
    htmlFragment = htmlFragment.replace(/<\/li>/g, '</li> ');
    const text = $(`<div>${htmlFragment}</div>`).text();
    if (text) {
      return text.replace(/\s+/g, ' ');
    } else {
      return '';
    }
  }

  handleImagePlacementChange(imagePlacement) {
    return this.modelHandler.set('model.image_placement', imagePlacement);
  }

  handleImageRemoval() {
    this.modelHandler.setProperties({
      'model.active_image_id': null,
      'model.image_placement': this.modelHandler.get('model.image_placement'),
      'model.image_type': 'custom',
      'model.image_url': null
    });

    window.parent.$('.file-upload-container .icon-trash').click();
  }

  handleImageReplaced(responseObject) {
    return this.modelHandler.setProperties({
      'model.active_image_id': responseObject.id,
      'model.image_placement': this.modelHandler.get('model.image_placement'),
      'model.image_type': 'custom',
      'model.image_url': responseObject.url
    });
  }

  handleContentChange(blockId, content) {
    content = this.preprocessContent(content);
    if (blockId && blockId.indexOf('f-') === 0) {
      const fields = this.modelHandler.get('model.settings.fields_to_collect');
      const fieldIdToChange = blockId.substring(2);
      const fieldToChange = (blockId === 'f-builtin-email') ?
        _.find(fields, f => f.type === 'builtin-email') :
      _.find(fields, f => f.id === fieldIdToChange);
      if (fieldToChange) {
        fieldToChange.label = content;
        this.service.get('bus').trigger('hellobar.core.fields.changed', {
          fields: fields,
          changedField: fieldToChange,
          content: content
        });
      }
    } else {
      switch (blockId) {
        case 'headline':
          return this.modelHandler.get('model').headline = content;
        case 'action_link':
          return this.modelHandler.get('model').link_text = content;
        case 'caption':
          return this.modelHandler.get('model').caption = content;
        case 'content':
          return this.modelHandler.get('model').content = content;
      }
    }
  }

  preprocessContent(content) {
    let $content = $(`<div>${content}</div>`);
    $content.find('a').filter(function () {
      return $(this).attr('target') !== '_blank';
    }).each(function () {
      return $(this).attr('target', '_top');
    });
    return $content.html();
  }

  activeImageId() {
    return this.modelHandler.get('model.active_image_id');
  }
}

export default Ember.Service.extend({

  bus: Ember.inject.service(),
  froalaFonts: Ember.inject.service(),

  modelHandler: null,
  simpleModelAdapter: null,

  $currentFroalaInstances: null,
  $currentInputInstances: null,

  init() {
    Ember.run.next(() => this.customizeFroala());
  },

  customizeFroala() {
    const that = this;
    $.FroalaEditor.DefineIcon('imageReplace', {NAME: 'image'});
    $.FroalaEditor.DefineIcon('imagePosition', {NAME: 'align-justify'});
    $.FroalaEditor.RegisterCommand('imagePosition', {
      title: 'Image position',
      type: 'dropdown',
      focus: false,
      undo: false,
      refreshAfterCallback: true,
      options: {
        'top': 'Top',
        'bottom': 'Bottom',
        'left': 'Left',
        'right': 'Right',
        'above-caption': 'Above Caption',
        'below-caption': 'Below Caption'
      },
      callback(cmd, val) {
        that.simpleModelAdapter.handleImagePlacementChange(val);
      }
    });
    $.FroalaEditor.DefineIcon('imageRemoveCustom', {NAME: 'trash'});
    $.FroalaEditor.RegisterCommand('imageRemoveCustom', {
      title: 'Remove image',
      icon: 'imageRemoveCustom',
      undo: false,
      focus: false,
      refreshAfterCallback: false,
      callback() {
        that.simpleModelAdapter.handleImageRemoval();
      }
    });
    $.FroalaEditor.DefineIcon('geolocationDropdown', {NAME: 'map-marker'});
    $.FroalaEditor.RegisterCommand('geolocationDropdown', {
      title: 'Insert geolocation name',
      icon: 'geolocationDropdown',
      type: 'dropdown',
      focus: false,
      undo: false,
      refreshAfterCallback: true,
      options: {
        'country': 'Country',
        'region': 'Region',
        'city': 'City'
      },
      callback(cmd, val) {
        const span = ` <span data-hb-geolocation="${val}"></span> `;
        this.html.insert(span);
        setTimeout(() => {
          this.toolbar.hide();
      }, 200);
      }
    });
  },

  setModelHandler(modelHandler) {
    this.modelHandler = modelHandler;
    if (modelHandler) {
      this.simpleModelAdapter = new SimpleModelAdapter(modelHandler, this);
    } else {
      this.simpleModelAdapter = null;
    }
  },

  preconfigure(capabilities) {
    this._capabilities = capabilities;
  },

  initializeInlineEditing(elementType) {
    this.cleanup();
    if (this.simpleModelAdapter) {
      this.simpleModelAdapter.trackElementTypeChange(elementType);
    }
    return setTimeout(() => {
      const $iframe = $('#hellobar-preview-container > iframe');
    if ($iframe.length > 0) {
      const $iframeBody = $($iframe[0].contentDocument.body);
      if ($iframeBody.length > 0) {
        return $($iframe[0].contentDocument).ready(() => {
          this.instantiateFroala($iframe, $iframeBody, elementType);
        this.initializeInputEditing($iframe, $iframeBody);
      }
      );
      }
    }
  }, 500);
  },

  instantiateFroala($iframe, $iframeBody, elementType){
    this.cleanupFroala();

    const isGeolocationInjectionAllowed = () => this._capabilities && this._capabilities['geolocation_injection'];

    const textFroala = (requestedMode) => {
      const mode = (elementType === 'Bar' && requestedMode === 'full') ? 'simple' : requestedMode;
      const linkStyles = {
        barlinkblue: 'Blue',
        barlinkmutedblue: 'Muted Blue',
        barlinkorange: 'Orange',
        barlinkgreen: 'Green',
        barlinkred: 'Red',
        barlinkwhite: 'White',
        barlinkblack: 'Black'
      };

      const toolbarButtons = {
        'simple': ['bold', 'italic', 'underline', 'strikeThrough','|',
          'fontFamily', 'fontSize', 'color','specialCharacters','emoticons', '-', 'insertLink',
          'undo', 'redo', 'clearFormatting', isGeolocationInjectionAllowed() ? 'geolocationDropdown' : undefined
        ],
        'simple-no-link': ['bold', 'italic', 'underline', 'strikeThrough',  '|',
          'fontFamily', 'fontSize','specialCharacters','emoticons', 'color', '-',
          'undo', 'redo', 'clearFormatting', 'selectAll', isGeolocationInjectionAllowed() ? 'geolocationDropdown' : undefined

        ],
        'full': [
          'bold', 'italic', 'underline', 'strikeThrough', '|',
          'fontFamily', 'fontSize', 'color',
          'align','-', 'formatOL', 'formatUL', 'outdent', 'indent','specialCharacters','emoticons', 'quote', '|', 'insertLink', '-',
          'undo', 'redo', 'clearFormatting', isGeolocationInjectionAllowed() ? 'geolocationDropdown' : undefined
        ]
      };

      const htmlAllowedTags = {
        'simple': [
          'p', 'strong', 'em', 'u', 's', 'sub', 'sup', 'span', 'a', 'br'
        ],
        'simple-no-link': [
          'p', 'strong', 'em', 'u', 's', 'sub', 'sup', 'span', 'br'
        ],
        'full': [
          'p', 'strong', 'em', 'u', 's', 'sub', 'sup', 'span', 'ul', 'ol', 'li',
          'a', 'br', 'hr', 'table', 'tbody', 'tr', 'th', 'td', 'blockquote'
        ]
      };

      const froalaOptions = {
        key: froalaKey,
        linkStyles: linkStyles,
        linkMultipleStyles: false,
        toolbarInline: true,
        toolbarVisibleWithoutSelection: true,
        emoticonsStep: 8,
        emoticonsSet: emojisSet,
        specialCharactersStep: 10,
        specialCharactersSets: charactersSet,
        toolbarButtons: toolbarButtons[mode],
        toolbarButtonsMD: toolbarButtons[mode],
        toolbarButtonsSM: toolbarButtons[mode],
        toolbarButtonsXS: toolbarButtons[mode],
        htmlAllowedTags: htmlAllowedTags[mode],
        htmlAllowedEmptyTags: ['span'],
        enter: $.FroalaEditor.ENTER_P,
        multiLine: true,
        initOnClick: false,
        zIndex: 9888,
        fontFamily: this.get('froalaFonts').fontFamily()
      };
      const $textFroala = $(`.hb-editable-block-with-${requestedMode}-formatting`, $iframeBody).froalaEditor($.extend({
        scrollableContainer: $iframeBody[0]
      }, froalaOptions));
      $textFroala.on('froalaEditor.contentChanged', (e /*, editor */) => {
        const $target = $(e.currentTarget);
      const content = $target.froalaEditor('html.get');
      const blockId = $target.attr('data-hb-editable-block');
      this.handleContentChange(blockId, content);
    });
      $textFroala.each(function () {
        const $editableElement = $(this);
        const editor = $editableElement.data('froala.editor');
        const newOptions = {};
        const placeholder = $editableElement.attr('data-hb-inline-editor-placeholder');
        if (placeholder) {
          newOptions.placeholderText = placeholder;
        }
        $.extend(editor.opts, newOptions);
        $editableElement.find('.fr-placeholder').text(placeholder);
      });
      return $textFroala;
    };

    const imageFroala = () => {
      const imageFroalaOptions = {
        key: froalaKey,
        pluginsEnabled: ['image'],
        toolbarInline: true,
        toolbarButtons: ['bold', 'italic', 'underline'],
        imageInsertButtons: ['imageUpload'],
        imageEditButtons: ['imageReplace', 'imagePosition', 'imageRemoveCustom'],
        htmlAllowedTags: ['p', 'div', 'img'],
        multiLine: false,
        initOnClick: false,
        zIndex: 9888,
        imageUploadURL: `/sites/${siteID}/image_uploads`,
        imageResize: false,
        requestHeaders: {
          'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
        }
      };
      const $imageFroala = $('.hb-editable-block-image', $iframeBody).froalaEditor($.extend({
        scrollableContainer: $iframeBody[0]
      }, imageFroalaOptions));
      $imageFroala.on('froalaEditor.image.uploaded', (e, editor, response) => {
        const responseObject = JSON.parse(response);
      if (this.simpleModelAdapter) {
        this.simpleModelAdapter.handleImageReplaced(responseObject);
      }
      return false;
    });
      return $imageFroala;
    };

    const $allFroala = $()
      .add(textFroala('simple'))
      .add(textFroala('simple-no-link'))
      .add(textFroala('full'))
      .add(imageFroala());

    geolocationHelper.bindEvents($allFroala);

    this.$currentFroalaInstances = this.$currentFroalaInstances || $();
    this.$currentFroalaInstances = this.$currentFroalaInstances.add($allFroala);
  },

  initializeInputEditing($iframe, $iframeBody){
    this.cleanupInputs();
    $('.hb-editable-block-input input', $iframeBody).blur(evt => {
      const $target = $(evt.currentTarget);
    const blockId = $target.closest('[data-hb-editable-block]').attr('data-hb-editable-block');
    const content = $target.val();
    this.handleContentChange(blockId, content);
  }
  );
  },

  cleanupInputs() {
    if (this.$currentInputInstances && this.$currentInputInstances.length > 0) {
      return this.$currentInputInstances.off('blur');
    }
  },

  cleanupFroala() {
    if (this.$currentFroalaInstances && this.$currentFroalaInstances.length > 0) {
      geolocationHelper.unbindEvents(this.$currentFroalaInstances);
      this.$currentFroalaInstances.off('froalaEditor.contentChanged');
      this.$currentFroalaInstances.off('froalaEditor.blur');
      this.$currentFroalaInstances.off('froalaEditor.image.uploaded');
      this.$currentFroalaInstances.off('froalaEditor.destroy');
      this.$currentFroalaInstances.froalaEditor('destroy');
      this.$currentFroalaInstances = $();
    }
  },


  cleanup() {
    this.cleanupFroala();
    this.cleanupInputs();
  },


  handleContentChange(blockId, content) {
    if (this.simpleModelAdapter) {
      this.simpleModelAdapter.handleContentChange(blockId, content);
    }
  }

});
