#= require modal
#= require modals/contact_list_modal

module "ContactListModal.open",
  setup: ->
    @modal = new ContactListModal(
      siteID: 123
      window: {location: ""}
    )

    @modal.open()

    $(document).ajaxComplete =>
      @modal.$modal.trigger("ajax-complete")

  teardown: ->
    @modal.$modal.unbind("ajax-complete")


test "inserts the modal html", ->
  includes find(@modal.$modal).text(), "sync with an email service", "Modal HTML was not rendered"

asyncTest "selecting a provider with no stored identities renders the provider instructions", ->
  expect(1)

  @modal.$modal.on "ajax-complete", =>
    includes find(@modal.$modal).text(), "To integrate with AWeber you'll need", "Provider instructions not rendered"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("aweber").change()

asyncTest "selecting a provider with a stored identity does not render the provider instructions", ->
  expect(1)

  @modal.$modal.on "ajax-complete", =>
    ok find(@modal.$modal).text().indexOf("To integrate with MailChimp you'll need") == -1, "Provider instructions were rendered"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("mailchimp").change()

asyncTest "selecting a provider with a stored identity renders a dropdown of that identity's remote lists", ->
  expect(1)

  @modal.$modal.on "ajax-complete", =>
    equal @modal.$modal.find("#contact_list_remote_list_id").find("option:selected").text(), "my cool list"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("mailchimp").change()


asyncTest "selecting \"I'm ready\" redirects to the correct URL to begin the oauth handshake", ->
  expect(1)

  @modal.$modal.on "ajax-complete", =>
    @modal.$modal.find(".start-oauth").click()
    includes @modal.options.window.location, "/sites/123/identities/new/?provider=aweber"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("aweber").change()

asyncTest "selecting \"I'll do this later\" sets the provider select back to 0 and resets the instruction text", ->
  expect(2)

  @modal.$modal.on "ajax-complete", =>
    @modal.$modal.find(".do-this-later").click()
    equal @modal.$modal.find("#contact_list_provider").val(), "0"
    includes find(@modal.$modal).text(), "No worries!", "Provider instructions not reset"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("aweber").change()
