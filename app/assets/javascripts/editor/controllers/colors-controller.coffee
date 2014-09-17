HelloBar.ColorsController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style.bar'
  nextStep: 'text'

  #-----------  Color Tracking  -----------#

  # siteColors: ['def1ff', '4f4f4f', 'fffff', 'ff11dd']
  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff']

  actions: 

    toggleFocus: ->
      console.log 'Controller'
