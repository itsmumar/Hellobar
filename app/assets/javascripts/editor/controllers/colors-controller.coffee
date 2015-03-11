HelloBar.ColorsController = Ember.Controller.extend

  needs: ['application']

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'text'

  #-----------  Color Tracking  -----------#

  # siteColors: ['def1ff', '4f4f4f', 'fffff', 'ff11dd']
  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff']

  focusedColor: Ember.computed.alias('controllers.application.focusedColor')
  showAdditionalColors: Ember.computed.equal('model.type', 'Bar')
