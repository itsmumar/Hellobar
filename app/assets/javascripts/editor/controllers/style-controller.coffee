HelloBar.StyleController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 2
  prevStep: 'settings'
  nextStep: 'colors'

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  setType: (->
    switch @get('routeForwarding')
      when 'style.modal'
        @set('model.type', 'Modal')
      when 'style.slider'
        @set('model.type', 'Slider')
      when 'style.takeover'
        @set('model.type', 'Takeover')
      else
        @set('model.type', 'Bar')
    InternalTracking.track_current_person("Editor Flow", {step: "Style Settings", goal: @get("model.type")}) if trackEditorFlow
  ).observes('routeForwarding')

  trackStyleView: (->
    InternalTracking.track_current_person("Editor Flow", {step: "Choose Style", goal: @get("model.element_subtype")}) if trackEditorFlow
  ).on('init')

  actions:

    changeStyle: ->
      @set('routeForwarding', false)
      @transitionToRoute('style')
      false
