HelloBar.ApplicationView = Ember.View.extend

  classNames: ['editor-wrapper']
  classNameBindings: ['isMobile', 'isFullscreen']

  #-----------  State Bindings  -----------#

  isMobile: Ember.computed.alias('controller.isMobile')
  isFullscreen: Ember.computed.alias('controller.isFullscreen')

