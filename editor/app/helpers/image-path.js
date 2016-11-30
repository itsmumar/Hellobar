import Ember from 'ember';

export default Ember.Helper.helper(function(image) {
  // TODO import image_path as ES6 module, get rid of global variable
  return new Ember.Handlebars.SafeString(window.image_path(image));
});
