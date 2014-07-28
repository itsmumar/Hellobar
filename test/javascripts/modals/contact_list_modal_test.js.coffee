#= require modal
#= require modals/contact_list_modal

module "ContactListModal.open",
  setup: ->
    @modal = new ContactListModal()
    @modal.open()

test "inserts the modal html", ->
  includes find(@modal.$modal).text(), "sync with an email service", "Modal HTML was not rendered"

test "selecting a provider renders the provider instructions", ->
  @modal.$modal.find("#contact_list_provider").val("mailchimp").change()
  includes find(@modal.$modal).text(), "To integrate with MailChimp you'll need", "Provider instructions not rendered"

  @modal.$modal.find("#contact_list_provider").val("aweber").change()
  includes find(@modal.$modal).text(), "To integrate with AWeber you'll need", "Provider instructions not rendered"

test "selecting \"I'll do this later\" sets the provider select back to 0 and resets the instruction text", ->
  expect(2)

  @modal.$modal.find("#contact_list_provider").val("mailchimp").change()
  modal = @modal

  click(@modal.$modal.find(".do-this-later")).andThen ->
    equal modal.$modal.find("#contact_list_provider").val(), "0"
    includes find(modal.$modal).text(), "No worries!", "Provider instructions not reset"
