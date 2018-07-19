import Ember from 'ember';

export default Ember.Helper.helper(function(image) {
  return new Ember.Handlebars.SafeString(window.svg_content(image));
});
