HelloBar.ColorsController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'text'

  #-----------  Color Settings  -----------#

  backgroundColor: null
  textColor: null
  buttonTextColor: null
  buttonColor: null

  themeSelection: null
  themeOptions: [
    {id: 1, text: 'Theme 1'}
    {id: 2, text: 'Theme 2'}
    {id: 3, text: 'Theme 3'}
  ]
