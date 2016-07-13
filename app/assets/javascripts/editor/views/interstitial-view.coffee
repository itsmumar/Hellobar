HelloBar.InterstitialView = Ember.View.extend

  classNames: ['goal-interstitial']
  classNameBindings: ['transitioning']

  isTransitioning: false

  closeView: ->
    @set('transitioning', true)
    setTimeout =>
      @$().remove()
    , 1000

  didInsertElement: ->
    @get('controller').on('viewClosed', this, this.closeView)

  #-----------  Removal Animation  -----------#

  click: (evt) ->
    if evt.target.className.indexOf('cancel-button') > -1
      $('.goal-interstitial').trigger("toggleGoalSelection")

    return false
