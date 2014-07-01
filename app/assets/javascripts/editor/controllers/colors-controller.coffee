HelloBar.ColorsController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'text'

  #-----------  Color Tracking  -----------#

  siteColors: ['def1ff', '4f4f4f', 'fffff', 'ff11dd']
  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff']

  logger: (->
    console.log @get('recentColors')
  ).observes('recentColors')

  actions: 

    toggleFocus: ->
      console.log 'Controller'
