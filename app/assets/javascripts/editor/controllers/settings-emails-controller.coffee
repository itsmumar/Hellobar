HelloBar.SettingsEmailsController = Ember.Controller.extend

  collectionOptions: [
    {value: 0, label: 'Just email addresses'}
    {value: 1, label: 'Names and email addresses'}
  ]

  storageOptions: [
    {id: 1, text: 'Store them in Hello Bar'}
    {id: 2, text: 'My own Google spreadsheet'}
    {id: 3, text: 'In da\' cloud, man'}
  ]

  #-----------  Trigger Email Settings Modal  -----------#

  emailSync: (->
    @send('triggerModal', 'sync') if @get('model.storage_selection.id') == 3
  ).observes('model.storage_selection')
