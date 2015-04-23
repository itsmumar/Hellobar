HelloBar.StyleModalController = Ember.Controller.extend HelloBar.HasPlacement,

  placementOptions: [
    {value: 'middle', label: 'Middle'}
    {value: 'top', label: 'Top'}
  ]
  
  triggerOptions: [
    {value: 'immidiately', label: 'Immediately'}
    {value: 'wait', label: '5 second delay'}
    {value: 'scroll', label: 'After scrolling'}
  ]