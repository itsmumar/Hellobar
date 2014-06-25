HelloBar.ApplicationController = Ember.Controller.extend

  #-----------  Default State Settings  -----------#

  isModal: false
  isMobile: false
  isFullscreen: false

  #-----------  Step Tracking  -----------#

  currentStep: 0
  prevRoute: null 
  nextRoute: null

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

