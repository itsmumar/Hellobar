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
    if (true) {
    // TODO uncomment this (this.announcementTracking doesn't work so far)
    //if (this.currentAnnouncementWasClosed || this.announcementTracking.wasAnnouncementClosedByCurrentUser(this.currentAnnouncementName)) {
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
    }
    , 5000);
  },

  actions: {
    closeCurrentAnnouncement() {
      HelloBar.announcementTracking.closeAnnouncement(this.currentAnnouncementName);
      return this.set('currentAnnouncementWasClosed', true);
    }
  }

});
