HelloBar.StyleBarController = Ember.Controller.extend(HelloBar.HasPlacement, {

  sizeOptions: [
    {value: 'large', label: 'Large - 50px height, 17px font'}
    {value: 'regular', label: 'Regular - 30px height, 14px font'}
  ]

  placementOptions: [
    {value: 'bar-top', label: 'Top'}
    {value: 'bar-bottom', label: 'Bottom'}
  ]
})
