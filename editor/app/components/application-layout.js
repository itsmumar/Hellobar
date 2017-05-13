import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['editor-wrapper'],
  classNameBindings: ['isMobile', 'isFullscreen', 'isCallType'],

  bus: Ember.inject.service(),
  palette: Ember.inject.service(),

  didRender() {
    Ember.run.next(() => this.get('bus').trigger('hellobar.core.application.initialized'));
  },

  //-----------  Click Action  -----------#

  click(obj) {
    const isCanvas = obj.target.localName === 'canvas';
    const isColorSelect = $(obj.target).closest('.color-select-wrapper').length;

    // TODO REFACTOR move this to service
    if (!isCanvas && !isColorSelect) {
      this.set('palette.focusedColor', null);
    }
  }

});
