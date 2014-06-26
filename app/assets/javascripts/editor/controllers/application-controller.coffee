HelloBar.ApplicationController = Ember.Controller.extend
  
  #-----------  Modal Triggers  -----------#

  queryParams: ['modal']
  modal: null

  toggleModal: (->
    @toggleProperty('isModal')
  ).observes('modal')

  #-----------  Step Tracking  -----------#

  prevRoute: null 
  nextRoute: null
  currentStep: false

  #-----------  State Default & Actions  -----------#

  isMobile: false
  isFullscreen: false

  actions:

    toggleFullscreen: ->
      @toggleProperty('isFullscreen')
      console.log 'full'
      false

    toggleMobile: ->
      @toggleProperty('isMobile')
      false

    toggleModal: ->
      @set('modal', null)
      false

    #-----------  Trigger Actions  -----------#

    triggerComment: ->
      #

    triggerFAQ: ->
      #

    triggerClose: ->
      #

