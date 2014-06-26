HelloBar.ApplicationView = Ember.View.extend

  classNames: ['editor-wrapper']
  classNameBindings: ['isMobile', 'isFullscreen']

  #-----------  State Bindings  -----------#

  # Tracks the application state properties from the application router
  # and uses them to generate state-specific classes for CSS. All
  # animations are handled by CSS transitions and toggleing classes.
    
  isMobile: Ember.computed.alias('controller.isMobile')
  isFullscreen: Ember.computed.alias('controller.isFullscreen')
