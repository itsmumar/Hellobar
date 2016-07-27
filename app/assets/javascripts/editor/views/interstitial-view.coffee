CSS_TRANSITION = 750 # when changing please update it in "_interstitial.css.sass" as well

HelloBar.InterstitialView = Ember.View.extend
  click: (e) ->
    $target = $(e.target)
    $reveal = $target.closest(".reveal-wrapper")

    if $reveal.length
      $reveal.addClass("activated")
      
  didInsertElement: () ->
    InternalTracking.track_current_person("Editor Flow", {step: "Choose Goal"}) if trackEditorFlow

  animateOut : (done) ->
    @$el.fadeOut(CSS_TRANSITION, done)

SubInterstitialView = Ember.View.extend
  classNames: ["interstitial-container"]
  baseZIndex: 10000 # should equal to z-index specified in "_interstitial.css.sass"
  routeName: null

  willAnimateIn: () ->
    @$el.addClass("transitioning no-transition") # set initial state immediately

  animateIn: (done) ->
    @$el.removeClass("transitioning no-transition")
    setTimeout done, CSS_TRANSITION
    
  didAnimateIn: () ->
    SubInterstitialView.lastRoute = @routeName

  animateOut: (done) ->
    @$el.addClass "transitioning"
    setTimeout done, CSS_TRANSITION

HelloBar.InterstitialIndexView = SubInterstitialView.extend
  willAnimateIn: () ->
    @_super()
    if SubInterstitialView.lastRoute
      this.$(".goal-block[data-route=#{SubInterstitialView.lastRoute}]").addClass("selected")

  click: (e) ->
    $target = $(e.target)
    if $target.is(".goal-block .button")
      this.$(".goal-block.selected").removeClass("selected")
      $target.closest(".goal-block").addClass("selected")

HelloBar.InterstitialContactsView = SubInterstitialView.extend
  routeName: "contacts"

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
