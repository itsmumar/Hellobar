HelloBar.CustomProSelectComponent = Ember.Component.extend

  isOpen: false

  classNames        : ['custom-select-wrapper']
  classNameBindings : ['isOpen:is-open']

  _setSelectedOption: ( ->
    @set('currentChoice', @get('options').findBy('key', @get('choice')))
  ).observes('choice').on('init')

  click: ->
    @toggleProperty('isOpen')

  actions:

    optionSelected: (option) ->
      @sendAction('action', option)

#-----------  Custom Select Child Views  -----------#

HelloBar.CustomSelectOption = Ember.View.extend

  classNames: ['custom-select-option']

  click: ->
    @get('parentView').send('optionSelected', @get('option'))
