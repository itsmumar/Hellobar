import Ember from 'ember';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  socialOptions: [
    {value: 'social/tweet_on_twitter', label: 'Tweet on Twitter', service: 'twitter', icon: 'icon-twitter-circled'},
    {value: 'social/follow_on_twitter', label: 'Follow on Twitter', service: 'twitter', icon: 'icon-twitter-circled'},
    {value: 'social/like_on_facebook', label: 'Like on Facebook', service: 'facebook', icon: 'icon-facebook-circled'},
    {value: 'social/share_on_linkedin', label: 'Share on LinkedIn', service: 'linkedin', icon: 'icon-linkedin-circled'},
    {value: 'social/pin_on_pinterest', label: 'Pin on Pinterest', service: 'pinterest', icon: 'icon-pinterest-circled'},
    {
      value: 'social/follow_on_pinterest',
      label: 'Follow on Pinterest',
      service: 'pinterest',
      icon: 'icon-pinterest-circled'
    },
    {value: 'social/follow_on_instagram', label: 'Follow on Instagram', service: 'instagram', icon: 'hb-instagram-circled'},
    {value: 'social/follow_on_youtube', label: 'Follow on Youtube', service: 'youtube', icon: 'hb-youtube-circled'},
    {value: 'social/share_on_buffer', label: 'Share on Buffer', service: 'buffer', icon: 'icon-buffer-circled'}
  ],

  selectedSocialSubtype: Ember.computed.alias('model.element_subtype'),

  socialSubtypeComponentName: function () {
    const subtype = this.get('selectedSocialSubtype');
    if (subtype && subtype.indexOf('/') >= 0) {
      const shortSubtype = subtype.replace(/^(social\/)/, '');
      const componentShortName = shortSubtype.replace(/_/g, '-');
      return 'goals/social/subtypes/' + componentShortName;
    } else {
      return null;
    }
  }.property('model.element_subtype')

});
