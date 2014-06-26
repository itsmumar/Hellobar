HelloBar.StylePopupController = Ember.Controller.extend

  themeSelection: null
  themeOptions: [
    {id: 1, text: 'Theme 1'}
    {id: 2, text: 'Theme 2'}
    {id: 3, text: 'Theme 3'}
  ]

  isBranded: true
  isAnimated: false

  placementSelection: null
  placementOptions: [
    {id: 1, text: 'Top'}
    {id: 2, text: 'Middle'}
    {id: 3, text: 'Bottom'}
  ]


