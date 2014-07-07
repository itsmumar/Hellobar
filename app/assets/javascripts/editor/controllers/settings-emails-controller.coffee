HelloBar.SettingsEmailsController = Ember.Controller.extend

  collectionOptions: [
    {id: 1, text: 'Just email addressses'}
    {id: 2, text: 'Just names & locations'}
    {id: 3, text: 'Names, locaitons & emails'}
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
