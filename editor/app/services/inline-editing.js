/* globals html_beautify, siteID */

import Ember from 'ember';
import _ from 'lodash/lodash';
import defaultBlocks from './inline-editing.blocks';
import geolocationHelper from './inline-editing.geolocation-helper';

// Froala Editor license key
const froalaKey = 'Qg1Ti1LXd2URVJh1DWXG==';

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
      this.shortenedHeadline = this.purgeHtmlMarkup(headline).substring(0, 60);
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
    htmlFragment = htmlFragment.replace(/\<\/p\>/g, '</p> ');
    htmlFragment = htmlFragment.replace(/\<\/li\>/g, '</li> ');
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

/**
 * Flexible model adapter based on property 'blocks' of model.
 */
class BlockBasedModelAdapter {
  constructor(modelHandler, service) {
    this.modelHandler = modelHandler;
    this.service = service;
  }

  /**
   * Handles block content change
   * @param blockId {string} fully-qualified block id, i.e. 'blocks.action_link'
   * @param content {string} plain text or HTML fragment
   */
  handleContentChange(blockId, content) {
    const blocks = this.modelHandler.get('model.blocks');
    const shortBlockId = blockId.substring('blocks.'.length);
    const foundBlock = _.find(blocks, (block) => block.id === shortBlockId);
    if (foundBlock) {
      if (foundBlock.content) {
        foundBlock.content.text = content;
      } else {
        foundBlock.content = {
          text: content
        };
      }
      delete foundBlock.isDefault;
    } else {
      console.warn(`Block ${blockId} not found in the current template blocks.`);
    }
  }
}

/**
 * Model adapter that provides inline editing support for Custom HTML elements
 */
class CustomHtmlModelAdapter {
  constructor(modelHandler, service) {
    this.modelHandler = modelHandler;
    this.service = service;
  }

  handleContentChange(blockId, content) {
    const customHtml = html_beautify(content);
    this.modelHandler.requestPreviewUpdateSkipping();
    this.modelHandler.set('model.custom_html', customHtml);
    this.service.customHtmlChangeListeners.forEach((listener) => listener(customHtml));
  }
}

/**
 * @deprecated
 */
class InlineImageManagementPane {
  constructor($iframe, $iframeBody, hasImage) {
    this.$pane = $('<div></div>').addClass('inline-image-management-pane');
    hasImage && (this.$pane.addClass('image-loaded'));
    $('<a href="javascript:void(0)" data-action="add-image"><i class="fa fa-image"></i><span>add image</span></a>').appendTo(this.$pane);
    $('<a href="javascript:void(0)" data-action="edit-image"><i class="fa fa-image"></i><span>edit image</span></a>').appendTo(this.$pane);
    $('<div class="image-holder hb-editable-block hb-editable-block-image hb-editable-block-image-without-placement"><img class="image" src=""></div>').appendTo(this.$pane);
    const $container = $iframeBody.find('.js-hellobar-element');
    $container.append(this.$pane);
    this.$pane.on('click', '[data-action]', evt => {
      const action = $(evt.currentTarget).attr('data-action');
      switch (action) {
        case 'add-image':
          return this.addImage();
        case 'edit-image':
          return this.editImage();
      }
    });
  }

  addImage() {
    const editor = this.$pane.find('.image-holder').data('froala.editor');
    const imageHolder = this.$pane.find('.image-holder')[0];
    const image = this.$pane.find('.image-holder .image')[0];
    if (editor && imageHolder && image) {
      const r = imageHolder.getBoundingClientRect();
      editor.selection.setAtStart(image);
      editor.selection.setAtEnd(image);
      editor.image.showInsertPopup();
      return editor.popups.show('image.insert', r.left + (r.width / 2), r.top);
    }
  }

  editImage() {
    const image = this.$pane.find('.image-holder .image')[0];
    if (image) {
      let event = document.createEvent('Events');
      event.initEvent('click', true, false);
      image.dispatchEvent(event);
    }
  }


  destroy() {
    this.$pane.off('click');
    this.$pane.remove();
  }
}

export default Ember.Service.extend({

  bus: Ember.inject.service(),

  modelHandler: null,
  simpleModelAdapter: null,
  blockBasedModelAdapter: null,
  customHtmlModelAdapter: null,

  customHtmlChangeListeners: [],

  $currentFroalaInstances: null,
  $currentInputInstances: null,

  inlineImageManagementPane: null,

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
      this.blockBasedModelAdapter = new BlockBasedModelAdapter(modelHandler, this);
      this.customHtmlModelAdapter = new CustomHtmlModelAdapter(modelHandler, this);
    } else {
      this.simpleModelAdapter = null;
      this.blockBasedModelAdapter = null;
      this.customHtmlModelAdapter = null;
    }
  },

  addCustomHtmlChangeListener(listener) {
    this.customHtmlChangeListeners.push(listener);
  },

  preconfigure(capabilities) {
    this._capabilities = capabilities;
  },

  initializeInlineEditing(elementType) {
    this.cleanup();
    this.simpleModelAdapter && this.simpleModelAdapter.trackElementTypeChange(elementType);
    return setTimeout(() => {
      const $iframe = $('#hellobar-preview-container > iframe');
      if ($iframe.length > 0) {
        const $iframeBody = $($iframe[0].contentDocument.body);
        if ($iframeBody.length > 0) {
          return $($iframe[0].contentDocument).ready(() => {
              // NOTE So far we don't use InlineImageManagementPane, we need to make final desicion later
              // const hasImage = this.simpleModelAdapter ? !!this.simpleModelAdapter.activeImageId() : false;
              //@instantiateInlineImageManagementPane($iframe, $iframeBody, elementType, hasImage)
              this.instantiateFroala($iframe, $iframeBody, elementType);
              this.initializeInputEditing($iframe, $iframeBody);
            }
          );
        }
      }
    }, 500);
  },

  instantiateInlineImageManagementPane($iframe, $iframeBody, elementType, hasImage) {
    return this.inlineImageManagementPane = new InlineImageManagementPane($iframe, $iframeBody, hasImage);
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
        'simple': ['bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|',
          'fontFamily', 'fontSize', 'color', 'insertLink', '-',
          'undo', 'redo', 'clearFormatting', 'selectAll', isGeolocationInjectionAllowed() ? 'geolocationDropdown' : undefined
        ],
        'simple-no-link': ['bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|',
          'fontFamily', 'fontSize', 'color', '-',
          'undo', 'redo', 'clearFormatting', 'selectAll', isGeolocationInjectionAllowed() ? 'geolocationDropdown' : undefined
        ],
        'full': [
          'bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|',
          'fontFamily', 'fontSize', 'color', '-',
          'align', 'formatOL', 'formatUL', 'outdent', 'indent', 'quote', '|',
          'insertHR', 'insertLink', '-',
          'undo', 'redo', 'clearFormatting', 'selectAll', isGeolocationInjectionAllowed() ? 'geolocationDropdown' : undefined
        ],
        'limited': [
          'bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|', 'color', '-',
          'undo', 'redo', 'clearFormatting', 'selectAll', isGeolocationInjectionAllowed() ? 'geolocationDropdown' : undefined
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
        ],
        'limited': [
          'p', 'strong', 'em', 'u', 's', 'sub', 'sup', 'span', 'a', 'br'
        ]
      };
      const froalaOptions = {
        key: froalaKey,
        linkStyles: mode === 'limited' ? undefined : linkStyles,
        linkMultipleStyles: false,
        toolbarInline: true,
        toolbarVisibleWithoutSelection: true,
        toolbarButtons: toolbarButtons[mode],
        toolbarButtonsMD: toolbarButtons[mode],
        toolbarButtonsSM: toolbarButtons[mode],
        toolbarButtonsXS: toolbarButtons[mode],
        htmlAllowedTags: htmlAllowedTags[mode],
        htmlAllowedEmptyTags: ['span'],
        enter: $.FroalaEditor.ENTER_P,
        multiLine: mode === 'full',
        initOnClick: false,
        zIndex: 9888
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
        this.simpleModelAdapter && this.simpleModelAdapter.handleImageReplaced(responseObject);
        return false;
      });
      return $imageFroala;
    };

    const $allFroala = $()
      .add(textFroala('simple'))
      .add(textFroala('simple-no-link'))
      .add(textFroala('full'))
      .add(textFroala('limited'))
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
    this.inlineImageManagementPane && this.inlineImageManagementPane.destroy();
    this.cleanupFroala();
    this.cleanupInputs();
  },


  handleContentChange(blockId, content) {
    if (blockId === 'custom_html') {
      this.customHtmlModelAdapter && this.customHtmlModelAdapter.handleContentChange(blockId, content);
    } else if (blockId && _.startsWith(blockId, 'blocks.')) {
      this.blockBasedModelAdapter && this.blockBasedModelAdapter.handleContentChange(blockId, content);
    } else {
      this.simpleModelAdapter && this.simpleModelAdapter.handleContentChange(blockId, content);
    }
  },

  initializeBlocks(model, themeId) {
    //const newBlock = (id, text) => ( {id, content: {text: text}} );
    model.blocks = model.blocks || [];
    const blocks = defaultBlocks[themeId];
    _.each(blocks, (defaultBlock) => {
      const foundModelBlock = _.find(model.blocks, (modelBlock) => modelBlock.id === defaultBlock.id);
      const clonedDefaultBlock = _.defaultsDeep({isDefault: true}, defaultBlock);
      if (!foundModelBlock) {
        model.blocks.push(clonedDefaultBlock);
      } else {
        foundModelBlock.isDefault && _.extend(foundModelBlock, clonedDefaultBlock);
      }
    });
  }

});
