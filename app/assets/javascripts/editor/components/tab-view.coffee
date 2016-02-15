HelloBar.NavTabComponent = Ember.Component.extend(
  tagName: 'a'
  classNames: [ 'nav-pill' ]
  classNameBindings: [ 'isActive:active' ]
  attributeBindings: ['onSelection']
  isActive: (->
    @get('paneId') == @get('parentView.activePaneId')
  ).property('paneId', 'parentView.activePaneId')
  click: ->
    @get('parentView').setActivePane @get('paneId')
    @sendAction('doTabSelected', @get('onSelection'))
    return

  doTabSelected: 'doTabSelected'
)

HelloBar.TabPaneComponent = Ember.Component.extend(
  classNames: [ 'tab-pane' ]
  classNameBindings: [ 'isActive:active' ]
  attributeBindings: ['onSelection']
  isActive: (->
    @get('elementId') == @get('parentView.activePaneId')
  ).property('elementId', 'parentView.activePaneId')
  didInsertElement: ->
    @get('parentView.panes').pushObject
      paneId: @get('elementId')
      name: @get('name')
      action: @get('onSelection')
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

  # Listen for paneSelected changes.  When this is changed, grab the pane and
  # and set it as active.  'paneSelected' is the INDEX of the panes array.
  paneSelectedChange: (->
      this.setActivePane(this.get('panes')[this.get('paneSelected')].paneId)
  ).observes('paneSelected'),

  actions:
    doTabSelected: (action) ->
      if (action)
        @sendAction(action)
)

HelloBar.QuestionTabsComponent = HelloBar.TabViewComponent.extend(
  layoutName: (->
    'components/tab-view'
  ).property()

  showQuestion:  'showQuestion'
  showResponse1: 'showResponse1'
  showResponse2: 'showResponse2'
)
