let CSS_TRANSITION = 750; // when changing please update it in "_interstitial.css.sass" as well

HelloBar.InterstitialView = Ember.View.extend({
  applicationSettings: Ember.computed.alias('applicationController.applicationSettings.settings'),

  didInsertElement() {
    if (this.get('applicationSettings.track_editor_flow')) {
      return InternalTracking.track_current_person("Editor Flow", {step: "Choose Goal"});
    }
  },

  animateOut(done) {
    return this.$el.fadeOut(CSS_TRANSITION, done);
  }
});

let SubInterstitialView = Ember.View.extend({
  classNames: ["interstitial-container"],
  baseZIndex: 10000, // should equal to z-index specified in "_interstitial.css.sass"
  routeName: null, // route name related to the view

  willAnimateIn() {
    return this.$el.addClass("transitioning no-transition"); // set initial state immediately
  },

  animateIn(done) {
    this.$el.removeClass("transitioning no-transition");
    return setTimeout(done, CSS_TRANSITION);
  },

  didAnimateIn() {
    return SubInterstitialView.lastRoute = this.routeName; // save last route name to enlarge its block on index view
  },

  animateOut(done) {
    this.$el.addClass("transitioning");
    return setTimeout(done, CSS_TRANSITION);
  }
});

HelloBar.InterstitialIndexView = SubInterstitialView.extend({
  willAnimateIn() {
    this._super();
    if (SubInterstitialView.lastRoute) { // specific css animation for previously selected interstitial goal block
      return this.$(`.goal-block[data-route=${SubInterstitialView.lastRoute}]`).addClass("selected");
    }
  },

  click(e) {
    let $target = $(e.target);
    let $reveal = $target.closest(".reveal-wrapper");

    if ($target.is(".cancel")) {
      $reveal.removeClass("activated");
    } else if ($reveal.length) { // open reveal block
      $reveal.addClass("activated");
      return;
    }

    if ($target.is(".goal-block .button")) { // mark selected goal block to use specific css animation for it
      this.$(".goal-block.selected").removeClass("selected");
      $target.closest(".goal-block").addClass("selected");

      let route = $target.closest(".goal-block").data("route");
      if (route) {
        InternalTracking.track_current_person("Template Selected", {template: route});
      }

      this._track_selected_goal();

      return;
    }
  },

  _track_selected_goal() {
    return $.ajax({
      method: "POST",
      url: `/sites/${siteID}/track_selected_goal`
    });
  }
});

HelloBar.InterstitialMoneyView = SubInterstitialView.extend({
  routeName: "money"
});

HelloBar.InterstitialCallView = SubInterstitialView.extend({
  routeName: "call"
});

HelloBar.InterstitialContactsView = SubInterstitialView.extend({
  routeName: "contacts"
});

HelloBar.InterstitialFacebookView = SubInterstitialView.extend({
  routeName: "facebook"
});
