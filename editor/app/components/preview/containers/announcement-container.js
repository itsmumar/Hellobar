import Ember from 'ember';

export default Ember.Component.extend({

  announcementTracking: Ember.inject.service(),
  imaging: Ember.inject.service(),

  currentAnnouncementName: null,
  currentAnnouncementWasClosed: false,

  buttonsAreVisible: false,

  classNames: [ 'announcement-container' ],
  classNameBindings: ['announcementToShow:visible', 'buttonsAreVisible:buttons-are-visible'],

  elementId: 'announcement-container',

  announcementToShow: function() {
    if (this.currentAnnouncementWasClosed || this.get('announcementTracking').wasAnnouncementClosedByCurrentUser(this.currentAnnouncementName)) {
      return null;
    } else {
      return this.currentAnnouncementName;
    }
  }.property('currentAnnouncement', 'currentAnnouncementWasClosed'),

  announcementImageSrc: function() {
    return this.get('imaging').imagePath(`announcements/${this.get('currentAnnouncementName')}.png`);
  }.property('currentAnnouncementName'),


  context: Ember.computed(function() { return this; }),

  didInsertElement() {
    const buttonShowDelayInMillis = 5000;
    return setTimeout(() => {
      return this.set('buttonsAreVisible', true);
    }, buttonShowDelayInMillis);
  },

  actions: {
    closeCurrentAnnouncement() {
      this.get('announcementTracking').closeAnnouncement(this.currentAnnouncementName);
      return this.set('currentAnnouncementWasClosed', true);
    }
  }

});
