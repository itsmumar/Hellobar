HelloBar.Router.map ->
  
  @resource 'settings', ->
    @route 'emails'
    @route 'social'
    @route 'click'
    @route 'feedback'

  @resource 'style', ->
    @route 'bar'
    @route 'popup'

  @route 'colors'
  
  @route 'text'
  
  @resource 'targeting', ->
    @route 'immediately'
    @route 'leaving'
    @route 'scroll'
    @route 'delay'