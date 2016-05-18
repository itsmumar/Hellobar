HelloBar.ImageUploadComponent = Ember.Component.extend
  dropzoneInstance: null
  classNames: ['file-upload-container']
  classNameBindings: ['hasFile:has-file', 'errorState:with-errors']

  hasFile: Ember.computed 'existingFileName', ->
    if @get('existingFileName') == "uploading"
      return false
    @get('existingFileName')

  errorState: ->
    dropzone = @get("dropzoneInstance")
    file = dropzone.files[0]
    file and file.status == "error"

  isUploading: Ember.computed 'existingFileName', ->
    unless dropzone = @get("dropzoneInstance")
      return false
    file = dropzone.files[0]
    if file and file.status == "uploading"
      return file.name

  actions:
    removeDropzoneImages: ->
      @set('existingFileName', null)
      @sendAction('setImageProps', null, '')
      @get('dropzoneInstance').removeAllFiles()

  didInsertElement: ->
    @insertDropzone()

  insertDropzone: ->
    dropzone = new Dropzone this.$(".file-upload")[0],
      url: "/sites/#{siteID}/image_uploads"
      clickable: "#dropzone-preview, #dropzone-preview *"
      maxFiles: 2
      maxFilesize: 1
      addRemoveLinks: false
      createImageThumbnails: false
      acceptedFiles: "image/*"
      dictInvalidFileType: "You can only upload image files."
      headers:
        'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
      success: (file, res) =>
        @set('existingFileName', file.name)
        @sendAction('setImageProps', res.id, res.url)
      sending: (file, xhr, formData) =>
        @set('existingFileName', "uploading")
        formData.append('site_element_id', siteID)

    dropzone.on 'addedfile', (file) =>
      for existingFile in dropzone.files
        if existingFile != file
          dropzone.removeFile(existingFile)

    dropzone.on 'error', (file) =>
      @set('existingFileName', null)

    @set('dropzoneInstance', dropzone)
