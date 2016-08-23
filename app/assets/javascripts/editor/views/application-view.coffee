HelloBar.ApplicationView = Ember.View.extend

  classNames: ['editor-wrapper']
  classNameBindings: ['isMobile', 'isFullscreen', 'isCallType']

  #-----------  State Bindings  -----------#

  # Tracks the application state properties from the application router
  # and uses them to generate state-specific classes for CSS. All
  # animations are handled by CSS transitions and toggleing classes.

  isMobile: Ember.computed.alias('controller.isMobile')
  isFullscreen: Ember.computed.alias('controller.isFullscreen')
  isCallType: Ember.computed.equal('controller.model.element_subtype', 'call')

  #-----------  Click Action  -----------#

  click: (obj) ->
    isCanvas = obj.target.localName == 'canvas'
    isColorSelect = $(obj.target).closest('.color-select-wrapper').length

    unless isCanvas || isColorSelect
      @set('controller.focusedColor', null)
