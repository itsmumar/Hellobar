HelloBar.ContactListSelectComponent = Ember.Component.extend

  classNames        : ['contact-list-wrapper']
  classNameBindings : ['isOpen:is-open', 'hasContactList:has-list']

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

  actions:

    toggleOpen: ->
      @toggleProperty('isOpen')

    newList: ->
      @sendAction('editList')

    editList: ->
      @sendAction('editList', @get('selectedList.id'))

    listSelected: (value) ->
      @sendAction('setList', value)
      @set('value', value)

#-----------  Contact List Child Views  -----------#

HelloBar.ContactListOption = Ember.View.extend

  classNames: ['contact-list-option']

  click: ->
    @get('parentView').send('listSelected', @get('option.id'))
