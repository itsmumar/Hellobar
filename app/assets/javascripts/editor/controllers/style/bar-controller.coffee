HelloBar.StyleBarController = Ember.Controller.extend HelloBar.HasPlacement,

  sizeOptions: [
    {value: 'large', label: 'Large - 50px height, 17px font'}
    {value: 'regular', label: 'Regular - 30px height, 14px font'}
  ]

  placementOptions: [
    {value: 'bar-top', label: 'Top'}
    {value: 'bar-bottom', label: 'Bottom'}
  ]

  canWiggle: (->
    @get("model.element_subtype") == "traffic" || @get("model.element_subtype")  == "email"
  ).property("model.element_subtype")

  pushesText: (->
    if @get('selectedPlacement') == 'bar-top' then 'Pushes page down' else 'Pushes page up'
  ).property('selectedPlacement')

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