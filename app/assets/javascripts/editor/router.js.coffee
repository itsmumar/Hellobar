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
  
  @route 'targeting'