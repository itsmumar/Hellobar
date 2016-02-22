HelloBar.Router.map ->

  @route 'home', {path: '/'}

  @resource 'settings', ->
    @route 'emails'
    @route 'social'
    @route 'click'
    @route 'call'
    @route 'feedback'
    @route 'announcement'

  @resource 'style', ->
    @route 'bar'
    @route 'modal'
    @route 'slider'
    @route 'takeover'

  @route 'colors'

  @route 'text'

  @resource 'targeting', ->
    @route 'immediately'
    @route 'leaving'
    @route 'scroll'
    @route 'delay'
