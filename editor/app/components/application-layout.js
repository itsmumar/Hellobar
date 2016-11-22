import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['editor-wrapper'],
  classNameBindings: ['isMobile', 'isFullscreen', 'isCallType'],

  //-----------  State Bindings  -----------#

  // Tracks the application state properties from the application router
  // and uses them to generate state-specific classes for CSS. All
  // animations are handled by CSS transitions and toggleing classes.

  // TODO uncomment and adopt?
  //isMobile: Ember.computed.alias('controller.isMobile'),
  //isFullscreen: Ember.computed.alias('controller.isFullscreen'),
  //isCallType: Ember.computed.equal('controller.model.element_subtype', 'call'),

  //-----------  Click Action  -----------#

  click(obj) {
    let isCanvas = obj.target.localName === 'canvas';
    let isColorSelect = $(obj.target).closest('.color-select-wrapper').length;

    if (!isCanvas && !isColorSelect) {
      // TODO improve this
      return this.set('applicationController.focusedColor', null);
    }
  }

});
