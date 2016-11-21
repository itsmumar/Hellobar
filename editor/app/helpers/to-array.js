import Ember from 'ember';

export default Ember.Helper.helper(function (item) {
  if (typeof item === 'object') {
    return item;
  } else {
    return [item];
  }
});
