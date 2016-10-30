HelloBar.ThemeTileComponent = Ember.Component.extend

  classNames: ['theme-tile']

  theme: null

  imageSrc: (->
    '/assets/themes/tiles/modal/' + @get('theme.id') + '.png'
  ).property('theme')

  init: ->
    @_super()

  selectButtonIsVisible: false

  mouseEnter: ->
    @set('selectButtonIsVisible', true)

  mouseLeave: ->
    @set('selectButtonIsVisible', false)

  actions: {
    select: ->
      HelloBar.bus.trigger('hellobar.core.bar.themeChanged', { themeId: @get('theme.id') })
      HelloBar.bus.trigger('hellobar.core.rightPane.hide')
  }


