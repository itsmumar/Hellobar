HelloBar.TextController = Ember.Controller.extend

  fontOptions: [
    {value: 'Helvetica,sans-serif', label: 'Helvetica'}
    {value: 'Arial,Helvetica,sans-serif', label: 'Arial'}
    {value: 'Georgia,serif', label: 'Georgia'}
    {value: 'Helvetica,Arial,sans-serif', label: 'Sans-Serif'}
  ]

  #-----------  Step Settings  -----------#

  step: 4
  prevStep: 'colors'
  nextStep: 'targeting'
