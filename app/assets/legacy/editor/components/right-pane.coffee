HelloBar.RightPaneComponent = Ember.Component.extend(
  classNames: [ 'right-pane' ]
  classNameBindings: ['componentIsDefined:visible']

  elementId: 'editor-right-pane'

  componentIsDefined: (->
    not not @get('componentName')
  ).property('componentName')

  componentName: null
  componentOptions: null

  context: Ember.computed(() -> this)

  init: ->
    HelloBar.bus.subscribe('hellobar.core.rightPane.show', (params) =>
      @setProperties({
        componentName: params.componentName
        componentOptions: params.componentOptions
      })
    )
    HelloBar.bus.subscribe('hellobar.core.rightPane.hide', (params) =>
      @setProperties({
        componentName: null
        componentOptions: null
      })
    )

  # TODO refactor this to generic solution after upgrading to Ember 2
  isThemeTileGridShown: (->
    @get('componentName') == 'theme-tile-grid'
  ).property('componentName')

  onComponentNameChange: (->
    # TODO refactor this jQuery usage after upgrading to Ember 2
    if @get('componentIsDefined')
      $('#editor-right-pane').show()
      $('#hellobar-preview-container').css('overflow-y', 'visible')
    else
      $('#editor-right-pane').hide()
      $('#hellobar-preview-container').css('overflow-y', 'hidden')
  ).observes('componentName')



)