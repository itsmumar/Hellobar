import Ember from 'ember';

/**
 * @class Preview
 * Encapsulates preview management
 */
export default Ember.Service.extend({

  _previewInjectionListeners: [],

  init() {
    this._initializeInjectionPolicy();
  },

  _initializeInjectionPolicy() {
    hellobar('elements.injection').overrideInjectionPolicy(function (element) {
      const dom = hellobar('base.dom');
      const container = dom.$("#hellobar-preview-container");
      if (container.children[0]) {
        container.insertBefore(element, container.children[0]);
      } else {
        container.appendChild(element);
      }
      this.notifyPreviewInjectionListeners();
    });
  },

  addPreviewInjectionListener(listener) {
    this._previewInjectionListeners.push(listener);
  },

  notifyPreviewInjectionListeners() {
    this._previewInjectionListeners.forEach((listener) => listener());
  }

});
