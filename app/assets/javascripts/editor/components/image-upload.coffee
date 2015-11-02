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
        existingFileName = @get('existingFileName')
        if !!existingFileName
          @setDropzoneMessage(existingFileName)
        else
          @setDropzoneMessage(@defaultMessage)
      headers:
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      success: (file, res) =>
        @set('existingFileName', file.name)
        @setRemoveButtonActive()
        @sendAction('setImageProps', res.id, res.url)
      sending: (file, xhr, formData) =>
        @setActionIcon("sync")
        formData.append('site_element_id', siteID)
      complete: =>
        @setActionIcon("trash")

    dropzone.on 'addedfile', (file) =>
      @setDropzoneMessage("")
      @toggleErrorState(false)
      for existingFile in dropzone.files
        if existingFile != file
          dropzone.removeFile(existingFile)

    dropzone.on 'error', (file) =>
      @toggleErrorState(true)

    @set('dropzoneInstance', dropzone)

  clearActionIcons: ->
    for key, val of @actionIcons
      @$(".file-action").removeClass(val)

  setActionIcon: (icon) ->
    @clearActionIcons()
    @$(".file-action").addClass(@actionIcons[icon])

  removeDropzoneImages: ->
    @set('existingFileName', null)
    @setDropzoneMessage(@defaultMessage)
    @sendAction('setImageProps', null, '')
    @get('dropzoneInstance').removeAllFiles()
    @$(".file-action").removeClass('active')
    @toggleErrorState(false)

  setRemoveButtonActive: ->
    @$(".file-action").addClass('active')

  setDropzoneMessage: (message) ->
    @$(".default-text").text(message)

  toggleErrorState: (bool) ->
      @$(".file-upload-container").toggleClass("with-errors", bool)
