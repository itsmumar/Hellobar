class @ContactListModal extends Modal
  constructor: (@options = {}) ->
    @options.window ||= window

    @_initializeTemplates()
    @_initializeBlocks()

    super(@$modal)

  close: ->
    @$modal.remove()

  open: ->
    @_loadContactList() if @options.loadURL
    @_bindInteractions(@$modal)

    super

  _initializeTemplates: ->
    @templates =
      main: Handlebars.compile($("#contact-list-modal-template").html())
      instructions: Handlebars.compile($("#contact-list-modal-provider-instructions-template").html())
      nevermind: Handlebars.compile($("#contact-list-modal-provider-instructions-nevermind-template").html())
      remoteListSelect: Handlebars.compile($("#contact-list-modal-remote-list-select-template").html())

    @$modal = $(@templates.main())
    @$modal.appendTo($("body"))

  _initializeBlocks: ->
    @blocks =
      instructions: @$modal.find(".provider-instructions-block")
      nevermind: @$modal.find(".provider-instructions-nevermind-block")
      remoteListSelect: @$modal.find(".remote-list-select-block")

  _bindInteractions: (object) ->
    @_bindProviderSelect(object)
    @_bindDoThisLater(object)
    @_bindOauthButton(object)
    @_bindSubmit(object)

  _bindProviderSelect: (object) ->
    modal = this

    object.find("#contact_list_provider").change (e) ->
      modal._loadRemoteLists(this)

  _bindDoThisLater: (object) ->
    object.find("a.do-this-later").click (e) =>
      @blocks.instructions.hide()
      @blocks.nevermind.show()
      @$modal.find("#contact_list_provider").val(0)

  _bindOauthButton: (object) ->
    object.find("a.start-oauth").click (e) =>
      provider = @$modal.find("#contact_list_provider").val()
      @options.window.location = "/sites/#{@options.siteID}/identities/new/?provider=#{provider}"

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

    $.ajax @options.saveURL,
      type: @options.saveMethod
      data: formData
      success: (data) =>
        if data.errors.length > 0
          @_showErrors(data.errors)
          submitButton.attr("disabled", false)
        else
          @options.success(data)

  _renderBlock: (name, context, bind = true) ->
    block = @blocks[name].html(@templates[name](context))
    @_bindInteractions(block) if bind

    block

  _loadContactList: ->
    $.get @options.loadURL, (data) =>
      @_setFormValues(data)
      @_loadRemoteLists()
      # todo: set remote list if chosen

  _loadRemoteLists: (select = null) ->
    select ||= @$modal.find("#contact_list_provider")

    value = $(select).val()
    label = $(select).find("option:selected").text()

    $.get "/sites/#{@options.siteID}/identities/#{value}.json", (data) =>
      if data # an identity was found for the selected provider
        @blocks.instructions.hide()
        @blocks.nevermind.hide()
        @_renderBlock("remoteListSelect", {providerName: label, lists: data.lists}).show()
      else # no identity found
        context = {providerName: label}

        @_renderBlock("nevermind", context).hide()
        @_renderBlock("instructions", context).show()
        @blocks.remoteListSelect.hide()

  _showErrors: (errors) ->
    html = "<div class=\"alert\">#{errors.reduce (a, b) -> "#{a}<br>#{b}"}</div>"
    @$modal.find(".modal-block").prepend(html)

  _clearErrors: ->
    @$modal.find(".alert").remove()

  _setFormValues: (data) ->
    @$modal.find("#contact_list_name").val(data.name)
    @$modal.find("#contact_list_provider").val(data.provider || "0")
