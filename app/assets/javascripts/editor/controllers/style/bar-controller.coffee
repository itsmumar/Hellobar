HelloBar.StyleBarController = Ember.Controller.extend HelloBar.HasPlacement, HelloBar.HasTriggerOptions, HelloBar.AfterConvertOptions,

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

  adoptedBarSize: (->
    size = @get('model.size')
    switch (size)
      when 'large' then 50
      when 'regular' then 30
      else parseInt(size)
  ).property('model.size')

  actions:
    barSizeUpdated: (value) ->
      console.log('sizeUpdated', value)
      @set('model.size', value)
