class @ContactListModal extends Modal
  constructor: (@options = {}) ->
    @_initializeTemplates()
    @_initializeBlocks()
    @_renderBlock("nameAndProvider")

    if @options.load
      @_loadContactList(@options.id, @options.site_id)

    @_bindInteractions(@$modal)
    super(@$modal)

  close: ->
    @$modal.remove()

  _initializeTemplates: ->
    @templates =
      main: Handlebars.compile($("#contact-list-modal-template").html())
      instructions: Handlebars.compile($("#contact-list-modal-provider-instructions-template").html())
      nevermind: Handlebars.compile($("#contact-list-modal-provider-instructions-nevermind-template").html())
      nameAndProvider: Handlebars.compile($("#contact-list-modal-name-and-provider-template").html())

    @$modal = $(@templates.main())
    @$modal.appendTo($("body"))

  _initializeBlocks: ->
    @blocks =
      instructions: @$modal.find(".provider-instructions-block")
      nevermind: @$modal.find(".provider-instructions-nevermind-block")
      nameAndProvider: @$modal.find(".name-and-provider-block")

  _bindInteractions: (object) ->
    @_bindProviderSelect(object)
    @_bindDoThisLater(object)
    @_bindSubmit(object)

  _bindProviderSelect: (object) ->
    modal = this

    object.find("#contact_list_provider").change (e) ->
      value = $(this).val()
      label = $(this).find("option:selected").text()

      context = {providerName: label}

      modal._renderBlock("nevermind", context).hide()
      modal._renderBlock("instructions", context).show()

  _bindDoThisLater: (object) ->
    object.find("a.do-this-later").click (e) =>
      @blocks.instructions.hide()
      @blocks.nevermind.show()
      @$modal.find("#contact_list_provider").val(0)

  _bindSubmit: (object) ->
    object.find("a.submit").click (e) =>
      @_doSubmit(e)

    object.find("form.contact_list").submit (e) =>
      e.preventDefault()
      @_doSubmit(e)

  _doSubmit: (e) ->
    @_clearErrors()
    submitButton = @$modal.find("a.submit")
    submitButton.attr("disabled", true)
    formData = @$modal.find("form.contact_list").serialize()

    if @options.create
      $.post "/sites/#{@options.site_id}/contact_lists.json", formData, (data) =>
        if data.errors.length > 0
          @_showErrors(data.errors)
          submitButton.attr("disabled", false)
        else
          @options.success(data)

    else
      $.ajax "/sites/#{@options.site_id}/contact_lists/#{@options.id}.json",
        type: "PUT"
        data: formData
        success: (data) =>
          if data.errors.length > 0
            @_showErrors(data.errors)
            submitButton.attr("disabled", false)
          else
            @options.success(data)

  _renderBlock: (name, context) ->
    block = @blocks[name].html(@templates[name](context))
    @_bindInteractions(block)

    block

  _loadContactList: (id, site_id) ->
    url = "/sites/#{site_id}/contact_lists/#{id}.json"

    $.get url, (data) =>
      @$modal.find("#contact_list_name").val(data.name)

  _showErrors: (errors) ->
    html = "<div class=\"alert\">#{errors.reduce (a, b) -> "#{a}<br>#{b}"}</div>"
    @$modal.find(".modal-block").prepend(html)

  _clearErrors: ->
    @$modal.find(".alert").remove()

