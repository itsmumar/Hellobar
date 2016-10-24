HelloBar.ContactListSelectComponent = Ember.Component.extend

  classNames        : ['contact-list-wrapper']
  classNameBindings : ['isOpen:is-open', 'hasContactList:has-list']
  attributeBindings : ['tabindex'] # to make component focusable

  tabindex: -1
  isOpen         : false
  hasContactList : Ember.computed.gt('options.length', 0)

  init: ->
    if @get('hasContactList') && Ember.isEmpty(@get('value'))
      @sendAction('setList', @get('options.firstObject.id'))

    @_super()

  _setSelectedList: ( ->
    value = @get('value') || 0
    list = @get('options').findBy('id', value)
    @set('selectedList', list || @get('options.firstObject'))
  ).observes('value').on('init')

  focusOut: ->
    event.stopPropagation()
    @set('isOpen', false)

  actions:

    toggleOpen: ->
      (typeof event == 'object') and (event.stopPropagation())
      @toggleProperty('isOpen')
      @.$el.find('.contact-list-dropdown').toggleClass('is-visible')

    newList: ->
      @sendAction('editList')

    editList: ->
      @sendAction('editList', @get('selectedList.id'))

    listSelected: (value) ->
      (typeof event == 'object') and (event.stopPropagation())
      @sendAction('setList', value)
      @set('value', value)
      @set('isOpen', false)
      @.$el.find('.contact-list-dropdown').toggleClass('is-visible')
