HelloBar.ColorsController = Ember.Controller.extend

  needs: ['application']

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'text'

  #-----------  Color Tracking  -----------#

  focusedColor: Ember.computed.alias('controllers.application.focusedColor')

  # siteColors: ['def1ff', '4f4f4f', 'fffff', 'ff11dd']
  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff']
