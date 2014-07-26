class @ContactListModal extends Modal
  constructor: (@$modal) ->
    @_bindInteractions()
    super

  _bindInteractions: ->
    @_bindProviderSelect()
    @_bindDoThisLater()

  _bindProviderSelect: ->
    modal = this

    @$modal.find("#contact_list_provider").change (e) ->
      value = $(this).val()
      label = $(this).find("option:selected").text()
      modal.$modal.find(".provider-name").html(label)
      modal.$modal.find(".provider-instructions-nevermind-block").hide()
      modal.$modal.find(".provider-instructions-block").show()

  _bindDoThisLater: ->
    modal = this

    @$modal.find("a.do-this-later").click (e) ->
      modal.$modal.find(".provider-instructions-block").hide()
      modal.$modal.find(".provider-instructions-nevermind-block").show()
      modal.$modal.find("#contact_list_provider").val(0)
