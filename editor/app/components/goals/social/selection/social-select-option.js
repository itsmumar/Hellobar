import Ember from 'ember';

export default Ember.Component.extend({

  tagName: 'li',

  classNameBindings: ['content.service', 'isSelected'],

  isSelected: function () {
    return Ember.isEqual(this.get('content.value'), this.get('parentView.selection')) || this.get('parentView.selectionInProgress');
  }.property('parentView.selection', 'parentView.selectionInProgress'),

  click(event) {
    if (this.get('parentView.selectionInProgress')) {
      this.setProperties({
        'parentView.selection': this.get('content.value'),
        'parentView.selectionInProgress': false
      });
    } else if (event.target.className === 'icon-close') {
      this.set('parentView.selectionInProgress', true);
    }
    return false;
  }
});
