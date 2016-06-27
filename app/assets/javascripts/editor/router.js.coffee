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

  @route 'design'

  @route 'text'

  @resource 'targeting', ->
    @route 'everyone'
    @route 'mobile'
    @route 'homepage'
    @route 'custom'
    @route 'saved'
