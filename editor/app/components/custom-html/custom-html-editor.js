import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['custom-html-editor'],

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

