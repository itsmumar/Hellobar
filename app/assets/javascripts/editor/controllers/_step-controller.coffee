HelloBar.StepController = Ember.Controller.extend

  needs: ['application']

  #-----------  Setp Settings  -----------#

  init: ->
    @_super()
    @get('controllers.application').setProperties
      currentStep: @get('setp')
      prevRoute: @get('prevStep')
      nextRoute: @get('nextStep')