import Ember from 'ember';

export default Ember.Component.extend({

  /*init() {
    //Ember.run.next(() => {
    //  this.sendAction('initialized', this);
    //});
    console.log('custom-html-editor', this);
  },*/

  didInsertElement() {
    Ember.run.next(() => {
      this.sendAction('onInitialized', this);
    });
  },

  classNames: ['custom-html-editor'],

  testFunction() {
    alert('testFunction');
  },


  /**
   * @property {string} Custom HTML
   */
  customHtml: null,

  /**
   * @property {string} Custom CSS
   */
  customCss: null,

  /**
   * @property {string} Custom JavaScript
   */
  customJs: null

});

