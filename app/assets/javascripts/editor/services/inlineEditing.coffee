# Froala Editor license key
froalaKey = 'Qg1Ti1LXd2URVJh1DWXG=='

class ModelAdapter
  constructor: (@modelHandler) ->
    #window.modelHandler = @modelHandler

  handleContentChange: (blockId, content) ->
    console.log('handleContentChange', blockId, content)
    if blockId and blockId.indexOf('f-') == 0
      fields = @modelHandler.get('model.settings.fields_to_collect')
      fieldIdToChange = blockId.substring(2)
      fieldToChange = null
      if blockId == 'f-builtin-email'
        fieldToChange = _.find(fields, (f) -> f.type == 'builtin-email')
      else
        fieldToChange = _.find(fields, (f) -> f.id == fieldIdToChange)
      console.log('handleContentChange fields = ', fields, ', fieldToChange = ', fieldToChange)
      if fieldToChange
        fieldToChange.label = content
    else
      switch blockId
        when 'headline' then @modelHandler.get('model').headline = content
        when 'action_link' then @modelHandler.get('model').link_text = content
        when 'caption' then @modelHandler.get('model').caption = content

# TODO Convert to service after upgrading to Ember 2
HelloBar.inlineEditing = {

  modelHandler: null
  modelAdapter: null

  $currentFroalaInstances: null
  $currentInputInstances: null

  setModelHandler: (modelHandler) ->
    @modelHandler = modelHandler
    if modelHandler
      @modelAdapter = new ModelAdapter(modelHandler)
    else
      @modelAdapter = null

  initializeInlineEditing: ->
    @cleanup()
    setTimeout(=>
      $iframe = $('#hellobar-preview-container > iframe')
      if $iframe.length > 0
        $iframeBody = $($iframe[0].contentDocument.body)
        if $iframeBody.length > 0
          $($iframe[0].contentDocument).ready(=>
            @instantiateFroala($iframe, $iframeBody)
            @initializeInputEditing($iframe, $iframeBody)
          )
    , 500)

  instantiateFroala: ($iframe, $iframeBody)->
    @cleanupFroala()
    $froala = $('.hb-editable-block-with-formatting', $iframeBody).add('.hb-editable-block-without-formatting',
      $iframeBody).froalaEditor({
      key: froalaKey,
      toolbarInline: true,
      toolbarButtons: ['bold', 'italic', 'underline'],
      htmlAllowedTags: ['p', 'strong', 'em', 'u', 'input', 'label'],
      enter: $.FroalaEditor.ENTER_P,
      multiLine: false,
      initOnClick: true,
      zIndex: 9888,
      scrollableContainer: $iframeBody[0]
    });
    $froala.on('froalaEditor.contentChanged', (e, editor) =>
      $target = $(e.currentTarget)
      content = $target.froalaEditor('html.get')
      blockId = $target.attr('data-hb-editable-block')
      @handleContentChange(blockId, content)
    )
    # This can be used for @set data model synchronization
    # $froala.on('froalaEditor.blur', (e, editor) ->
    # )
    $froala.on('froalaEditor.destroy', (e, editor) =>
    )
    @$currentFroalaInstances = $froala

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
      @$currentFroalaInstances.off('froalaEditor.destroy')
      @$currentFroalaInstances.froalaEditor('destroy')


  cleanup: ->
    @cleanupFroala()
    @cleanupInputs()


  handleContentChange: (blockId, content) ->
    if @modelAdapter
      @modelAdapter.handleContentChange(blockId, content)

}
