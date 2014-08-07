HelloBar.SettingsEmailsController = Ember.Controller.extend

  collectionOptions: [
    {value: 0, label: 'Just email addresses'}
    {value: 1, label: 'Names and email addresses'}
  ]

  contactListOptions: (->
    list = @get("model.site.contact_lists")
    list.push({id: 0, name: "New contact list..."})
    list.slice(0, list.length) # for some reason this is necessary
  ).property("model.site.contact_lists")

  popNewContactListModal: (->
    if @get("model.contact_list_id") == 0
      options =
        siteID: window.siteID
        saveURL: "/sites/#{siteID}/contact_lists.json"
        saveMethod: "POST"
        success: (data) ->
          window.location = "/sites/#{window.siteID}/contact_lists/#{data.id}"

      new ContactListModal(options).open()
  ).observes("model.contact_list_id")
