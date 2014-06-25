HelloBar.ApplicationController = Ember.Controller.extend

  #-----------  Default State Settings  -----------#

  isModal: false
  isMobile: false
  isFullscreen: false

  #-----------  Step Tracking  -----------#

  prevRoute: null 
  nextRoute: null
  currentStep: false

  #-----------  Actions  -----------#

  actions:

    #-----------  Toggle Actions  -----------#

    toggleFullscreen: ->
      @toggleProperty('isFullscreen')

    toggleMobile: ->
      @toggleProperty('isMobile')

    #-----------  Trigger Actions  -----------#

    triggerComment: ->
      #

    triggerFAQ: ->
      #

    triggerClose: ->
      #

