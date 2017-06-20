/* globals Handlebars */

import Ember from 'ember';

export default Ember.Helper.helper(function (method, value, text) {
  let $option = $('<option>');
  $option.val(value)
    .text(text);
  if (method === value) {
    $option.attr('selected', 'selected');
  }
  return new Handlebars.SafeString($option.prop('outerHTML'));
});
