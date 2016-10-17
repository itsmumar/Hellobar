HelloBar.RangeSliderComponent = Ember.Component.extend

  classNames: ['range-slider']

  sliderEvents: Ember.A(['update'])

  min: 0
  max: 100,
  start: 0,

  leftLabel: null,
  rightLabel: null,

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
          value = @get('slider').get()
          value = if value then parseInt(value).toString() else '0';
          @updateHandleValue(value)
          @sendAction(event, value)
        )
    )
    @updateLayout()

  updateLayout: ->
    $slider = this.$('.js-slider')
    $ll = this.$('.js-left-label')
    if $ll.length > 0
      $slider.css('margin-left', $ll[0].offsetWidth + 15)
    $rl = this.$('.js-right-label')
    if $rl.length > 0
      $slider.css('margin-right', $rl[0].offsetWidth + 15)

  updateHandleValue: (value) ->
    this.$('.noUi-handle').text(value)

  willDestroyElement: ->
    if @slider
      @sliderEvents.forEach((event) =>
        @slider.off(event)
      )
      @slider.destroy()

