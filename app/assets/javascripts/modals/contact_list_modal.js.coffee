class @ContactListModal extends Modal

  constructor: (@options = {}) ->
    # A/B Variant
    @isVariant = (window.HB_EMAIL_INTEGRATION_TEST && HB_EMAIL_INTEGRATION_TEST == 'variant')
    @modalName = if @isVariant then 'contact-list-variant' else 'contact-list'

    @options.window ||= window
    @options.canDelete = (@options.canDelete != false)
    @options.templates ||= @_loadTemplates()

    @_initializeTemplates()
    @_initializeBlocks()

    @$modal.on 'load', -> $(this).addClass('loading')
    @$modal.on 'complete', -> $(this).removeClass('loading').finish()

    super(@$modal)

  close: ->
    @options.close(this) if @options.close
    super

  open: ->
    @_loadContactList() if @options.loadURL
    @_populateContactList() if @options.contactList
    @_bindInteractions(@$modal)
    @_setBlockVisibilty(true)

    super

  _hasSiteElements: ->
    num = @$modal.find("#contact_list_site_elements_count").val()
    parseInt(num) > 0

  _setBlockVisibilty: (initital = false)->
    listVal = @$modal.find("#contact_list_provider").val()

    # A/B Variant
    if @isVariant
      if initital
        @blocks.iconListing.show()
        @blocks.hellobarOnly.hide()
        @blocks.selectListing.hide()
      else if listVal == "0"
        @blocks.iconListing.hide()
        @blocks.hellobarOnly.show()
        @blocks.selectListing.hide()
      else
        @blocks.iconListing.hide()
        @blocks.hellobarOnly.hide()
        @blocks.selectListing.show()
    else
      if listVal == "0"
        @blocks.hellobarOnly.show()
      else
        @blocks.hellobarOnly.hide()

    @_setSideIcon() if initital && listVal != "0"

  _loadTemplates: ->
    # A/B Variant
    if @isVariant
      return {
        main             : $("#contact-list-variant-modal-template").html()
        instructions     : $("#contact-list-variant-modal-provider-instructions-template").html()
        nevermind        : $("#contact-list-variant-modal-provider-instructions-nevermind-template").html()
        syncDetails      : $("#contact-list-variant-modal-sync-details-template").html()
        remoteListSelect : $("#contact-list-variant-modal-remote-list-select-template").html()
        tagListSelect    : $("#contact-list-variant-modal-tag-select-template").html()
      }
    else
      return {
        main             : $("#contact-list-modal-template").html()
        instructions     : $("#contact-list-modal-provider-instructions-template").html()
        nevermind        : $("#contact-list-modal-provider-instructions-nevermind-template").html()
        syncDetails      : $("#contact-list-modal-sync-details-template").html()
        remoteListSelect : $("#contact-list-modal-remote-list-select-template").html()
        tagListSelect    : $("#contact-list-modal-tag-select-template").html()
      }

  _initializeTemplates: ->
    @templates =
      main             : Handlebars.compile(@options.templates.main)
      instructions     : Handlebars.compile(@options.templates.instructions)
      nevermind        : Handlebars.compile(@options.templates.nevermind)
      syncDetails      : Handlebars.compile(@options.templates.syncDetails)
      remoteListSelect : Handlebars.compile(@options.templates.remoteListSelect)
      tagListSelect    : Handlebars.compile(@options.templates.tagListSelect)

    @$modal = $(@templates.main({header: @_header()}))
    @$modal.appendTo($("body"))

  _header: ->
    # A/B Variant
    if @isVariant
      "Set up your contact list and integration"
    else if @options.id
      "Edit Contact List"
    else
      "Where do you want to store the emails we collect?"

  _initializeBlocks: ->
    # A/B Variant: iconListing, selectListing
    @blocks =
      iconListing      : @$modal.find(".primary-selection-block")
      selectListing    : @$modal.find(".secondary-selection-block")
      instructions     : @$modal.find(".provider-instructions-block")
      nevermind        : @$modal.find(".provider-instructions-nevermind-block")
      syncDetails      : @$modal.find(".sync-details-block")
      remoteListSelect : @$modal.find(".remote-list-select-block")
      hellobarOnly     : @$modal.find(".hellobar-only")
      tagListSelect    : @$modal.find(".tag-select-block")

  _bindInteractions: (object) ->
    if @isVariant
      @_bindCustomEvents(object)
      @_bindShowExpandedList(object)
      @_bindProviderRadio(object)
      @_bindSelectIcons(object)
      @_bindHbSelection(object)

    @_bindProviderSelect(object)
    @_bindDoThisLater(object)
    @_bindReadyButton(object)
    @_bindSubmit(object)
    @_bindDisconnect(object)
    @_bindDelete(object)
    @_bindTagAddition(object)
    @_bindTagRemove(object)
    @_bindCycleDay(object)

  # A/B Variant - Handles custom event triggers for new UI pieces
  _bindCustomEvents: (object) ->
    selectList  = object.find('#contact_list_provider')

    object.on 'provider:connected', (evt) =>
      selectList.parent().addClass('connected')
      @blocks.selectListing.show()
      @blocks.hellobarOnly.hide()
      @blocks.iconListing.hide()

    object.on 'provider:disconnected', (evt) ->
      selectList.parent().removeClass('connected')

  # A/B Variant - Handles the expanded icon list toggling
  _bindShowExpandedList: (object) ->
    providerList = object.find('.contact-list-radio-wrapper')
    expandLabel  = object.find('.show-expanded-providers')

    expandLabel.on 'click', (evt) ->
      providerList.toggleClass('expanded')

  # A/B Variant - Handles the icon block selections
  _bindProviderRadio: (object) ->
    radioInputs = object.find('input[type = radio][name = "contact_list[provider]"]')
    selectList  = object.find('#contact_list_provider')
    blocks      = @blocks

    radioInputs.on 'change', (e) ->
      selectList.val(this.value).trigger('change')
      blocks.iconListing.hide()
      blocks.selectListing.show()

  # A/B Variant - Handles the select dropdown icon rendering
  _bindSelectIcons: (object) ->
    selectList = object.find('#contact_list_provider')

    selectList.on 'change', (e) =>
      selectList.parent().removeClass('connected')
      @_setBlockVisibilty()
      @_setSideIcon()

  # A/B Variant - Set the icon beside the dropdown
  _setSideIcon: ->
    provider  = @$modal.find('#contact_list_provider').val()
    listImage = @$modal.find(".contact-list-radio-block.#{provider}-provider img").clone()

    @$modal.find('.select-side-icon').html(listImage)

  # A/B Variant - Handles the "I don't use these tools" HB integration selection
  _bindHbSelection: (object) ->
    useHbOnly    = object.find('.use-hello-bar-email-lists')
    noHbOnly     = object.find('.back-to-providers')
    providerList = object.find('.contact-list-radio-wrapper')
    selectList   = object.find('#contact_list_provider')
    blocks       = @blocks

    useHbOnly.on 'click', (evt) ->
      selectList.val('0').trigger('change')

    noHbOnly.on 'click', (evt) ->
      providerList.addClass('expanded')
      blocks.selectListing.hide()
      blocks.hellobarOnly.hide()
      blocks.iconListing.show()

  _bindProviderSelect: (object) ->
    modal = this

    object.find("#contact_list_provider").change (e) ->
      modal._loadRemoteLists(select: this, listData: {double_optin: true})

  _bindDisconnect: (object) ->
    modal = this
    object.find("a.unlink").click (e) ->
      $.ajax "/sites/#{modal.options.siteID}/identities/#{$(this).data('identity-id')}",
        type: "DELETE"
        success: (data) =>
          modal.blocks.instructions.show()
          modal.blocks.syncDetails.hide()
          modal.blocks.remoteListSelect.hide()
          modal.$modal.trigger('provider:disconnected')
        error: (response) =>
          console.log("Could not disconnect identity", response)

  _bindDoThisLater: (object) ->
    object.find("a.do-this-later").click (e) =>
      @blocks.instructions.hide()
      @blocks.nevermind.show()
      @$modal.find("#contact_list_provider").val(0)

  _bindReadyButton: (object) ->
    object.find("a.ready").click (e) =>
      @_clearErrors()

      if @_requiredFieldsAreValid()
        # stash the model so that it can be reloaded by the ember app
        localStorage["stashedEditorModel"] = JSON.stringify(@options.editorModel) if @options.editorModel
        localStorage["stashedContactList"] = JSON.stringify($.extend(@_getFormData(), {id: @options.id}))

        newPath = "/sites/#{@options.siteID}/identities/new?provider=#{@_getFormData().provider}"
        queryParams = {}
        queryParams["api_key"]  = @_getFormData().data.api_key
        queryParams["username"] = @_getFormData().data.username
        queryParams["app_url"]  = @_getFormData().data.app_url
        newPath += "&" + $.param(queryParams)

        @options.window.location = newPath

  _bindSubmit: (object) ->
    object.find("a.submit").click (e) =>
      @_doSubmit(e)

    object.find("form.contact_list").submit (e) =>
      e.preventDefault()
      @_doSubmit(e)

  _bindDelete: (object) ->
    object.find("a.delete-confirm").click (e) =>
      e.preventDefault()
      @_confirmDelete(e)

    object.find("a.delete").click (e) =>
      e.preventDefault()
      @_doDelete(e)

  _bindCycleDay: (object) ->
    object.find("input#contact_list_cycle_day_enabled").on "change", (event) ->
      cycleDayEnabled = $(event.target).prop('checked')

      $("input#contact_list_cycle_day").prop("disabled", !cycleDayEnabled)
                                       .toggle(cycleDayEnabled)

  _bindTagAddition: (object) ->
    object.on "click", "a[data-js-action=add-tag]", (event) =>
      event.preventDefault()

      source = $('script#tag-dropdown-template').html()
      template = Handlebars.compile(source)
      newMarkup = template(identity: @options.identity)
      $previous = object.find(".select-wrapper:last")

      $(newMarkup).insertAfter($previous)

  _bindTagRemove: (object) ->
    object.on "click", "i[data-js-action=remove-tag]", (event) ->
      $(event.target)
        .parents('.select-wrapper')
        .remove()

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
        @_displayErrors(contactList.errors)
        @$modal.find("a.submit").removeAttr("disabled")

  _confirmDelete: (e) =>
    @$modal.find("#contact-list-form").hide()
    @$modal.find("#contact-list-delete").show()

    confirmOnly = @$modal.find(".confirm-delete-contact-list")
    deleteOptions = @$modal.find(".delete-contact-list")

    if @_hasSiteElements()
      confirmOnly.hide()
      deleteOptions.show()
    else
      confirmOnly.show()
      deleteOptions.hide()

  _doDelete: (e) =>
    data = @$modal.find("form.delete-contact-list").serialize()

    $.ajax @options.loadURL,
      type: 'DELETE'
      data: data
      success: (data) =>
        @options.destroyed(data, this)
      error: (response) =>
        data = response.responseJSON
        @_displayErrors(data.errors)

  _getFormData: ->
    {
      name         : @$modal.find("form #contact_list_name").val()
      provider     : @$modal.find("form #contact_list_provider").val()
      double_optin : if @$modal.find("#contact_list_double_optin").prop("checked") then "1" else "0"
      data         : @_getContactListData()
    }

  _getContactListData: ->
    if @_isLocalContactStorage() then return {}
    remoteListSelect = @$modal.find("#contact_list_remote_list_id")
    data =
      remote_id   : $(remoteListSelect).val()
      remote_name : $(remoteListSelect).find("option:selected").text()
      embed_code  : $('#contact_list_embed_code').val()

    api_key         = $('#contact_list_api_key').val()
    username        = $('#contact_list_username').val()
    app_url         = $('#contact_list_app_url').val()
    webhook_url     = $('#contact_list_webhook_url').val()
    webhook_method  = if $('#contact_list_webhook_method').prop('checked') then "post" else "get"
    tags            = (tag.value for tag in $(".contact-list-tag"))
    $cycle_day      = $('#contact_list_cycle_day')

    if $('#contact_list_cycle_day_enabled').prop('checked')
      cycle_day = $cycle_day.val()
    else
      cycle_day = null

    if api_key        then data.api_key = api_key
    if username       then data.username = username
    if app_url        then data.app_url = app_url
    if webhook_url    then data.webhook_url = webhook_url
    if webhook_method then data.webhook_method = webhook_method
    if cycle_day      then data.cycle_day = cycle_day
    if tags.length    then data.tags = tags

    data

  _isLocalContactStorage: ->
    @$modal.find("form #contact_list_provider").val() == "0"

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

  _showListInstructions: (context) ->
    @_renderBlock("nevermind", context).hide()
    @_renderBlock("instructions", context).show()
    @blocks.remoteListSelect.hide()
    @blocks.tagListSelect.hide()
    @blocks.hellobarOnly.hide()
    @blocks.syncDetails.hide()

  _loadRemoteLists: ({listData, select}) ->
    select ||= @$modal.find("#contact_list_provider")

    value = $(select).val()
    option = $(select).find("option:selected")
    label = option.text()
    cycle_day = @options.contactList?.data?.cycle_day
    cycle_day_enabled = cycle_day != undefined

    defaultContext =
      provider: value
      providerName: label
      isProviderConvertKit: (label == 'ConvertKit')
      oauth: option.data('oauth')
      requiresEmbedCode: option.data('requiresEmbedCode')
      requiresAppUrl: option.data('requiresAppUrl')
      requiresAccountId: option.data('requiresAccountId')
      requiresApiKey: option.data('requiresApiKey')
      requiresUsername: option.data('requiresUsername')
      requiresWebhookUrl: option.data('requiresWebhookUrl')
      webhookIsPost: @options.contactList?.data?.webhook_method == "post"
      contactList: @options.contactList
      cycleDayEnabled: cycle_day_enabled
      cycleDay: cycle_day || 0
      tags: @options.contactList?.data?.tags
      providerNameLabel: (label + ' ' + switch label
                                          when 'Drip' then 'campaign'
                                          when 'ConvertKit' then 'form'
                                          else 'list')

    if value == "0" # user selected "in Hello Bar only"
      @blocks.hellobarOnly.show()
      @blocks.instructions.hide()
      @blocks.nevermind.hide()
      @blocks.syncDetails.hide()
      @blocks.remoteListSelect.hide()
      @blocks.tagListSelect.hide()
      return

    @$modal.trigger 'load'

    $.get("/sites/#{@options.siteID}/identities/#{value}.json", (data) =>
      if data and (data.lists or data.tags) # an identity was found for the selected provider
        @blocks.hellobarOnly.hide()
        @blocks.instructions.hide()
        @blocks.nevermind.hide()
        @blocks.tagListSelect.hide()
        @$modal.trigger('provider:connected')
        @_renderBlock("syncDetails", $.extend(defaultContext, {identity: data})).show()
        @_renderBlock("instructions", defaultContext).hide()
        @options.identity = data

        if data.provider == "infusionsoft" or data.provider == "convert_kit"
          if data.provider == "convert_kit"
            @_renderBlock("remoteListSelect", $.extend(defaultContext, {identity: data})).show()

          tagsContext = $.extend(true, {}, defaultContext, {identity: data})
          tagsContext.preparedLists = (tagsContext.tags or []).map((tag) =>
            clonedTags = $.extend(true, [], tagsContext.identity.tags)
            clonedTags.forEach((clonedTag) =>
              clonedTag.isSelected = if String(clonedTag.id) == tag then true else false
            )
            { tag: tag, lists: clonedTags}
          )
          @_renderBlock("tagListSelect", tagsContext, false).show()
        else
          @_renderBlock("remoteListSelect", $.extend(defaultContext, {identity: data})).show()
          $cycle_day = $('#contact_list_cycle_day')
          if ($cycle_day).length
            $cycle_day.toggle(cycle_day_enabled)

        if listData
          @$modal.find("#contact_list_remote_list_id").val(listData.data.remote_id) if listData.data && listData.data.remote_id
          @$modal.find("#contact_list_double_optin").prop("checked", true) if listData.double_optin

      else # no identity found, or an embed provider
        @_showListInstructions(defaultContext)
      ).fail( =>
        @_showListInstructions(defaultContext)
      ).always( =>
        @$modal.trigger 'complete'
      )

  _setFormValues: (data) ->
    @$modal.find("#contact_list_name").val(data.name)
    @$modal.find("#contact_list_provider").val(data.provider || "0").trigger('change')
    @$modal.find("#contact_list_double_optin").prop("checked", true) if data.double_optin
    @$modal.find("#contact_list_site_elements_count").val(data.site_elements_count || 0)
    @$modal.find("a.delete-confirm").removeClass('hidden') if @options.canDelete && @options.id

  _validateRequiredField: (element) ->
    if element.length
      element.removeClass('invalid-field')
      if element.val().length == 0
        element.addClass('invalid-field')
        return false
    return true

  _requiredFieldsAreValid: ->
    validityAry = []
    validityAry.push @_validateRequiredField($('.contact_list_api_key'))
    validityAry.push @_validateRequiredField($('.contact_list_app_url'))
    validityAry.push @_validateRequiredField($('.contact_list_embed_code'))

    if $.inArray(false, validityAry) != -1
      return false # if any validations are false
    else
      return true
