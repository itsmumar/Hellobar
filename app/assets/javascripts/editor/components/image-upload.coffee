HelloBar.ImageUploadComponent = Ember.Component.extend
  dropzoneInstance: null
  actionIcons:
    sync: "icon-sync"

  currentFileText: (filename) ->
    """
    <div class="name">#{filename}</div>
    <img class="file-action icon-trash" src="#{image_path "delete.svg"}">
    """

  defaultMessage: (file=null) ->
    """
    <img src="#{image_path "upload-icon.svg"}">

    <div>
      Drag an image here or <a href="#_">browse</a><br/>
      #{if file then "to replace the uploaded image" else "for an image to upload"}
    </div>

    <div><small>Limit images to 300px tall</small></div>
    """

  uploadingMessage: (filename) ->
    """
    <i class="#{@actionIcons['sync']}"></i>
    <div>
      Uploading <strong>#{filename}</strong>
    </div>
    """

  didInsertElement: ->
    @insertDropzone()

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
          # this case runs when a user navigates away and back again in ember
          @setDropzoneUploaded(existingFileName)
        else
          @setDropzoneReady()
      headers:
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      success: (file, res) =>
        @set('existingFileName', file.name)
        @sendAction('setImageProps', res.id, res.url)
        @setDropzoneUploaded(file.name)
      sending: (file, xhr, formData) =>
        @setDropzoneUploading(file.name)
        formData.append('site_element_id', siteID)

    dropzone.on 'addedfile', (file) =>
      @toggleErrorState(false)
      for existingFile in dropzone.files
        if existingFile != file
          dropzone.removeFile(existingFile)

    dropzone.on 'error', (file) =>
      @toggleErrorState(true)
      @setDropzoneReady()

    @set('dropzoneInstance', dropzone)

  setDropzoneReady: ->
    @hasNoFile()
    @setDropzoneMessage(@defaultMessage())

  setDropzoneUploading: (filename) ->
    @hasNoFile()
    @setDropzoneMessage(@uploadingMessage(filename))

  setDropzoneUploaded: (filename) ->
    @hasFile(filename)
    @setDropzoneMessage(@defaultMessage(filename))

  hasNoFile: ->
    @$(".file-upload-container").removeClass("has-file")

  hasFile: (filename) ->
    @$(".file-upload-container").addClass("has-file")
    @$(".current-file").html(@currentFileText(filename))
    @$(".file-action").click =>
      @removeDropzoneImages()

  removeDropzoneImages: ->
    @set('existingFileName', null)
    @setDropzoneReady()
    @sendAction('setImageProps', null, '')
    @get('dropzoneInstance').removeAllFiles()
    @$(".file-action").removeClass('active')
    @toggleErrorState(false)

  setDropzoneMessage: (message) ->
    @$(".default-text").html(message)

  toggleErrorState: (bool) ->
    @$(".file-upload-container").toggleClass("with-errors", bool)
