import Ember from 'ember';

const announcementKeyPrefix = 'HB-announcement-';

export default Ember.Service.extend({

  wasAnnouncementClosedByCurrentUser(announcementName) {
    return !!localStorage.getItem(announcementKeyPrefix + announcementName);
  },

  closeAnnouncement(announcementName) {
    return localStorage.setItem(announcementKeyPrefix + announcementName, 'closed');
  }
});

