HelloBar.ApplicationView = Ember.View.extend

  classNames: ['editor-wrapper']
  classNameBindings: ['isMobile', 'isFullscreen']

  #-----------  State Bindings  -----------#

  # Tracks the application state properties from the application router
  # and uses them to generate state-specific classes for CSS. All
  # animations are handled by CSS transitions and toggleing classes.

  isMobile: Ember.computed.alias('controller.isMobile')
  isFullscreen: Ember.computed.alias('controller.isFullscreen')

  #-----------  Click Action  -----------#

  click: (obj) ->
    isCanvas = $(obj.target)[0].localName == 'canvas'
    isColorSelect = $(obj.target).closest('.color-select-wrapper').length 

    unless isCanvas || isColorSelect
      @set('controller.focusedColor', null)