HelloBar.InterstitialController = Ember.Controller.extend

  needs: ['application']

  #-----------  Template Properties  -----------#
  
  showInterstitial: Ember.computed.alias('controllers.application.showInterstitial')
  interstitialType: Ember.computed.alias('controllers.application.interstitialType')
