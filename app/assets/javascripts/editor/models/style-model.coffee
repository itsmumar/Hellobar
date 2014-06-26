HelloBar.StyleModel = Ember.Object.create

  #-----------  Responses  -----------#

  barIsBranded: true
  barIsAnimated: false
  barIsHidable: true

  popupIsBranded: true
  popupIsAnimated: false

  barThemeSelection: null
  popupThemeSelection: null

  barPlacementSelection: null
  barPlacementSelection: null

  #-----------  Choices  -----------#

  themeOptions: [
    {id: 1, text: 'Theme 1'}
    {id: 2, text: 'Theme 2'}
    {id: 3, text: 'Theme 3'}
  ]

  placementOptions: [
    {id: 1, text: 'Top'}
    {id: 2, text: 'Bottom'}
  ]

