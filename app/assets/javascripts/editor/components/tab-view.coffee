HelloBar.NavTabComponent = Ember.Component.extend(
  tagName: 'a'
  classNames: [ 'nav-pill' ]
  classNameBindings: [ 'isActive:active' ]
  attributeBindings: ['onSelection']
  isActive: (->
    @get('paneId') == @get('parentView.activePaneId')
  ).property('paneId', 'parentView.activePaneId')
  click: ->
    @get('parentView').setActivePane @get('paneId'), @get('name')
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
    if @get('parentView.model.' + @get('parentView.currentTabNameAttribute')) == @get('name')
      @get('parentView').setActivePane @get('elementId'), @get('name')
    if @get('parentView.activePaneId') == null
      @get('parentView').setActivePane @get('elementId'), @get('name')
    return
)

HelloBar.TabViewComponent = Ember.Component.extend(
  classNames: [ 'tab-view' ]
  attributeBindings: ['model', 'navigationName']
  activePaneId: null
  layoutName: (->
    'components/tab-view'
  ).property()
  didInsertElement: ->
    @set 'panes', []
    @set 'currentTabNameAttribute', 'current_' + @get('navigationName') + '_tab_name'
    return
  setActivePane: (paneId, name) ->
    if @get('activePaneId') == null
      @set 'activePaneId', paneId
    else if paneId != @get('activePaneId')
      @set 'activePaneId', paneId
      @set('model.' + @get('currentTabNameAttribute') , name)

  # Listen for paneSelected changes.  When this is changed, grab the pane and
  # and set it as active.
  paneSelectedChange: (->
    pane = this.get('panes')[this.get('model.paneSelectedIndex')]
    this.setActivePane(pane.paneId, pane.name)
  ).observes('paneSelectionCount')

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
