HelloBar.TextController = Ember.Controller.extend

  fontOptions: [
    {id: 1, text: 'Helvetica'}
    {id: 2, text: 'Times New Roman'}
    {id: 3, text: 'Georgia'}
    {id: 4, text: 'Sans-Serif'}
  ]

  #-----------  Step Settings  -----------#

  step: 4
  prevStep: 'colors'
  nextStep: 'targeting'
