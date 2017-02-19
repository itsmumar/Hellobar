import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['editor-wrapper'],
  classNameBindings: ['isMobile', 'isFullscreen', 'isCallType'],

  bus: Ember.inject.service(),

  didRender() {
    Ember.run.next(() => this.get('bus').trigger('hellobar.core.application.initialized'));
  },

  //-----------  Click Action  -----------#

  click(obj) {
    const isCanvas = obj.target.localName === 'canvas';
    const isColorSelect = $(obj.target).closest('.color-select-wrapper').length;

    if (!isCanvas && !isColorSelect) {
      this.set('applicationController.focusedColor', null);
    }
  }

});
