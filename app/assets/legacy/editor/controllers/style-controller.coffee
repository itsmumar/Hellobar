HelloBar.StyleController = Ember.Controller.extend

  #-----------  Step Settings  -----------#

  step: 2
  prevStep: 'settings'
  nextStep: 'design'

  themeSelectionInProgress: false

  init: ->
    HelloBar.bus.subscribe('hellobar.core.bar.themeChanged', (params) =>
      @set('model.theme_id', params.themeId)
    )
    HelloBar.bus.subscribe('hellobar.core.rightPane.show', (params) =>
      if params.componentName == 'theme-tile-grid'
        @set('themeSelectionInProgress', true)
    )
    HelloBar.bus.subscribe('hellobar.core.rightPane.hide', (params) =>
      @set('themeSelectionInProgress', false)
    )

  currentTheme: (->
    allThemes = availableThemes
    currentThemeId = @get('model.theme_id')
    currentTheme = _.find(allThemes, (theme) => currentThemeId == theme.id)
    currentTheme
  ).property('model.theme_id')

  currentThemeName: (->
    theme = @get('currentTheme')
    if theme then theme.name else ''
  ).property('currentTheme')

  shouldShowThemeInfo: (->
    @get('isModalType') and not @get('themeSelectionInProgress')
  ).property('themeSelectionInProgress', 'isModalType')

  #-----------  Sub-Step Selection  -----------#

  # Sets a property which tells the route to forward to a previously
  # selected child route (ie. sub-step)

  routeForwarding: false

  setType: (->
    switch @get('routeForwarding')
      when 'style.modal'
        @set('model.type', 'Modal')
      when 'style.slider'
        @set('model.type', 'Slider')
      when 'style.takeover'
        @set('model.type', 'Takeover')
      else
        @set('model.type', 'Bar')
    InternalTracking.track_current_person("Editor Flow", {step: "Style Settings", goal: @get("model.element_subtype")}) if trackEditorFlow
  ).observes('routeForwarding')

  trackStyleView: (->
    InternalTracking.track_current_person("Editor Flow", {step: "Choose Style", goal: @get("model.element_subtype")}) if trackEditorFlow && !Ember.isEmpty(@get('model'))
  ).observes('model').on('init')

  onElementTypeChanged: (->
    elementType = @get('model.type')
    if elementType == 'Modal'
      HelloBar.bus.trigger('hellobar.core.rightPane.show', {componentName: 'theme-tile-grid', componentOptions: {}})
    else
      HelloBar.bus.trigger('hellobar.core.rightPane.hide')
    HelloBar.inlineEditing.initializeInlineEditing(elementType)
  ).observes('model.type')


  #--- Theme change handling moved from design-controller ---
  themeChanged: Ember.observer('currentThemeName', ->
    Ember.run.next(@, ->
      @setProperties
        'model.image_placement'   : @getImagePlacement()
        #'model.use_default_image' : false
    )
  )

  getImagePlacement: ->
    positionIsSelectable  = @get('currentTheme.image.position_selectable')
    imageIsbackground     = (@get('model.image_placement') == 'background')
    positionIsEmpty       = Ember.isEmpty(@get('model.image_placement'))
    if !positionIsSelectable
      @get('currentTheme.image.position_default')
    else if imageIsbackground || positionIsEmpty
      @get('currentTheme.image.position_default')
    else
      @get('model.image_placement')

  #-------------------------------------------------------------

  isModalType: (->
    @get('model.type') == 'Modal'
  ).property('model.type')

  actions:

    changeStyle: ->
      @set('routeForwarding', false)
      @transitionToRoute('style')
      false

    changeTheme: ->
      confirmModal = null
      modalOptions = {
        title: 'Are you sure you want to change the theme?',
        text: 'We will save the content and style of your current theme before the update',
        confirmBtnText: 'Yes, Change The Theme',
        cancelBtnText: 'No, Keep The Theme',
        showCloseIcon: true,
        confirm: ->
          confirmModal.close()
          HelloBar.bus.trigger('hellobar.core.rightPane.show', {componentName: 'theme-tile-grid', componentOptions: {}})

      }
      confirmModal = new ConfirmModal(modalOptions)
      confirmModal.open()

