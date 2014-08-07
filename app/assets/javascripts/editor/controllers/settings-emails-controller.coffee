HelloBar.SettingsEmailsController = Ember.Controller.extend

  collectionOptions: [
    {value: 0, label: 'Just email addresses'}
    {value: 1, label: 'Names and email addresses'}
  ]

  setContactListOptions: (->
    lists = @get("model.site.contact_lists").slice(0)
    lists.push({id: 0, name: "New contact list..."})
    @set("contactListOptions", lists)
  ).observes("model.site.contact_lists")

  popNewContactListModal: (->
    if @get("model.contact_list_id") == 0
      options =
        siteID: window.siteID
        saveURL: "/sites/#{siteID}/contact_lists.json"
        saveMethod: "POST"
        success: (data, modal) =>
          lists = @get("model.site.contact_lists")
          lists.push({id: data.id, name: data.name})
          @set("model.site.contact_lists", lists)
          @setContactListOptions() # for some reason this is necessary
          @set("model.contact_list_id", data.id)
          modal.$modal.remove()
        close: (modal) =>
          @set("model.contact_list_id", null)

      new ContactListModal(options).open()
  ).observes("model.contact_list_id")
