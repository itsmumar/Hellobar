HelloBar.InterstitialView = Ember.View.extend

  classNames: ['goal-interstitial']
  classNameBindings: ['transitioning']

  isTransitioning: false

  #-----------  Template Routing  -----------#

  # use specific templates depending on interstitial type

  templateName: ( ->
    type = @get('controller.interstitialType')
    return "interstitials/#{type}" if type
  ).property('controller.interstitialType')

  #-----------  Removal Animation  -----------#

  click: (evt) ->
    return false unless (evt.target.className == 'button save-editor')

    @set('transitioning', true)
    
    setTimeout =>
      @$().remove()
    , 1000