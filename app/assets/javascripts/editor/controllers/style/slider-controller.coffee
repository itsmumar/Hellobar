HelloBar.StyleSliderController = Ember.Controller.extend HelloBar.HasPlacement,

  placementOptions: [
    {value: 'bottom-right', label: 'Bottom Right'}
    {value: 'top-right', label: 'Top Right'}
    {value: 'bottom-left', label: 'Bottom Left'}
    {value: 'top-left', label: 'Top Left'}
  ]

  triggerOptions: [
    {value: 'immediately', label: 'Immediately'}
    {value: 'wait-5', label: '5 second delay'}
    {value: 'wait-10', label: '10 second delay'}
    {value: 'wait-60', label: '60 second delay'}
    {value: 'scroll-some', label: 'After scrolling a little'}
    {value: 'scroll-middle', label: 'After scrolling to middle'}
    {value: 'scroll-to-bottom', label: 'After scrolling to bottom'}
    {value: 'exit-intent', label: 'User intends to leave'}
  ]
