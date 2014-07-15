HelloBar.StepNavigationComponent = Ember.Component.extend

  tagName: 'nav'
  classNames: ['step-navigation']

  routes: ['settings', 'style.bar', 'colors', 'text', 'targeting']

  routeLinks: (->
    $.map @get('routes'), (route, i) =>
      {route: route, past: (i+1 < @get('current'))}
  ).property('current')
