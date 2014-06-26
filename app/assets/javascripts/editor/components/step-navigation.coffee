HelloBar.StepNavigationComponent = Ember.Component.extend

  tagName: 'nav'
  classNames: ['step-navigation']

  routes: ['settings', 'style', 'colors', 'text', 'targeting']

  # Component acts as Controller & View for the step navigation bar

  routeLinks: (->
    $.map @get('routes'), (route, i) =>
      {route: route, past: (i+1 < @get('current'))}
  ).property('current')