HelloBar.Router.map ->

  @route 'home', {path: '/'}

  @route 'settings', ->
    @route 'emails'
    @route 'social'
    @route 'click'
    @route 'call'
    @route 'feedback'
    @route 'announcement'

  @route 'style', ->
    @route 'bar'
    @route 'modal'
    @route 'slider'
    @route 'takeover'

  @route 'design'

  @route 'text'

  @route 'targeting', ->
    @route 'everyone'
    @route 'mobile'
    @route 'homepage'
    @route 'custom'
    @route 'saved'
    
  @route 'interstitial', ->
    @route 'call'
    @route 'money', path: 'promote'
    @route 'contacts'
    @route 'facebook'
