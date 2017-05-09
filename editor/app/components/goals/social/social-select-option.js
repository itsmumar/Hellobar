import Ember from 'ember';

export default Ember.Component.extend({

  tagName: 'li',

  classNameBindings: ['content.service', 'isSelected'],

  isSelected: function () {
    return Ember.isEqual(this.get('content.value'), this.get('parentView.selection'));
  }.property('parentView.selection'),

  click(event) {
    if (!this.get('isSelected')) {
      this.set('parentView.selection', this.get('content.value'));
    } else if (event.target.className === 'icon-close') {
      this.set('parentView.selection', null);
    }
    return false;
  }
});
