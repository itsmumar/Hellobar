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
  ).observes('routeForwarding')

  actions:

    changeStyle: ->
      @set('routeForwarding', false)
      @transitionToRoute('style')
      false
