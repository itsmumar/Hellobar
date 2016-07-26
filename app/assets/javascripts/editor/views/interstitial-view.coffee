HelloBar.InterstitialView = Ember.View.extend
  click: (e) ->
    $target = $(e.target)
    $reveal = $target.closest(".reveal-wrapper")

    if $reveal.length
      $reveal.addClass("activated")
      
  didInsertElement: () ->
    InternalTracking.track_current_person("Editor Flow", {step: "Choose Goal"}) if trackEditorFlow


#
#  classNames: ['goal-interstitial']
#  classNameBindings: ['transitioning']
#
#  isTransitioning: false
#
#  closeView: ->
#    @set('transitioning', true)
#    setTimeout =>
#      @$().remove()
#    , 1000
#
#  didInsertElement: ->
#    @get('controller').on('viewClosed', this, this.closeView)
#
#  #-----------  Removal Animation  -----------#
#
#  click: (evt) ->
#    if evt.target.className.indexOf('cancel-button') > -1
#      $('.goal-interstitial').trigger("toggleGoalSelection")
#
#    return false
#
#HelloBar.InterstitialIndexView = HelloBar.InterstitialView.extend()
