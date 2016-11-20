import Ember from 'ember';

export default Ember.Component.extend({

  tagName: 'li',
  classNames: ['color-preview'],
  attributeBindings: ['style'],

  style: ( function () {
    // TODO why we use global variable 'one' here?
    let color = one.color(this.get('color'));
    if (color && color.hex()) {
      return `background-color: ${color.hex()}`;
    }
  }).property('color'),

  mouseUp() {
    let color = one.color(this.get('color'));
    if (color && color.hex()) {
      return this.set('parentView.color', color.hex());
    }
  }
});
