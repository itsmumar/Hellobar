import Ember from 'ember';

/**
 * @class CustomHtmlEditor
 * Component that contains editors (HTML, CSS, JS) for Custom HTML Bars
 */
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
