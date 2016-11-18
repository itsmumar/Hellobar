HelloBar.CustomProSelectComponent = Ember.Component.extend

  isOpen: false
  tabindex: -1

  classNames        : ['custom-select-wrapper']
  classNameBindings : ['isOpen:is-open']
  attributeBindings : ['tabindex'] # to make component focusable

  _setSelectedOption: ( ->
    @set('currentChoice', @get('options').findBy('key', @get('choice')))
  ).observes('choice').on('init')

  focusOut: ->
    @set("isOpen", false)

  click: (event) ->
    event.stopPropagation()
    @toggleProperty("isOpen")
    @.$el.find('.custom-select-dropdown').toggleClass('is-visible')

  actions:

    optionSelected: (option) ->
      (typeof event == 'object') and (event.stopPropagation())
      @sendAction('action', option)
      @set("isOpen", false)
      @.$el.find('.custom-select-dropdown').removeClass('is-visible')
