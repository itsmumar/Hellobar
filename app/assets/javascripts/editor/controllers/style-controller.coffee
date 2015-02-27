HelloBar.StyleController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 2
  prevStep: 'settings'
  nextStep: 'colors'

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  setStyle: (->
    switch @get('routeForwarding')
      when 'style.modal'
        @set('model.element_style', 'modal')
      when 'style.slider'
        @set('model.element_style', 'slider')
      when 'style.takeover'
        @set('model.element_style', 'takeover')
      else
        @set('model.element_style', 'bar')
  ).observes('routeForwarding')

  actions:

    changeStyle: ->
      @set('routeForwarding', false)
      @transitionToRoute('style')
      false
