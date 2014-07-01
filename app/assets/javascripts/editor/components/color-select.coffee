HelloBar.ColorSelectComponent = Ember.Component.extend

  classNames: ['color-select']
  classNameBindings: ['inFocus']

  inFocus: false

  cssStyle: (->
    'background-color:#' + @get('color')
  ).property('color')

  actions:

    toggleFocus: ->
      @toggleProperty('inFocus')
      @sendAction()


HelloBar.ColorPreview = Ember.View.extend

  tagName: 'li'
  classNames: ['color-preview']
  attributeBindings: ['style']

  style: (->
    'background-color:#' + @get('color')
  ).property('color')

  mouseDown: ->
    @set('parentView.color', @color)