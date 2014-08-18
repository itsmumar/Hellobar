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
    @modal.close()

test "inserts the modal html", ->
  includes find(@modal.$modal).text(), "sync with an email service", "Modal HTML was not rendered"

test "header is \"New Contact List\" when creating a new list", ->
  includes find(@modal.$modal).text(), "New Contact List", "\"New Contact List\" not found in modal"

asyncTest "selecting a provider with no stored identities renders the provider instructions", ->
  expect(2)

  @modal.$modal.on "ajax-complete", =>
    text = find(@modal.$modal).text()
    includes text, "To integrate with AWeber you'll need", "Provider instructions not rendered"
    includes text, "Your AWeber username and password", "Provider instructions not rendered correctly"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("aweber").change()

asyncTest "selecting an embed provider with no stored identities renders the provider instructions", ->
  expect(2)

  @modal.$modal.on "ajax-complete", =>
    text = find(@modal.$modal).text()
    includes text, "To integrate with Mad Mimi you'll need", "Provider instructions not rendered"
    includes text, "Your embed code from Mad Mimi", "Provider instructions not rendered correctly"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("mad_mimi").change()

asyncTest "selecting \"in hello bar only\" does not render instructions", ->
  expect(1)

  @modal.$modal.on "ajax-complete", =>
    @modal.$modal.find("#contact_list_provider").val("0").change()
    ok @modal.blocks.instructions.is(":hidden"), "Provider instructions were rendered"
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
    equal @modal.$modal.find("#contact_list_remote_list_id option:selected").text(), "my cool list"
    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("mailchimp").change()

asyncTest "form data is serialized correctly", ->
  expect(4)

  @modal.$modal.on "ajax-complete", =>
    @modal.$modal.find("#contact_list_remote_list_id").val("2").change()
    @modal.$modal.find("#contact_list_name").val("my new contact list").change()
    formData = @modal._getFormData()

    equal formData.name, "my new contact list"
    equal formData.provider, "mailchimp"
    equal formData.data.remote_id, "2"
    equal formData.data.remote_name, "my other cool list"

    QUnit.start()

  @modal.$modal.find("#contact_list_provider").val("mailchimp").change()

asyncTest "selecting \"I'm ready\" redirects to the correct URL to begin the oauth handshake", ->
  expect(1)

  @modal.$modal.on "ajax-complete", =>
    @modal.$modal.find(".start-connect").click()
    includes @modal.options.window.location, "/sites/123/identities/new"

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


module "ContactListModal.open for edit via AJAX",
  setup: ->
    @modal = new ContactListModal(
      id: 1
      siteID: 123
      window: {location: ""}
      loadURL: "/sites/123/contact_lists/1.json"
    )

    $(document).ajaxComplete =>
      @modal.$modal.trigger("ajax-complete")

    $(document).ajaxStop =>
      @modal.$modal.trigger("ajax-stop")

  teardown: ->
    @modal.$modal.unbind("ajax-complete")
    @modal.$modal.unbind("ajax-stop")
    @modal.close()

test "header is \"Edit Contact List\" when editing", ->
  includes find(@modal.$modal).text(), "Edit Contact List", "\"Edit Contact List\" not found in modal"

asyncTest "populates the name of the contact list in the form", ->
  expect(1)

  @modal.$modal.on "ajax-complete", =>
    equal @modal.$modal.find("form #contact_list_name").val(), "Contact List Name"
    QUnit.start()

  @modal.open()

asyncTest "loads the remote list select if a provider with stored credentials is loaded", ->
  expect(1)

  @modal.$modal.on "ajax-stop", =>
    includes @modal.$modal.find("#contact_list_remote_list_id").text(), "my cool list"
    QUnit.start()

  @modal.open()

asyncTest "selects the persisted remote list if present", ->
  expect(2)

  @modal.$modal.on "ajax-stop", =>
    equal @modal.$modal.find("#contact_list_remote_list_id").val(), "2"
    equal @modal.$modal.find("#contact_list_remote_list_id option:selected").text(), "my other cool list"

    QUnit.start()

  @modal.open()

module "ContactListModal.open for edit via provided JavaScript object",
  setup: ->
    @modal = new ContactListModal(
      siteID: 123
      window: {location: ""}
      contactList:
        id: 1
        name: "my great contact list"
        provider: "0"
    )

    $(document).ajaxComplete =>
      @modal.$modal.trigger("ajax-complete")

  teardown: ->
    @modal.$modal.unbind("ajax-complete")
    @modal.close()

test "populates the name of the contact list in the form", ->
  @modal.open()
  equal @modal.$modal.find("form #contact_list_name").val(), "my great contact list"
