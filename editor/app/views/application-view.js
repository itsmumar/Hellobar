console.log('Application View declaration');

HelloBar.ApplicationView = Ember.View.extend({

  classNames: ['editor-wrapper'],
  classNameBindings: ['isMobile', 'isFullscreen', 'isCallType'],

  //-----------  State Bindings  -----------#

  // Tracks the application state properties from the application router
  // and uses them to generate state-specific classes for CSS. All
  // animations are handled by CSS transitions and toggleing classes.

  isMobile: Ember.computed.alias('controller.isMobile'),
  isFullscreen: Ember.computed.alias('controller.isFullscreen'),
  isCallType: Ember.computed.equal('controller.model.element_subtype', 'call'),

  //-----------  Click Action  -----------#

  click(obj) {
    let isCanvas = obj.target.localName === 'canvas';
    let isColorSelect = $(obj.target).closest('.color-select-wrapper').length;

    if (!isCanvas && !isColorSelect) {
      return this.set('controller.focusedColor', null);
    }
  }
});
