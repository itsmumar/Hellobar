import Ember from 'ember';

// Froala Editor license key
const froalaKey = 'Qg1Ti1LXd2URVJh1DWXG==';

class ModelAdapter {

  constructor(modelHandler, service) {
    this.modelHandler = modelHandler;
    this.service = service;
    this.lastElementType = null;
    this.fullFeaturedHeadline = null;
    this.shortenedHeadline = null;
  }

  trackElementTypeChange(newElementType) {
    if (this.lastElementType && this.lastElementType !== 'Bar' && newElementType === 'Bar') {
      let headline = this.modelHandler.get('model.headline');
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
    let text = $(`<div>${htmlFragment}</div>`).text();
    if (text) { return text.replace(/\s+/g,' '); } else { return ''; }
  }

  handleImagePlacementChange(imagePlacement) {
    return this.modelHandler.set('model.image_placement', imagePlacement);
  }

  handleImageRemoval() {
    return this.modelHandler.setProperties({
      'model.active_image_id': null,
      'model.image_placement': this.modelHandler.get('model.image_placement'),
      'model.image_type': 'custom',
      'model.image_url': null
    });
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
      let fields = this.modelHandler.get('model.settings.fields_to_collect');
      let fieldIdToChange = blockId.substring(2);
      let fieldToChange = null;
      if (blockId === 'f-builtin-email') {
        fieldToChange = _.find(fields, f => f.type === 'builtin-email');
      } else {
        fieldToChange = _.find(fields, f => f.id === fieldIdToChange);
      }
      if (fieldToChange) {
        fieldToChange.label = content;
        this.modelHandler.notifyPropertyChange('model.settings.fields_to_collect');
        if (this.service.fieldChangeListeners) {
          return this.service.fieldChangeListeners.forEach(listener => listener.notifyPropertyChange('model.settings.fields_to_collect'));
        }
      }
    } else {
      switch (blockId) {
        case 'headline': return this.modelHandler.get('model').headline = content;
        case 'action_link': return this.modelHandler.get('model').link_text = content;
        case 'caption': return this.modelHandler.get('model').caption = content;
      }
    }
  }

  preprocessContent(content){
    let $content = $(`<div>${content}</div>`);
    $content.find('a').filter(function() { return $(this).attr('target') !== '_blank'; }).each(function() { return $(this).attr('target', '_top'); });
    return $content.html();
  }

  activeImageId() {
    return this.modelHandler.get('model.active_image_id');
  }
}


class InlineImageManagementPane {
  constructor($iframe, $iframeBody, hasImage) {
    this.$pane = $('<div></div>').addClass('inline-image-management-pane');
    hasImage && (this.$pane.addClass('image-loaded'));
    $('<a href="javascript:void(0)" data-action="add-image"><i class="fa fa-image"></i><span>add image</span></a>').appendTo(this.$pane);
    $('<a href="javascript:void(0)" data-action="edit-image"><i class="fa fa-image"></i><span>edit image</span></a>').appendTo(this.$pane);
    $('<div class="image-holder hb-editable-block hb-editable-block-image hb-editable-block-image-without-placement"><img class="image" src=""></div>').appendTo(this.$pane);
    let $container = $iframeBody.find('.js-hellobar-element');
    $container.append(this.$pane);
    this.$pane.on('click', '[data-action]', evt => {
      let action = $(evt.currentTarget).attr('data-action');
      switch (action) {
        case 'add-image': return this.addImage();
        case 'edit-image': return this.editImage();
      }
    }
    );
  }
  addImage() {
    let editor = this.$pane.find('.image-holder').data('froala.editor');
    let imageHolder = this.$pane.find('.image-holder')[0];
    let image = this.$pane.find('.image-holder .image')[0];
    if (editor && imageHolder && image) {
      let r = imageHolder.getBoundingClientRect();
      editor.selection.setAtStart(image);
      editor.selection.setAtEnd(image);
      editor.image.showInsertPopup();
      return editor.popups.show('image.insert', r.left + (r.width / 2), r.top);
    }
  }

  editImage() {
    let image = this.$pane.find('.image-holder .image')[0];
    if (image) {
      let event = document.createEvent('Events');
      event.initEvent('click', true, false);
      return image.dispatchEvent(event);
    }
  }


  destroy() {
    this.$pane.off('click');
    return this.$pane.remove();
  }
}

export default Ember.Service.extend({

  modelHandler: null,
  modelAdapter: null,

  fieldChangeListeners: [],

  $currentFroalaInstances: null,
  $currentInputInstances: null,

  inlineImageManagementPane: null,

  init() {
    Ember.run.next(() => HelloBar.inlineEditing.customizeFroala());
  },

  customizeFroala() {
    let that = this;
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
        // TODO remove
        //console.log(this, cmd, val)
        //this.image.exitEdit()
        return that.modelAdapter.handleImagePlacementChange(val);
      }
    });
    $.FroalaEditor.DefineIcon('imageRemoveCustom', {NAME: 'trash'});
    return $.FroalaEditor.RegisterCommand('imageRemoveCustom', {
      title: 'Remove image',
      icon: 'imageRemoveCustom',
      undo: false,
      focus: false,
      refreshAfterCallback: false,
      callback() {
        return that.modelAdapter.handleImageRemoval();
      }
    });
  },

  setModelHandler(modelHandler) {
    this.modelHandler = modelHandler;
    if (modelHandler) {
      return this.modelAdapter = new ModelAdapter(modelHandler, this);
    } else {
      return this.modelAdapter = null;
    }
  },

  addFieldChangeListener(listener) {
    return this.fieldChangeListeners.push(listener);
  },

  initializeInlineEditing(elementType) {
    this.cleanup();
    this.modelAdapter && this.modelAdapter.trackElementTypeChange(elementType);
    return setTimeout(() => {
      let $iframe = $('#hellobar-preview-container > iframe');
      if ($iframe.length > 0) {
        let $iframeBody = $($iframe[0].contentDocument.body);
        if ($iframeBody.length > 0) {
          return $($iframe[0].contentDocument).ready(() => {
            let hasImage = this.modelAdapter ? !!this.modelAdapter.activeImageId() : false;
            // NOTE So far we don't use InlineImageManagementPane, we need to make final desicion later
            //@instantiateInlineImageManagementPane($iframe, $iframeBody, elementType, hasImage)
            this.instantiateFroala($iframe, $iframeBody, elementType);
            return this.initializeInputEditing($iframe, $iframeBody);
          }
          );
        }
      }
    }
    , 500);
  },

  instantiateInlineImageManagementPane($iframe, $iframeBody, elementType, hasImage) {
    return this.inlineImageManagementPane = new InlineImageManagementPane($iframe, $iframeBody, hasImage);
  },

  instantiateFroala($iframe, $iframeBody, elementType){
    this.cleanupFroala();
    let simpleFroalaOptions = {
      key: froalaKey,
      toolbarInline: true,
      toolbarVisibleWithoutSelection: true,
      toolbarButtons: [
        'bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|',
        'fontFamily', 'fontSize', 'color', '-',
        'undo', 'redo', 'clearFormatting', 'selectAll'
      ],
      htmlAllowedTags: [
        'p', 'strong', 'em', 'u', 's', 'sub', 'sup', 'span', 'a', 'br'
      ],
      enter: $.FroalaEditor.ENTER_P,
      multiLine: false,
      initOnClick: false,
      zIndex: 9888
    };
    let fullFroalaOptions = {
      key: froalaKey,
      toolbarInline: true,
      toolbarVisibleWithoutSelection: true,
      toolbarButtons: ['bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|',
                       'fontFamily', 'fontSize', 'color', '-',
                       'align', 'formatOL', 'formatUL', 'outdent', 'indent', 'quote', '|',
                       'insertHR', 'insertLink', '-',
                       'undo', 'redo', 'clearFormatting', 'selectAll'
      ],
      htmlAllowedTags: [
        'p', 'strong', 'em', 'u', 's', 'sub', 'sup', 'span', 'ul', 'ol', 'li',
        'a', 'br', 'hr', 'table', 'tbody',  'tr', 'th', 'td', 'blockquote'
      ],
      enter: $.FroalaEditor.ENTER_P,
      multiLine: true,
      initOnClick: false,
      zIndex: 9888,
    };
    let imageFroalaOptions = {
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
      requestHeaders: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    };
    let $simpleFroala = $('.hb-editable-block-with-simple-formatting', $iframeBody).froalaEditor($.extend({
      scrollableContainer: $iframeBody[0]
    }, simpleFroalaOptions));
    let $fullFroala = $('.hb-editable-block-with-full-formatting', $iframeBody).froalaEditor($.extend({
      scrollableContainer: $iframeBody[0]
    }, elementType === 'Bar' ? simpleFroalaOptions : fullFroalaOptions));
    let $imageFroala = $('.hb-editable-block-image', $iframeBody).froalaEditor($.extend({
      scrollableContainer: $iframeBody[0]
    }, imageFroalaOptions));

    // NOTE This was used previously to support image uploading inline
    /*imageEditorWithoutPlacement = $('.hb-editable-block-image-without-placement', $iframeBody).data('froala.editor')
    $.extend(imageEditorWithoutPlacement.opts, {
      imageEditButtons: ['imageReplace', 'imageRemoveCustom']
    })*/


    $imageFroala.on('froalaEditor.image.uploaded', (e, editor, response) => {
      //console.log(e, editor, response)
      let responseObject = JSON.parse(response);
      this.modelAdapter && this.modelAdapter.handleImageReplaced(responseObject);
      return false;
    }
    );

    let $textFroala = $simpleFroala.add($fullFroala);
    $textFroala.on('froalaEditor.contentChanged', (e, editor) => {
      let $target = $(e.currentTarget);
      let content = $target.froalaEditor('html.get');
      let blockId = $target.attr('data-hb-editable-block');
      return this.handleContentChange(blockId, content);
    }
    );
    $textFroala.on('froalaEditor.destroy', (e, editor) => {}
    );

    let $allFroala = $($textFroala).add($imageFroala);
    this.$currentFroalaInstances = $allFroala;

    //TODO remove
    window.f = {
      $,
      $allFroala,
      $iframeBody
    };

    return $textFroala.each(function() {
      let $editableElement = $(this);
      let editor = $editableElement.data('froala.editor');
      let newOptions = {};
      let placeholder = $editableElement.attr('data-hb-inline-editor-placeholder');
      if (placeholder) {
        newOptions.placeholderText = placeholder;
      }
      $.extend(editor.opts, newOptions);
      return $editableElement.find('.fr-placeholder').text(placeholder);
    });
  },

  initializeInputEditing($iframe, $iframeBody){
    this.cleanupInputs();
    return $('.hb-editable-block-input input', $iframeBody).blur(evt => {
      let $target = $(evt.currentTarget);
      let blockId = $target.closest('[data-hb-editable-block]').attr('data-hb-editable-block');
      let content = $target.val();
      return this.handleContentChange(blockId, content);
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
      this.$currentFroalaInstances.off('froalaEditor.contentChanged');
      this.$currentFroalaInstances.off('froalaEditor.blur');
      this.$currentFroalaInstances.off('froalaEditor.image.uploaded');
      this.$currentFroalaInstances.off('froalaEditor.destroy');
      return this.$currentFroalaInstances.froalaEditor('destroy');
    }
  },


  cleanup() {
    this.inlineImageManagementPane && this.inlineImageManagementPane.destroy();
    this.cleanupFroala();
    return this.cleanupInputs();
  },


  handleContentChange(blockId, content) {
    if (this.modelAdapter) {
      return this.modelAdapter.handleContentChange(blockId, content);
    }
  }

});



