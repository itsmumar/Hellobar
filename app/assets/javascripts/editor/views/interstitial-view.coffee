HelloBar.InterstitialView = Ember.View.extend

  classNames: ['goal-interstitial']
  classNameBindings: ['transitioning']

  isTransitioning: false

  #-----------  Removal Animation  -----------#

  click: (evt) ->
    switch evt.target.className
  
      when 'button save-editor'
        @set('transitioning', true)      
        setTimeout =>
          @$().remove()
        , 1000
  
      when 'button cancel-button cancel'
        $('.goal-interstitial').trigger("toggleGoalSelection")

    return false

