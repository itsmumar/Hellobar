HelloBar.PreviewController = Ember.Controller.extend

  needs: ['application']

  isMobile: Ember.computed.alias('controllers.application.isMobile')
  isPushed: Ember.computed.alias('model.pushes_page_down')
