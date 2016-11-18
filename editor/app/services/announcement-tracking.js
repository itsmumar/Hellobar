import Ember from 'ember';

const announcementKeyPrefix = 'HB-announcement-';

export default Ember.Service.extend({

  init() {
    // TODO remove
    console.log('announcemnt-tracking service initialized');
  },

  wasAnnouncementClosedByCurrentUser(announcementName) {
    return !!localStorage.getItem(announcementKeyPrefix + announcementName);
  },

  closeAnnouncement(announcementName) {
    return localStorage.setItem(announcementKeyPrefix + announcementName, 'closed');
  }
});

