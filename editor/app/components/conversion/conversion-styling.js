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
    this.set('model.conversion_font',this.get('model.font_id'));
  }.property('model.text_color','model.conversion_font')
});
