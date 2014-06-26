HelloBar.SettingsEmailsController = Ember.Controller.extend

  #-----------  Trigger Email Settings Modal  -----------#

  emailSync: (->
    @send('triggerModal', 'sync') if @get('content.storageSelection.id') == 3
  ).observes('content.storageSelection')
