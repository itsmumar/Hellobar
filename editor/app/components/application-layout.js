import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['editor-wrapper'],
  classNameBindings: ['isMobile', 'isFullscreen', 'isCallType'],

  //-----------  State Bindings  -----------#

  // Tracks the application state properties from the application router
  // and uses them to generate state-specific classes for CSS. All
  // animations are handled by CSS transitions and toggleing classes.



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
