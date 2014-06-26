HelloBar.TargetingModel = Ember.Object.create

  #-----------  Responses  -----------#

  isScroll: false
  scrollPercentage: null

  isElement: false
  elementTarget: null

  delayValue: null

  whoSelection: null
  whenSelection: null
  unitsSelections: null

  #-----------  Choices  -----------#

  whoOptions: [
    {id: 1, text: 'Everyone'}
    {id: 2, text: '/signup'}
    {id: 3, text: '/new'}
    {id: 4, text: '/new'}
    {id: 5, text: 'Only visitors on certain pages'}
    {id: 6, text: 'Only visitors during certain dates'}
    {id: 7, text: 'Other...'}
  ]

  whenOptions: [
    {route: null,                text: 'Show immediately'}
    {route: 'targeting.leaving', text: 'When a visitor is leaving'}
    {route: 'targeting.scroll',  text: 'After visitor scrolls'}
    {route: 'targeting.delay',   text: 'After a time delay'}
  ]

  unitsOptions: [
    {id: 1, text: 'hours'}
    {id: 2, text: 'minuts'}
    {id: 3, text: 'seconds'}
  ]
