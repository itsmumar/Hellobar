#= require application
#= require modal
#= require modals/contact_list_modal

context = describe
jasmine.clock().install()
templates =
  main: "<div>This modal is gonna rock your socks off</div>"
  instructions: "<div></div>"
  nevermind: "<div></div>"
  syncDetails: "<div></div>"
  remoteListSelect: "<div></div>"
  tagListSelect: "<div></div>"


describe "ContactListModal", ->
  context "when opening the modal", ->
    beforeEach ->
      @modal = new ContactListModal(
        siteID: 123
        templates: templates
        window: {location: ""}
      )

      @modal.open()
      jasmine.clock().tick(1)

    afterEach ->
      @modal.close()
      jasmine.clock().tick(501)

    it "inserts the modal html", ->
      expect(@modal.$modal.text()).toContain("This modal is gonna rock your socks off")

  context "header", ->
    beforeEach ->
      @modal = new ContactListModal(
        siteID: 123
        templates: templates
        window: {location: ""}
      )

    it "shows the correct header when there is no contact list id(new contact list)", ->
      expect(@modal._header()).toEqual("Set up your contact list and integration")

    it "shows the correct header when there is a contact list id(existing contact list)", ->
      modal = new ContactListModal(
        siteID: 123
        templates: templates
        id: 9001
        window: {location: ""}
      )

      expect(modal._header()).toEqual("Set up your contact list and integration")
