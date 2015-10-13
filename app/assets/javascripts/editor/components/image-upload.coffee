HelloBar.ImageUploadComponent = Ember.Component.extend
  dropzoneInstance: null
  actionIcons:
    sync: "icon-sync"
    trash: "icon-trash"

  didInsertElement: ->
    @insertDropzone()
    @$(".file-action").click =>
      @removeDropzoneImages()
    if !!@get('existingURL')
      @setRemoveButtonActive()

  insertDropzone: ->
    that = this
    dropzone = new Dropzone this.$(".file-upload")[0],
      url: "/sites/#{siteID}/image_uploads"
      maxFiles: 1
      maxFilesize: 1
      addRemoveLinks: false
      createImageThumbnails: false
      init: ->
        this.on "addedfile", (file) ->
          that.$(".default-text").text("")
      headers:
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      success: (file, res) =>
        @setRemoveButtonActive()
        @sendAction('setImageProps', res.id, res.url)
      sending: (file, xhr, formData) =>
        @setActionIcon("sync")
        formData.append('site_element_id', siteID)
      drop: (evt) ->
        @removeAllFiles()
      complete: =>
        @setActionIcon("trash")

    @set('dropzoneInstance', dropzone)

  clearActionIcons: ->
    for key, val of @actionIcons
      @$(".file-action").removeClass(val)

  setActionIcon: (icon) ->
    @clearActionIcons()
    @$(".file-action").addClass(@actionIcons[icon])

  removeDropzoneImages: ->
    @sendAction('setImageProps', null, '')
    @get('dropzoneInstance').removeAllFiles()
    @$(".file-action").removeClass('active')

  setRemoveButtonActive: ->
    @$(".file-action").addClass('active')
