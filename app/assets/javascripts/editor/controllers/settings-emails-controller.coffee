HelloBar.SettingsEmailsController = Ember.Controller.extend

  collectionOptions: [
    {value: 0, label: 'Just email addresses'}
    {value: 1, label: 'Names and email addresses'}
  ]

  contactListOptions: (->
    window.foo = @get("model.site.contact_lists")
    list = @get("model.site.contact_lists")
    list.slice(0, list.length) # for some reason this is necessary
  ).property("model.site.contact_lists")
