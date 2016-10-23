HelloBar.StyleModalController = Ember.Controller.extend(HelloBar.HasPlacement, HelloBar.HasTriggerOptions, HelloBar.AfterConvertOptions, {

  placementOptions: [
    {value: 'middle', label: 'Middle'},
    {value: 'top', label: 'Top'}
  ]
});
