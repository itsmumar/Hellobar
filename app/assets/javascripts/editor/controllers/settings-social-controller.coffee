HelloBar.SettingsSocialController  = Ember.Controller.extend
  socialOptions: [
    {value: "social/tweet_on_twitter", label: 'Tweet on Twitter'}
    {value: "social/follow_on_twitter", label: 'Follow on Twitter'}
    {value: "social/like_on_facebook", label: 'Like on Facebook'}
    {value: "social/share_on_linkedin", label: 'Share on LinkedIn'}
    {value: "social/plus_one_on_google_plus", label: '+1 on Google+'}
    {value: "social/pin_on_pinterest", label: 'Pin on Pinterest'}
    {value: "social/follow_on_pinterest", label: 'Follow on Pinterest'}
    {value: "social/share_on_buffer", label: 'Share on Buffer'}
  ]

  selectedSocialSubtype: Ember.computed.alias("model.element_subtype")
