HelloBar.NavTabComponent = Ember.Component.extend(
  tagName: 'li'
  classNames: [ 'nav-pill' ]
  classNameBindings: [ 'isActive:active' ]
  attributeBindings: ['previewAction']
  isActive: (->
    @get('paneId') == @get('parentView.activePaneId')
  ).property('paneId', 'parentView.activePaneId')
  click: ->
    @get('parentView').setActivePane @get('paneId')
    @sendAction('updatePreview', @get('previewAction'))
    return

  updatePreview: 'updatePreview'
)

HelloBar.TabPaneComponent = Ember.Component.extend(
  classNames: [ 'tab-pane' ]
  classNameBindings: [ 'isActive:active' ]
  attributeBindings: ['previewAction']
  isActive: (->
    @get('elementId') == @get('parentView.activePaneId')
  ).property('elementId', 'parentView.activePaneId')
  didInsertElement: ->
    @get('parentView.panes').pushObject
      paneId: @get('elementId')
      name: @get('name')
      action: @get('previewAction')
    if @get('parentView.activePaneId') == null
      @get('parentView').setActivePane @get('elementId')
    return
)

HelloBar.TabViewComponent = Ember.Component.extend(
  classNames: [ 'tab-view' ]
  activePaneId: null
  layoutName: (->
    'components/tab-view'
  ).property()
  didInsertElement: ->
    @set 'panes', []
    return
  setActivePane: (paneId) ->
    if @get('activePaneId') != null
      if paneId != @get('activePaneId')
        @set 'activePaneId', paneId
    else
      @set 'activePaneId', paneId
    return

  showQuestion: 'showQuestion'
  showResponse1: 'showResponse1'
  showResponse2: 'showResponse2'

  actions:
    updatePreview: (action) ->
      @sendAction(action)

)
