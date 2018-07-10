import Ember from 'ember';
import { VIEW_DESKTOP, VIEW_TABLET, VIEW_MOBILE } from '../../constants';

export default Ember.Component.extend({
  modelLogic: Ember.inject.service(),

  viewName: function () {
    switch (this.get('viewMode')) {
      case VIEW_DESKTOP:
        return 'Desktop';
        break;
      case VIEW_TABLET:
        return 'Tablet';
        break;
      case VIEW_MOBILE:
        return 'Mobile';
        break;
      default:
        return 'Desktop';
    }
  }.property('viewMode'),

  /**
   * @property {boolean}
   */
  isFullscreen: false,

  /**
   * @property {string}
   */
  goal: true,

  /**
   * @property {string}
   */
  style: true,

  tagName: 'nav',

  classNames: ['step-navigation', 'links-wrapper'],

  actions: {
    toggleView() {
      if (this.get('modelLogic.model.element_subtype') === 'call') {
        return;
      }

      switch (this.get('viewMode')) {
        case VIEW_DESKTOP:
          this.set('viewMode', VIEW_TABLET);
          break;
        case VIEW_TABLET:
          this.set('viewMode', VIEW_MOBILE);
          break;
        case VIEW_MOBILE:
          this.set('viewMode', VIEW_DESKTOP);
          break;
        default:
          this.set('viewMode', VIEW_DESKTOP);
      }
    },

    toggleFullscreen() {
      this.toggleProperty('isFullscreen');
    },

    closeEditor() {
      this.sendAction('closeEditor');
    }
  }

});
