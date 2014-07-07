HelloBar.ColorsController = Ember.Controller.extend

  themeOptions: [
    {id: 1, text: 'Theme 1'}
    {id: 2, text: 'Theme 2'}
    {id: 3, text: 'Theme 3'}
  ]

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'text'

  #-----------  Color Tracking  -----------#

  siteColors: ['def1ff', '4f4f4f', 'fffff', 'ff11dd']
  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff']

  actions: 

    toggleFocus: ->
      console.log 'Controller'
