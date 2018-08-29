import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Component.extend({

  /**
   * @property {object} Application model
   */
  model: null,

  theming: Ember.inject.service(),

  goal: Ember.computed.alias('model.element_subtype'),
  isEmail: Ember.computed.equal('goal', 'email'),
  isCall: Ember.computed.equal('goal', 'call'),
  isTraffic: Ember.computed.equal('goal', 'traffic'),
  isAnnouncement: Ember.computed.equal('goal', 'announcement'),
  isSocial: function () {
    return _.startsWith(this.get('goal'), 'social');
  }.property('goal'),

  actions: {
    select(goal) {
      this.set('goal', goal === 'social' ? 'social/like_on_facebook' : goal);
      this.get('theming').resetThemeIfNeeded();
      this.set('model.wiggle_button', false); // turn wiggling off
      switch(goal) {git
        case 'call':
          this.set('model.headline', 'Talk to us to find out more')
          this.set('model.link_text', 'Call Now')
          break;
        case 'email':
          this.set('model.headline', 'Join our mailing list to stay up to date on our upcoming events')
          this.set('model.link_text', 'Subscribe')
          break;
        case 'announcement':
          this.set('model.headline', 'Flash Sale: 20% Off Sitewide, Enter Code “20savings')
          this.set('model.link_text', 'Shop Now')
          break;
        case 'social':
          this.set('model.headline', 'Like us on Facebook!')
          break;
        case 'traffic':
          this.set('model.headline', 'Want To Become An Expert In Hosting Webinars? Join Our Free Webinar Masterclass!' )
          this.set('model.link_text', 'Save Me A Spot!')
          break;
        default:
          this.set('model.headline', goal )
          this.set('model.link_text', goal )
      }
    }
  }
});
