import Ember from 'ember';

export default Ember.Service.extend({
  init() {
    if (!window.image_path) {
      console.warn('Global function image_path is not defined');
    }
  },

  imagePath(imageFile) {
    return window.image_path(imageFile);
  }
});
