class @ContactListModal extends Modal
  constructor: (options = {}) ->
    @_initializeTemplates()
    @_initializeBlocks()
    @_renderBlock("nameAndProvider")

    if options.load
      @_loadContactList(options.id, options.site_id)

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

  _bindProviderSelect: (object) ->
    modal = this

    object.find("#contact_list_provider").change (e) ->
      value = $(this).val()
      label = $(this).find("option:selected").text()

      context = {providerName: label}

      modal._renderBlock("nevermind", context).hide()
      modal._renderBlock("instructions", context).show()

  _bindDoThisLater: (object) ->
    modal = this

    object.find("a.do-this-later").click (e) ->
      modal.blocks.instructions.hide()
      modal.blocks.nevermind.show()
      modal.$modal.find("#contact_list_provider").val(0)

  _renderBlock: (name, context) ->
    block = @blocks[name].html(@templates[name](context))
    @_bindInteractions(block)

    block

  _loadContactList: (id, site_id) ->
    url = "/sites/#{site_id}/contact_lists/#{id}.json"

    $.get url, (data) =>
      @$modal.find("#contact_list_name").val(data.name)
