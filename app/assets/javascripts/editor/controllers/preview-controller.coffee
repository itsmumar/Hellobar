HelloBar.PreviewController = Ember.Controller.extend

  needs: ['application']

  isMobile: Ember.computed.alias('controllers.application.isMobile')
