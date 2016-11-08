announcementKeyPrefix = 'HB-announcement-'

# TODO Convert to service after upgrading to Ember 2
HelloBar.announcementTracking = {

  wasAnnouncementClosedByCurrentUser: (announcementName) ->
    !!localStorage.getItem(announcementKeyPrefix + announcementName)

  closeAnnouncement: (announcementName) ->
    localStorage.setItem(announcementKeyPrefix + announcementName, 'closed')

}
