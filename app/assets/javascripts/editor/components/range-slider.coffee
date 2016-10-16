HelloBar.RangeSliderComponent = Ember.Component.extend

  classNames: ['range-slider']

  sliderEvents: Ember.A(['update'])

  min: 0
  max: 100,
  start: 0

  context: Ember.computed(() -> this)

  didInsertElement: ->
    startValue = @start or @min
    el = this.$('.js-slider')[0]
    noUiSlider.create(el, {
      start: [startValue],
      connect: [true, false],
      range: {
        min: @min,
        max: @max
      }
    })
    slider = el.noUiSlider
    @set('slider', slider)
    @sliderEvents.forEach((event) =>
      if not Ember.isEmpty(@get(event))
        slider.on(event, (values, handle) =>
          @sendAction(event, @get('slider').get())
        )
    )

  willDestroyElement: ->
    if @slider
      @sliderEvents.forEach((event) =>
        @slider.off(event)
      )
      @slider.destroy()

