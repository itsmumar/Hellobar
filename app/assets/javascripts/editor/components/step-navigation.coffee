HelloBar.StepNavigationComponent = Ember.Component.extend

  classNames: ['step-navigation']
  classNameBindings: ['alternative']

  layoutName: ( ->
    return (if HB_EDITOR_VARIATION == 'navigation' then 'components/step-navigation2' else 'components/step-navigation1')
  ).property()

  alternative: ( ->
    return (HB_EDITOR_VARIATION == 'navigation')
  ).property()

  #-----------  Routeing  -----------#

  routes: ['settings', 'style.bar', 'colors', 'text', 'targeting']

  routeLinks: (->
    $.map @get('routes'), (route, i) =>
      {route: route, past: (i+1 < @get('current'))}
  ).property('current')

  #-----------  Save Actions  -----------#

  actions:

    saveSiteElement: ->
      @sendAction('action')    