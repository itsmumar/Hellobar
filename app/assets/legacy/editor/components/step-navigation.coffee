HelloBar.StepNavigationComponent = Ember.Component.extend

  classNames: ['step-navigation']

  layoutName: ( ->
    return ('components/step-navigation1') # HB_EDITOR_VARIATION
  ).property()

  #-----------  Routing  -----------#

  routes: ['settings', 'style', 'design', 'targeting']

  routeLinks: (->
    $.map @get('routes'), (route, i) =>
      {route: route, past: (i+1 < @get('current'))}
  ).property('current')

  #-----------  Save Actions  -----------#

  actions:

    saveSiteElement: ->
      @sendAction('action')
