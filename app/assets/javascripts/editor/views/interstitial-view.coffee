CSS_TRANSITION = 750 # when changing please update it in "_interstitial.css.sass" as well

HelloBar.InterstitialView = Ember.View.extend
  didInsertElement: () ->
    InternalTracking.track_current_person("Editor Flow", {step: "Choose Goal"}) if trackEditorFlow

  animateOut : (done) ->
    @$el.fadeOut(CSS_TRANSITION, done)

SubInterstitialView = Ember.View.extend
  classNames: ["interstitial-container"]
  baseZIndex: 10000 # should equal to z-index specified in "_interstitial.css.sass"
  routeName: null # route name related to the view

  willAnimateIn: () ->
    @$el.addClass("transitioning no-transition") # set initial state immediately

  animateIn: (done) ->
    @$el.removeClass("transitioning no-transition")
    setTimeout done, CSS_TRANSITION

  didAnimateIn: () ->
    SubInterstitialView.lastRoute = @routeName # save last route name to enlarge its block on index view

  animateOut: (done) ->
    @$el.addClass "transitioning"
    setTimeout done, CSS_TRANSITION

HelloBar.InterstitialIndexView = SubInterstitialView.extend
  willAnimateIn: () ->
    @_super()
    if SubInterstitialView.lastRoute # specific css animation for previously selected interstitial goal block
      this.$(".goal-block[data-route=#{SubInterstitialView.lastRoute}]").addClass("selected")

  click: (e) ->
    $target = $(e.target)
    $reveal = $target.closest(".reveal-wrapper")

    if $reveal.length # open reveal block
      $reveal.addClass("activated")
      return

    if $target.is(".goal-block .button") # mark selected goal block to use specific css animation for it
      this.$(".goal-block.selected").removeClass("selected")
      $target.closest(".goal-block").addClass("selected")

      route = $target.closest(".goal-block").data("route")
      InternalTracking.track_current_person("Template Selected", {template: route}) if route
      return

HelloBar.InterstitialMoneyView = SubInterstitialView.extend
  routeName: "money"

HelloBar.InterstitialCallView = SubInterstitialView.extend
  routeName: "call"

HelloBar.InterstitialContactsView = SubInterstitialView.extend
  routeName: "contacts"

HelloBar.InterstitialFacebookView = SubInterstitialView.extend
  routeName: "facebook"
