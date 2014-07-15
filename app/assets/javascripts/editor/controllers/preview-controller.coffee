HelloBar.PreviewController = Ember.Controller.extend

  needs: ['application']

  isMobile: Ember.computed.alias('controllers.application.isMobile')

  updatePreview: ( ->
    this.get("controllers.application").renderPreview()
  ).observes("isMobile")
