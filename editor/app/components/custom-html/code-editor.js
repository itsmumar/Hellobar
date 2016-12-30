import Ember from 'ember';
import CodeMirror from 'npm:codemirror';
import CodeMirrorModeCss from 'npm:codemirror/mode/css/css.js';
import CodeMirrorModeHtmlMixed from 'npm:codemirror/mode/htmlmixed/htmlmixed.js';
import CodeMirrorModeJavascript from 'npm:codemirror/mode/javascript/javascript.js';

/**
 * @class CodeEditor
 * Component for custom code editing (HTML, CSS or JS).
 */
export default Ember.Component.extend({

  classNames: ['code-editor'],

  /**
   * @property {string} editor title
   */
  title: null,

  /**
   * @property {string} editor mode (can be "htmlmixed", "css" or "javascript")
   */
  editorMode: null,

  /**
   * @property {string} current value to edit
   */
  value: null,

  didInsertElement() {
    const editor = CodeMirror(this.$('.js-editor-container')[0], {
      lineNumbers: true,
      mode: this.editorMode,
      value: this.value || ''
    });
    editor.on('change', () => {
      this.set('value', editor.getValue());
    });
  }

});

