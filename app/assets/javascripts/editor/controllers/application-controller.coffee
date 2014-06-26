HelloBar.ApplicationController = Ember.Controller.extend

  queryPrams: ['modal']
  modal: null
  
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
      console.log 'full'
      false

    toggleMobile: ->
      @toggleProperty('isMobile')
      false

    #-----------  Trigger Actions  -----------#

    triggerComment: ->
      #

    triggerFAQ: ->
      #

    triggerClose: ->
      #

