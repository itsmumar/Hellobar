import Ember from 'ember';

export default Ember.Component.extend({
  classNames: ['conversion-styling'],


  /**
   * @property {object} Application model
   */
  model: null,
  selectedColorAndFont: function () {
    console.log("hello");
    this.set('model.conversion_font_color',this.get('model.text_color'));
  }.property('model.text_color')
});
