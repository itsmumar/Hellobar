HelloBar.SettingsController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 1
  prevStep: false
  nextStep: 'style.bar'

  #-----------  Sub-Step Selection  -----------#

  setSubtype: (->
    switch @get("routeForwarding")
      when "settings.emails"
        @set("model.element_subtype", "email")
      when "settings.click"
        @set("model.element_subtype", "traffic")
      when "settings.social"
        @set("model.element_subtype", "social/tweet_on_twitter")
  ).observes('routeForwarding')

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  actions:

    changeSettings: ->
      @set('routeForwarding', false)
      @replaceRoute('settings')
      false
