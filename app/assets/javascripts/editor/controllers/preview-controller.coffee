HelloBar.PreviewController = Ember.Controller.extend

  needs: ['application']

  isMobile: Ember.computed.alias('controllers.application.isMobile')

  #-----------  Default State Settings  -----------#

  hasPreview: false
