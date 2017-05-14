import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  socialOptions: [
    {value: 'tweet_on_twitter', label: 'Tweet on Twitter', service: 'twitter', icon: 'icon-twitter-circled'},
    {value: 'follow_on_twitter', label: 'Follow on Twitter', service: 'twitter', icon: 'icon-twitter-circled'},
    {value: 'like_on_facebook', label: 'Like on Facebook', service: 'facebook', icon: 'icon-facebook-circled'},
    {value: 'share_on_linkedin', label: 'Share on LinkedIn', service: 'linkedin', icon: 'icon-linkedin-circled'},
    {value: 'plus_one_on_google_plus', label: '+1 on Google+', service: 'google', icon: 'icon-gplus-circled'},
    {value: 'pin_on_pinterest', label: 'Pin on Pinterest', service: 'pinterest', icon: 'icon-pinterest-circled'},
    {
      value: 'follow_on_pinterest',
      label: 'Follow on Pinterest',
      service: 'pinterest',
      icon: 'icon-pinterest-circled'
    },
    {value: 'share_on_buffer', label: 'Share on Buffer', service: 'buffer', icon: 'icon-buffer-circled'}
  ],

  selectedSocialSubtype: function () {
    return 'social/' + this.get('model.element_subtype');
  }.property('model.element_subtype')

});
