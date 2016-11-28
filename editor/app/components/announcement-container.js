import Ember from 'ember';

export default Ember.Component.extend({

  announcementTracking: Ember.inject.service(),

  currentAnnouncementName: 'inline-editing',
  currentAnnouncementWasClosed: false,

  buttonsAreVisible: false,

  classNames: [ 'announcement-container' ],
  classNameBindings: ['announcementToShow:visible', 'buttonsAreVisible:buttons-are-visible'],

  elementId: 'announcement-container',

  announcementToShow: (function() {
    if (this.currentAnnouncementWasClosed || this.get('announcementTracking').wasAnnouncementClosedByCurrentUser(this.currentAnnouncementName)) {
      return null;
    } else {
      return this.currentAnnouncementName;
    }
  }).property('currentAnnouncement', 'currentAnnouncementWasClosed'),

  announcementImageSrc: (function() {
    return `/assets/announcements/${this.get('currentAnnouncementName')}.png`;
  }).property('currentAnnouncementName'),


  context: Ember.computed(function() { return this; }),

  didInsertElement() {
    return setTimeout(() => {
      return this.set('buttonsAreVisible', true);
    }, 5000);
  },

  actions: {
    closeCurrentAnnouncement() {
      this.get('announcementTracking').closeAnnouncement(this.currentAnnouncementName);
      return this.set('currentAnnouncementWasClosed', true);
    }
  }

});
