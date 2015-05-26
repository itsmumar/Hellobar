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

  selectedTrigger: ( (key, value) ->

    if arguments.length > 1
      @set('model.view_condition', value)
      return value
    else
      current_trigger = @get('model.view_condition')

      for val in this.triggerOptions
        return current_trigger if current_trigger == val.value

      if @triggerOptions != null && @triggerOptions.length > 0
        current_trigger = @triggerOptions[0].value
        @set('model.view_condition', current_trigger)

      current_trigger
  ).property()

  canSetViewTrigger: (->
    showViewCondition
  ).property('canSetViewTrigger')

  actions:

    popDelayTootlipModal: () ->
      new DelayTooltipModal().open()
