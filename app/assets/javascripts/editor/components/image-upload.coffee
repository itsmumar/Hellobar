HelloBar.ImageUploadComponent = Ember.Component.extend
  dropzoneInstance: null

  didInsertElement: ->
    @insertDropzone()
    @$(".remove-file").click =>
      @removeDropzoneImages()
    if !!@get('existingURL')
      @setRemoveButtonActive()

  insertDropzone: ->
    that = this
    dropzone = new Dropzone this.$(".file-upload")[0],
      url: "image_uploads"
      maxFiles: 1
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
        formData.append('site_element_id', siteID)
      drop: (evt) ->
        @removeAllFiles()

    @set('dropzoneInstance', dropzone)

  removeDropzoneImages: ->
    @sendAction('setImageProps', null, '')
    @get('dropzoneInstance').removeAllFiles()
    @$(".remove-file").removeClass('active')

  setRemoveButtonActive: ->
    @$(".remove-file").addClass('active')
