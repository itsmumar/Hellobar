HelloBar.InterstitialView = Ember.View.extend

  classNames: ['goal-interstitial']

  templateName: ( ->
    type = @get('controller.interstitialType')
    return "interstitials/#{type}" if type
  ).property('controller.interstitialType')
