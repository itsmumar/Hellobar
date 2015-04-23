HelloBar.StyleTakeoverController = Ember.Controller.extend HelloBar.HasPlacement,

  placementOptions: [
  ]

  triggerOptions: [
    {value: 'immidiately', label: 'Immediately'}
    {value: 'wait', label: '5 second delay'}
    {value: 'scroll', label: 'After scrolling'}
  ]
