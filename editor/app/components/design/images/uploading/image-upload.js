import Ember from 'ember';

export default Ember.Component.extend({
  dropzoneInstance: null,
  classNames: ['file-upload-container'],
  classNameBindings: ['hasFile:has-file', 'errorState:with-errors'],

  hasFile: Ember.computed('existingFileName', function () {
      if (this.get('existingFileName') === 'uploading') {
        return false;
      }
      return this.get('existingFileName');
    }
  ),

  errorState() {
    let dropzone = this.get('dropzoneInstance');
    let file = dropzone.files[0];
    return file && file.status === 'error';
  },

  isUploading: Ember.computed('existingFileName', function () {
      let dropzone;
      if (!(dropzone = this.get('dropzoneInstance'))) {
        return false;
      }
      let file = dropzone.files[0];
      if (file && file.status === 'uploading') {
        return file.name;
      }
    }
  ),

  actions: {
    removeDropzoneImages() {
      this.set('existingFileName', null);
      this.sendAction('setImageProps', { imageID: null, imageUrl: '' });
      let dropzone = this.get('dropzoneInsance');
      if (dropzone) {
        return dropzone.removeAllFiles();
      }
    }
  },

  didInsertElement() {
    return this.insertDropzone();
  },

  insertDropzone() {
    let dropzone = new Dropzone(this.$('.file-upload')[0], {
        url: `/sites/${siteID}/image_uploads`,
        clickable: '#dropzone-preview, #dropzone-preview *',
        maxFiles: 2,
        maxFilesize: 20,
        addRemoveLinks: false,
        createImageThumbnails: false,
        acceptedFiles: 'image/*',
        dictInvalidFileType: 'You can only upload image files.',
        headers: {
          'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content')
        },
        success: (file, res) => {
          this.set('existingFileName', file.name);
          return this.sendAction('setImageProps', {
            imageID: res.id,
            imageUrl: res.url,
            imageSmallUrl: res.small_url,
            imageMediumUrl: res.medium_url,
            imageLargeUrl: res.large_url,
            imageModalUrl: res.modal_url,
            imageType: 'custom',
            useDefaultImage: false
          });
        },
        sending: (file, xhr, formData) => {
          this.set('existingFileName', 'uploading');
          return formData.append('site_element_id', siteID);
        }
      }
    );

    dropzone.on('addedfile', file => {
        return (() => {
          let result = [];
          for (let i = 0; i < dropzone.files.length; i++) {
            let existingFile = dropzone.files[i];
            let item;
            if (existingFile !== file) {
              item = dropzone.removeFile(existingFile);
            }
            result.push(item);
          }
          return result;
        })();
      }
    );

    dropzone.on('error', file => {
        return this.set('existingFileName', null);
      }
    );

    return this.set('dropzoneInstance', dropzone);
  }
});
