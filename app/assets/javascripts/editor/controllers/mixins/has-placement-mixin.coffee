HelloBar.HasPlacement = Ember.Mixin.create

  selectedPlacement: ( (key, value) ->
    if arguments.length > 1
      @set('model.placement', value)
      return value
    else
      current_placement = @get('model.placement')
      
      for val in this.placementOptions
        return current_placement if current_placement == val.value

      if @placementOptions != null && @placementOptions.length > 0
        current_placement = @placementOptions[0].value
        @set('model.placement', current_placement)
      
      current_placement
  ).property()
