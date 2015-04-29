HelloBar.StyleModalController = Ember.Controller.extend HelloBar.HasPlacement,

  placementOptions: [
    {value: 'middle', label: 'Middle'}
    {value: 'top', label: 'Top'}
  ]
  
  triggerOptions: [
    {value: 'immidiately', label: 'Immediately', attribute: 0}
    {value: 'wait', label: '5 second delay', attribute: 5}
    {value: 'wait', label: '10 second delay', attribute: 10}
    {value: 'wait', label: '60 second delay', attribute: 60}
    {value: 'scroll', label: 'After scrolling a little', attribute: 500}
    {value: 'scroll', label: 'After scrolling a lot', attribute: 1000}
    {value: 'scroll', label: 'After scrolling near bottom', attribute: -200}
  ]