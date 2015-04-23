HelloBar.StyleSliderController = Ember.Controller.extend HelloBar.HasPlacement,

  placementOptions: [
    {value: 'bottom-right', label: 'Bottom Right'}
    {value: 'top-right', label: 'Top Right'}
    {value: 'bottom-left', label: 'Bottom Left'}
    {value: 'top-left', label: 'Top Left'}
  ]

  triggerOptions: [
    {value: 'immidiately', label: 'Immediately'}
    {value: 'wait', label: '5 second delay'}
    {value: 'scroll', label: 'After scrolling'}
  ]