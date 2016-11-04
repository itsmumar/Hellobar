# Froala Editor license key
froalaKey = 'Qg1Ti1LXd2URVJh1DWXG=='

class ModelAdapter
  constructor: (@modelHandler) ->

  handleContentChange: (blockId, content) ->
    console.log('handleContentChange', blockId, content)
    switch blockId
      when 'headline' then @modelHandler.get('model').headline = content
      when 'action_link' then @modelHandler.get('model').link_text = content
      when 'caption' then @modelHandler.get('model').caption = content
    #console.log('after', blockId, content, @modelHandler.get('model'))


# TODO Convert to service after upgrading to Ember 2
HelloBar.inlineEditing = {

  modelHandler: null
  modelAdapter: null

  $currentFroalaInstance: null

  setModelHandler: (modelHandler) ->
    @modelHandler = modelHandler
    if modelHandler
      @modelAdapter = new ModelAdapter(modelHandler)
    else
      @modelAdapter = null

  instantiateFroala: ->
    setTimeout(=>
      $iframe = $('#hellobar-preview-container > iframe')
      if $iframe.length > 0
        $iframeBody = $($iframe[0].contentDocument.body)
        if $iframeBody.length > 0
          $($iframe[0].contentDocument).ready(=>
            if @$currentFroalaInstance and @$currentFroalaInstance.length > 0
              @$currentFroalaInstance.off('froalaEditor.contentChanged')
              @$currentFroalaInstance.off('froalaEditor.blur')
              @$currentFroalaInstance.off('froalaEditor.destroy')

            $froala = $iframeBody.find('.hb-editable-block').froalaEditor({
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
            #$froala.on('froalaEditor.blur', (e, editor) ->
            #)
            $froala.on('froalaEditor.destroy', (e, editor) =>
            )
            @$currentFroalaInstance = $froala
          )


    , 0)

  handleContentChange: (blockId, content) ->
    if @modelAdapter
      @modelAdapter.handleContentChange(blockId, content)

}
