class @ContactListModal extends Modal

  modalName: 'contact-list'

  constructor: (@options = {}) ->
    @options.window ||= window

    @_initializeTemplates()
    @_initializeBlocks()

    @$modal.on 'load',   -> $(this).addClass('loading')
    @$modal.on 'complete', -> $(this).removeClass('loading').finish()

    super(@$modal)

  close: ->
    @options.close(this) if @options.close
    @$modal.remove()

  open: ->
    @_loadContactList() if @options.loadURL
    @_populateContactList() if @options.contactList
    @_bindInteractions(@$modal)

    super

  _initializeTemplates: ->
    @templates =
      main: Handlebars.compile($("#contact-list-modal-template").html())
      instructions: Handlebars.compile($("#contact-list-modal-provider-instructions-template").html())
      nevermind: Handlebars.compile($("#contact-list-modal-provider-instructions-nevermind-template").html())
      remoteListSelect: Handlebars.compile($("#contact-list-modal-remote-list-select-template").html())

    @$modal = $(@templates.main({header: if @options.id then "Edit Contact List" else "New Contact List"}))
    @$modal.appendTo($("body"))

  _initializeBlocks: ->
    @blocks =
      instructions: @$modal.find(".provider-instructions-block")
      nevermind: @$modal.find(".provider-instructions-nevermind-block")
      remoteListSelect: @$modal.find(".remote-list-select-block")

  _bindInteractions: (object) ->
    @_bindProviderSelect(object)
    @_bindDoThisLater(object)
    @_bindReadyButton(object)
    @_bindSubmit(object)

  _bindProviderSelect: (object) ->
    modal = this

    object.find("#contact_list_provider").change (e) ->
      modal._loadRemoteLists(select: this, listData: {double_optin: true})

  _bindDoThisLater: (object) ->
    object.find("a.do-this-later").click (e) =>
      @blocks.instructions.hide()
      @blocks.nevermind.show()
      @$modal.find("#contact_list_provider").val(0)

  _bindReadyButton: (object) ->
    object.find("a.ready").click (e) =>
      @_clearErrors()

      # stash the model so that it can be reloaded by the ember app
      localStorage["stashedEditorModel"] = JSON.stringify(@options.editorModel) if @options.editorModel
      localStorage["stashedContactList"] = JSON.stringify($.extend(@_getFormData(), {id: @options.id}))

      @options.window.location = "/sites/#{@options.siteID}/identities/new?provider=#{@_getFormData().provider}"

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
    formData = @_getFormData()

    $.ajax @options.saveURL,
      type: @options.saveMethod
      data: {contact_list: formData}
      success: (data) =>
        @options.success(data, this)
      error: (response) =>
        contactList = response.responseJSON
        @_showErrors(contactList.errors)
        @$modal.find("a.submit").removeAttr("disabled")

  _getFormData: ->
    remoteListSelect = @$modal.find("#contact_list_remote_list_id")

    {
      name: @$modal.find("form #contact_list_name").val()
      provider: @$modal.find("form #contact_list_provider").val()
      double_optin: if @$modal.find("form #contact_list_double_optin").prop("checked") then "1" else "0"
      data:
        remote_id: $(remoteListSelect).val()
        remote_name: $(remoteListSelect).find("option:selected").text()
        embed_code: $('#contact_list_embed_code').val()
    }

  _renderBlock: (name, context, bind = true) ->
    block = @blocks[name].html(@templates[name](context))
    @_bindInteractions(block) if bind

    block

  _loadContactList: ->
    $.get @options.loadURL, (contactList) =>
      @options.contactList = $.extend(@options.contactList, data: contactList.data, name: contactList.name, id: contactList.id)
      @_setFormValues(contactList)
      @_loadRemoteLists(listData: contactList)

  _populateContactList: ->
    @_setFormValues(@options.contactList)
    @_loadRemoteLists(listData: @options.contactList)

  _loadRemoteLists: ({listData, select}) ->
    select ||= @$modal.find("#contact_list_provider")

    value = $(select).val()
    option = $(select).find("option:selected")
    label = option.text()
    defaultContext = 
      provider: value
      providerName: label
      requiresEmbedCode: option.data('requiresEmbedCode')
      contactList: @options.contactList

    if value == "0" # user selected "in Hello Bar only"
      @blocks.instructions.hide()
      @blocks.nevermind.hide()
      @blocks.remoteListSelect.hide()
      return

    @$modal.trigger 'load'

    $.get "/sites/#{@options.siteID}/identities/#{value}.json", (data) =>
      @$modal.trigger 'complete'

      if data and data.lists # an identity was found for the selected provider
        @blocks.instructions.hide()
        @blocks.nevermind.hide()
        @_renderBlock("remoteListSelect", $.extend(defaultContext, {identity: data})).show()

        if listData
          window.foo = listData
          @$modal.find("#contact_list_remote_list_id").val(listData.data.remote_id) if listData.data && listData.data.remote_id
          @$modal.find("#contact_list_double_optin").prop("checked", true) if listData.double_optin

      else # no identity found, or an embed provider
        @_renderBlock("nevermind", defaultContext).hide()
        @_renderBlock("instructions", defaultContext).show()
        @blocks.remoteListSelect.hide()

  _showErrors: (errors) ->
    return unless errors.length > 0
    html = "<div class=\"alert\">#{errors.reduce (a, b) -> "#{a}<br>#{b}"}</div>"
    @$modal.find(".modal-block").prepend(html)

  _clearErrors: ->
    @$modal.find(".alert").remove()

  _setFormValues: (data) ->
    @$modal.find("#contact_list_name").val(data.name)
    @$modal.find("#contact_list_provider").val(data.provider || "0")
    @$modal.find("#contact_list_double_optin").prop("checked", true) if data.double_optin
