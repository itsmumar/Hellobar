import Ember from 'ember';

export default Ember.Component.extend({

  bus: Ember.inject.service(),
  imaging: Ember.inject.service(),

  classNames: ['theme-tile'],

  /**
   * @property [object] Theme object. Can be empty.
   */
  theme: null,

  /**
   * @property {string} Element type (Bar, Modal, Slider, Takeover). Required property.
   */
  elementType: null,

  imageSrc: (function () {
    const elementTypeFolder = (this.get('elementType') || '').toLowerCase();
    const theme = this.get('theme');
    if (theme) {
      return this.get('imaging').imagePath(`themes/tiles/${elementTypeFolder}/${this.get('theme.id')}.png`);
    } else {
      // TODO use special image
      return this.get('imaging').imagePath(`themes/tiles/${elementTypeFolder}/classic.png`);
    }
  }).property('theme', 'elementType'),

  init() {
    return this._super();
  },

  selectButtonIsVisible: false,

  mouseEnter() {
    this.set('selectButtonIsVisible', true);
  },

  mouseLeave() {
    this.set('selectButtonIsVisible', false);
  },

  actions: {
    select() {
      this.get('bus').trigger('hellobar.core.bar.themeChanged', {
        themeId: this.get('theme.id'),
        elementType: this.get('elementType')
      });
      this.get('bus').trigger('hellobar.core.rightPane.hide');
    }
  }
});


