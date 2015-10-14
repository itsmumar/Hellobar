HelloBar.ImageUploadComponent = Ember.Component.extend
  defaultMessage: "Click or drag to upload ..."
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
    dropzone = new Dropzone this.$(".file-upload")[0],
      url: "/sites/#{siteID}/image_uploads"
      clickable: "#dropzone-preview"
      maxFiles: 2
      maxFilesize: 1
      addRemoveLinks: false
      createImageThumbnails: false
      acceptedFiles: "image/*"
      dictInvalidFileType: "You can only upload image files."
      init: =>
        @setDropzoneMessage(@defaultMessage)
      headers:
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      success: (file, res) =>
        @setRemoveButtonActive()
        @sendAction('setImageProps', res.id, res.url)
      sending: (file, xhr, formData) =>
        @setActionIcon("sync")
        formData.append('site_element_id', siteID)
      complete: =>
        @setActionIcon("trash")
      reset: =>
        @setDropzoneMessage(@defaultMessage)

    dropzone.on 'addedfile', (file) =>
      @setDropzoneMessage("")
      for existingFile in dropzone.files
        if existingFile != file
          dropzone.removeFile(existingFile)

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

  setDropzoneMessage: (message) ->
    @$(".default-text").text(message)
