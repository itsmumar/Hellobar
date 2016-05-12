HelloBar.ColorsController = Ember.Controller.extend

  needs: ['application']

  #----------- Theme Settings  -----------#

  themeOptions: availableThemes

  themeChanged: Ember.observer 'model.theme_id', ->
    @set('themeChangeCount', (@get('themeChangeCount') || 0) + 1)
    if @get('themeChangeCount') > 1
      @applyThemeDefaults()

  applyThemeDefaults: ->
    foundTheme = _.find availableThemes, (theme) =>
      theme.id == @get('model.theme_id')

    if foundTheme && foundTheme.defaults[@get('model.type')]
      _.each foundTheme.defaults[@get('model.type')], (value, key) =>
        @set("model.#{key}", value)

  #-----------  Step Settings  -----------#

  step: 3
  prevStep: 'style'
  nextStep: 'text'

  #-----------  Color Tracking  -----------#

  recentColors : ['ffffff', 'ffffff', 'ffffff', 'ffffff']
  siteColors   : Ember.computed.alias('controllers.application.colorPalette')
  focusedColor : Ember.computed.alias('controllers.application.focusedColor')

  showAdditionalColors: Ember.computed.equal('model.type', 'Bar')

  trackColorView: (->
    InternalTracking.track_current_person("Editor Flow", {step: "Color Settings", goal: @get("model.element_subtype"), style: @get("model.type")}) if trackEditorFlow && !Ember.isEmpty(@get('model'))
  ).observes('model').on('init')

  actions:

    eyeDropperSelected: ->
      type = @get('model.type')
      if type == 'Modal' || type == 'Takeover'
        @set('focusedColor', null)
      false
