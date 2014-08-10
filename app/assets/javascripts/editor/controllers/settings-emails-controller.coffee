HelloBar.SettingsEmailsController = Ember.Controller.extend

  collectionOptions: [
    {value: 0, label: 'Just email addresses'}
    {value: 1, label: 'Names and email addresses'}
  ]

  contactListOptions: (->
    lists = @get("model.site.contact_lists").slice(0)
    lists.push({id: 0, name: "New contact list..."})
    lists
  ).property("model.site.contact_lists")

  popNewContactListModal: (->
    if @get("model.contact_list_id") == 0
      options =
        siteID: window.siteID
        saveURL: "/sites/#{siteID}/contact_lists.json"
        saveMethod: "POST"
        success: (data, modal) =>
          lists = @get("model.site.contact_lists").slice(0)
          lists.push({id: data.id, name: data.name})
          @set("model.site.contact_lists", lists)
          @set("model.contact_list_id", data.id)
          modal.$modal.remove()
        close: (modal) =>
          @set("model.contact_list_id", null)

      new ContactListModal(options).open()
  ).observes("model.contact_list_id")

  showEditContactListLink: (->
    id = @get("model.contact_list_id")
    id && id != 0
  ).property("model.contact_list_id")


  actions:

    popEditContactListModal: (id) ->
      options =
        id: id
        siteID: window.siteID
        loadURL: "/sites/#{siteID}/contact_lists/#{id}.json"
        saveURL: "/sites/#{siteID}/contact_lists/#{id}.json"
        saveMethod: "PUT"
        success: (data, modal) =>
          @get("model.site.contact_lists").forEach (list) ->
            Ember.set(list, "name", data.name) if list.id == data.id

          modal.close()

      new ContactListModal(options).open()
