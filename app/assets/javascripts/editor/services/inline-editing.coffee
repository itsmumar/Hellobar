# Froala Editor license key
froalaKey = 'Qg1Ti1LXd2URVJh1DWXG=='

class ModelAdapter

  lastElementType: null
  fullFeaturedHeadline: null
  shortenedHeadline: null

  constructor: (@modelHandler, @service) ->

  trackElementTypeChange: (newElementType) ->
    if @lastElementType and @lastElementType != 'Bar' and newElementType == 'Bar'
      headline = @modelHandler.get('model.headline')
      @fullFeaturedHeadlineBackup = headline
      @shortenedHeadline = @purgeHtmlMarkup(headline).substring(0, 60)
      @modelHandler.set('model.headline', @shortenedHeadline)

    if @lastElementType == 'Bar' and newElementType != 'Bar'
      if (@modelHandler.get('model.headline') == @shortenedHeadline) and @fullFeaturedHeadlineBackup
        @modelHandler.set('model.headline', @fullFeaturedHeadlineBackup)
        @fullFeaturedHeadlineBackup = null
        @shortenedHeadline = null

    @lastElementType = newElementType

  purgeHtmlMarkup: (htmlFragment) ->
    htmlFragment = htmlFragment or ''
    htmlFragment = htmlFragment.replace(/\<\/p\>/g, '</p> ')
    htmlFragment = htmlFragment.replace(/\<\/li\>/g, '</li> ')
    text = $('<div>' + htmlFragment + '</div>').text()
    if text then text.replace(/\s+/g,' ') else ''

  handleImagePlacementChange: (imagePlacement) ->
    @modelHandler.set('model.image_placement', imagePlacement)

  handleImageRemoval: () ->
    @modelHandler.setProperties({
      'model.active_image_id': null,
      'model.image_placement': @modelHandler.get('model.image_placement'),
      'model.image_type': 'custom',
      'model.image_url': null
    })

  handleImageReplaced: (responseObject) ->
    @modelHandler.setProperties({
      'model.active_image_id': responseObject.id,
      'model.image_placement': @modelHandler.get('model.image_placement'),
      'model.image_type': 'custom',
      'model.image_url': responseObject.url
    })

  handleContentChange: (blockId, content) ->
    if blockId and blockId.indexOf('f-') == 0
      fields = @modelHandler.get('model.settings.fields_to_collect')
      fieldIdToChange = blockId.substring(2)
      fieldToChange = null
      if blockId == 'f-builtin-email'
        fieldToChange = _.find(fields, (f) -> f.type == 'builtin-email')
      else
        fieldToChange = _.find(fields, (f) -> f.id == fieldIdToChange)
      if fieldToChange
        fieldToChange.label = content
        @modelHandler.notifyPropertyChange('model.settings.fields_to_collect')
        if @service.fieldChangeListeners
          @service.fieldChangeListeners.forEach((listener) ->
            listener.notifyPropertyChange('model.settings.fields_to_collect')
          )
    else
      switch blockId
        when 'headline' then @modelHandler.get('model').headline = content
        when 'action_link' then @modelHandler.get('model').link_text = content
        when 'caption' then @modelHandler.get('model').caption = content


class InlineImageManagementPane
  constructor: ($iframe, $iframeBody) ->
    @$pane = $('<div></div>').addClass('inline-image-management-pane')
    $('<a href="javascript:void(0)" data-action="add-image"><i class="fa fa-image"></i><span>Add class</span></a>').appendTo(@$pane)
    $('<div class="image-holder hb-editable-block hb-editable-block-image"><img class="image" src=""></div>').appendTo(@$pane)
    $container = $iframeBody.find('.js-hellobar-element')
    $container.append(@$pane)
    @$pane.on('click', '[data-action]', (evt) =>
      action = $(evt.currentTarget).attr('data-action')
      switch action
        when 'add-image' then @addImage()
        when 'edit-image' then @editImage()
    )
  addImage: ->
    console.log('addImage')
    #@$pane.find('.hb-editable-block-image').froalaEditor('events.focus')
    editor = @$pane.find('.image-holder').data('froala.editor')
    imageHolder = @$pane.find('.image-holder')[0]
    image = @$pane.find('.image-holder .image')[0]
    if editor and imageHolder and image
      r = imageHolder.getBoundingClientRect()
      editor.selection.setAtStart(image)
      editor.selection.setAtEnd(image)
      editor.image.showInsertPopup()
      editor.popups.show('image.insert', r.left + r.width / 2, r.top)

  editImage: ->
    console.log('editImage')

  destroy: ->
    @$pane.off('click')
    @$pane.remove()


# TODO Convert to service after upgrading to Ember 2
HelloBar.inlineEditing = {

  modelHandler: null
  modelAdapter: null

  fieldChangeListeners: []

  $currentFroalaInstances: null
  $currentInputInstances: null

  inlineImageManagementPane: null

  customizeFroala: ->
    that = this
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
      callback: (cmd, val) ->
        # TODO remove
        #console.log(this, cmd, val)
        #this.image.exitEdit()
        that.modelAdapter.handleImagePlacementChange(val)
    })
    $.FroalaEditor.DefineIcon('imageRemoveCustom', {NAME: 'trash'});
    $.FroalaEditor.RegisterCommand('imageRemoveCustom', {
      title: 'Remove image',
      icon: 'imageRemoveCustom',
      undo: false,
      focus: false,
      refreshAfterCallback: false,
      callback: () ->
        that.modelAdapter.handleImageRemoval()
    })

  setModelHandler: (modelHandler) ->
    @modelHandler = modelHandler
    if modelHandler
      @modelAdapter = new ModelAdapter(modelHandler, this)
    else
      @modelAdapter = null

  addFieldChangeListener: (listener) ->
    @fieldChangeListeners.push(listener)

  initializeInlineEditing: (elementType) ->
    @cleanup()
    @modelAdapter.trackElementTypeChange(elementType)
    setTimeout(=>
      $iframe = $('#hellobar-preview-container > iframe')
      if $iframe.length > 0
        $iframeBody = $($iframe[0].contentDocument.body)
        if $iframeBody.length > 0
          $($iframe[0].contentDocument).ready(=>
            @instantiateInlineImageManagementPane($iframe, $iframeBody, elementType)
            @instantiateFroala($iframe, $iframeBody, elementType)
            @initializeInputEditing($iframe, $iframeBody)
          )
    , 500)

  instantiateInlineImageManagementPane: ($iframe, $iframeBody, elementType) ->
    @inlineImageManagementPane = new InlineImageManagementPane($iframe, $iframeBody)

  instantiateFroala: ($iframe, $iframeBody, elementType)->
    @cleanupFroala()
    simpleFroalaOptions = {
      key: froalaKey,
      toolbarInline: true,
      toolbarVisibleWithoutSelection: true,
      toolbarButtons: [
        'bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|',
        'fontFamily', 'fontSize', 'color', '-',
        'undo', 'redo', 'clearFormatting', 'selectAll', '|', 'insertLink', 'emoticons'
      ],
      htmlAllowedTags: [
        'p', 'strong', 'em', 'u', 's', 'sub', 'sup', 'span', 'a', 'br'
      ],
      enter: $.FroalaEditor.ENTER_P,
      multiLine: false,
      initOnClick: false,
      zIndex: 9888
    }
    fullFroalaOptions = {
      key: froalaKey,
      toolbarInline: true,
      toolbarVisibleWithoutSelection: true,
      toolbarButtons: ['bold', 'italic', 'underline', 'strikeThrough', 'subscript', 'superscript', '|',
                       'fontFamily', 'fontSize', 'color', '-',
                       'align', 'formatOL', 'formatUL', 'outdent', 'indent', 'quote', '|',
                       'insertHR', 'insertLink', 'emoticons', '-',
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
    }
    imageFroalaOptions = {
      key: froalaKey,
      pluginsEnabled: ['image'],
      toolbarInline: true,
      toolbarButtons: [],
      imageInsertButtons: ['imageUpload'],
      imageEditButtons: ['imageReplace', 'imagePosition', 'imageRemoveCustom']
      htmlAllowedTags: ['p', 'div', 'img']
      multiLine: false,
      initOnClick: false,
      zIndex: 9888,
      imageUploadURL: "/sites/#{siteID}/image_uploads",
      requestHeaders: {
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      }
    }
    $simpleFroala = $('.hb-editable-block-with-simple-formatting', $iframeBody).froalaEditor($.extend({
      scrollableContainer: $iframeBody[0]
    }, simpleFroalaOptions))
    $fullFroala = $('.hb-editable-block-with-full-formatting', $iframeBody).froalaEditor($.extend({
      scrollableContainer: $iframeBody[0]
    }, if elementType == 'Bar' then simpleFroalaOptions else fullFroalaOptions))
    $imageFroala = $('.hb-editable-block-image', $iframeBody).froalaEditor($.extend({
      scrollableContainer: $iframeBody[0]
    }, imageFroalaOptions))

    $imageFroala.on('froalaEditor.image.uploaded', (e, editor, response) =>
      #console.log(e, editor, response)
      responseObject = JSON.parse(response)
      @modelAdapter and @modelAdapter.handleImageReplaced(responseObject)
      false
    )

    $textFroala = $simpleFroala.add($fullFroala)
    $textFroala.on('froalaEditor.contentChanged', (e, editor) =>
      $target = $(e.currentTarget)
      content = $target.froalaEditor('html.get')
      blockId = $target.attr('data-hb-editable-block')
      @handleContentChange(blockId, content)
    )
    $textFroala.on('froalaEditor.destroy', (e, editor) =>
    )

    $allFroala = $($textFroala).add($imageFroala)
    @$currentFroalaInstances = $allFroala

    #TODO remove
    window.f = {
      $: $,
      $allFroala: $allFroala,
      $iframeBody: $iframeBody
    }

    $textFroala.each(->
      $editableElement = $(this)
      editor = $editableElement.data('froala.editor')
      newOptions = {}
      placeholder = $editableElement.attr('data-hb-inline-editor-placeholder')
      if placeholder
        newOptions.placeholderText = placeholder
      $.extend(editor.opts, newOptions)
      $editableElement.find('.fr-placeholder').text(placeholder)
    )

  initializeInputEditing: ($iframe, $iframeBody)->
    @cleanupInputs()
    $('.hb-editable-block-input input', $iframeBody).blur((evt) =>
      $target = $(evt.currentTarget)
      blockId = $target.closest('[data-hb-editable-block]').attr('data-hb-editable-block')
      content = $target.val()
      @handleContentChange(blockId, content)
    )

  cleanupInputs: ->
    if @$currentInputInstances and @$currentInputInstances.length > 0
      @$currentInputInstances.off('blur')

  cleanupFroala: ->
    if @$currentFroalaInstances and @$currentFroalaInstances.length > 0
      @$currentFroalaInstances.off('froalaEditor.contentChanged')
      @$currentFroalaInstances.off('froalaEditor.blur')
      @$currentFroalaInstances.off('froalaEditor.image.uploaded')
      @$currentFroalaInstances.off('froalaEditor.destroy')
      @$currentFroalaInstances.froalaEditor('destroy')


  cleanup: ->
    @inlineImageManagementPane and @inlineImageManagementPane.destroy()
    @cleanupFroala()
    @cleanupInputs()


  handleContentChange: (blockId, content) ->
    if @modelAdapter
      @modelAdapter.handleContentChange(blockId, content)

}

Ember.run.next(->
  HelloBar.inlineEditing.customizeFroala()
)

