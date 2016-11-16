let announcementKeyPrefix = 'HB-announcement-';

// TODO Convert to service after upgrading to Ember 2
HelloBar.announcementTracking = {

  wasAnnouncementClosedByCurrentUser(announcementName) {
    return !!localStorage.getItem(announcementKeyPrefix + announcementName);
  },

  closeAnnouncement(announcementName) {
    return localStorage.setItem(announcementKeyPrefix + announcementName, 'closed');
  }

};
