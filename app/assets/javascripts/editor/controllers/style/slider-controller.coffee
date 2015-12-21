HelloBar.StyleSliderController = Ember.Controller.extend HelloBar.HasPlacement, HelloBar.HasTriggerOptions,

  placementOptions: [
    {value: 'bottom-right', label: 'Bottom Right'}
    {value: 'top-right', label: 'Top Right'}
    {value: 'bottom-left', label: 'Bottom Left'}
    {value: 'top-left', label: 'Top Left'}
  ]
