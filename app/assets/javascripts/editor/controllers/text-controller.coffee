HelloBar.TextController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 4
  prevStep: 'colors'
  nextStep: 'targeting'

  #-----------  Text Settings  -----------#

  barText: null
  lineText: null

  fontSelection: null
  fontOptions: [
    {id: 1, text: 'Halvetica'}
    {id: 2, text: 'Times New Roman'}
    {id: 3, text: 'Georgia'}
  ]
