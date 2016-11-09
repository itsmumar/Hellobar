HelloBar.AnnouncementContainerComponent = Ember.Component.extend(

  currentAnnouncementName: 'inline-editing'
  currentAnnouncementWasClosed: false

  buttonsAreVisible: false

  classNames: [ 'announcement-container' ]
  classNameBindings: ['announcementToShow:visible', 'buttonsAreVisible:buttons-are-visible']

  elementId: 'announcement-container'

  announcementToShow: (->
    if @currentAnnouncementWasClosed or HelloBar.announcementTracking.wasAnnouncementClosedByCurrentUser(@currentAnnouncementName)
      null
    else
      @currentAnnouncementName
  ).property('currentAnnouncement', 'currentAnnouncementWasClosed')

  announcementImageSrc: (->
    '/assets/announcements/' + @get('currentAnnouncementName') + '.png'
  ).property('currentAnnouncementName')


  context: Ember.computed(() -> this)

  didInsertElement: ->
    setTimeout(=>
      @set('buttonsAreVisible', true)
    , 5000)

  actions: {
    closeCurrentAnnouncement: ->
      HelloBar.announcementTracking.closeAnnouncement(@currentAnnouncementName)
      @set('currentAnnouncementWasClosed', true)
  }

)