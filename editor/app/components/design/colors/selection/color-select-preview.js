import Ember from 'ember';

export default Ember.Component.extend({

  tagName: 'li',
  classNames: ['color-preview'],
  attributeBindings: ['style'],

  style: function () {
    // TODO why we use global variable 'one' here?
    const color = one.color(this.get('color'));
    if (color && color.hex()) {
      return `background-color: ${color.hex()}`;
    }
  }.property('color'),

  mouseUp() {
    // TODO get rid of global 'one'
    const color = one.color(this.get('color'));
    if (color && color.hex()) {
      return this.set('parentView.color', color.hex());
    }
  }
});
