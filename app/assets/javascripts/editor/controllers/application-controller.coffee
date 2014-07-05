HelloBar.ApplicationController = Ember.Controller.extend
  
  #-----------  Step Tracking  -----------#

  # Tracks global step tracking 
  # (primarily observed by the step-navigation component)

  prevRoute: null 
  nextRoute: null
  currentStep: false

  #-----------  Color Palette  -----------#

  # Generates color palette from screengrab
  # (primarily observed by the color-picker component)

  colorPalette: []

  #-----------  Modal Triggers  -----------#

  # Query params are managed by the controller (and no the router)
  # This defines the acceptable params and toggles the modal property 
  # used to trigger the modal visibility.

  queryParams: ['modal']
  modal: null

  toggleModal: (->
    @toggleProperty('isModal')
  ).observes('modal')

  #-----------  State Default & Actions  -----------#

  # Tracks global application states & catches actions
  # (primarily observed by the application-view)

  isMobile: false
  isFullscreen: false
  saveSubmitted: false

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

    saveSiteElement: ->
      controller = this
      controller.toggleProperty('saveSubmitted')

      Ember.$.ajax
        type: "PUT"
        url: "/sites/#{window.siteID}/site_elements/#{window.barID}.json"
        contentType: "application/json"
        data: JSON.stringify(@get("model"))
        success: ->
          window.location = "/sites/#{window.siteID}/site_elements"
        error: ->
          controller.toggleProperty('saveSubmitted')
