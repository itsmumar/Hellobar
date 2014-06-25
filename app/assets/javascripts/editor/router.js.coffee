HelloBar.Router.map ->
  
  @resource 'settings', ->
    @route 'emails'
    @route 'social'
    @route 'cilck'
    @route 'feedback'

  @route 'style'

  @route 'colors'
  
  @route 'text'
  
  @route 'targeting'