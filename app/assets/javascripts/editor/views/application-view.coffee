HelloBar.ApplicationView = Ember.View.extend

  classNames: ['editor-wrapper']
  classNameBindings: ['isModal', 'isMobile', 'isFullscreen']

  #-----------  State Bindings  -----------#

  isModal: Ember.computed.alias('controller.isModal')
  isMobile: Ember.computed.alias('controller.isMobile')
  isFullscreen: Ember.computed.alias('controller.isFullscreen')
