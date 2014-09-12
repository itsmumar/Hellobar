HelloBar.SettingsSocialController  = Ember.Controller.extend

  socialOptions: [
    {value: "social/tweet_on_twitter",        label: 'Tweet on Twitter',    service: 'twitter',   icon: 'icon-twitter-circled'}
    {value: "social/follow_on_twitter",       label: 'Follow on Twitter',   service: 'twitter',   icon: 'icon-twitter-circled'}
    {value: "social/like_on_facebook",        label: 'Like on Facebook',    service: 'facebook',  icon: 'icon-facebook-circled'}
    {value: "social/share_on_linkedin",       label: 'Share on LinkedIn',   service: 'linkedin',  icon: 'icon-linkedin-circled'}
    {value: "social/plus_one_on_google_plus", label: '+1 on Google+',       service: 'google',    icon: 'icon-gplus-circled'}
    {value: "social/pin_on_pinterest",        label: 'Pin on Pinterest',    service: 'pinterest', icon: 'icon-pinterest-circled'}
    {value: "social/follow_on_pinterest",     label: 'Follow on Pinterest', service: 'pinterest', icon: 'icon-pinterest-circled'}
    {value: "social/share_on_buffer",         label: 'Share on Buffer',     service: 'buffer',    icon: 'icon-wordpress'}
  ]

  selectedSocialSubtype: Ember.computed.alias("model.element_subtype")
