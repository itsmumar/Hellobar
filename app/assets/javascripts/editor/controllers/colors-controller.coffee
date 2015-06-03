HelloBar.ColorsController = Ember.Controller.extend

  needs: ['application']

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
