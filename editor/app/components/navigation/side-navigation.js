import Ember from 'ember';
import { VIEW_DESKTOP, VIEW_TABLET, VIEW_MOBILE } from '../../constants';

export default Ember.Component.extend({
  modelLogic: Ember.inject.service(),

  viewName: function () {
    switch (this.get('viewMode')) {
      case VIEW_DESKTOP:
        return 'Desktop';
      case VIEW_TABLET:
        return 'Tablet';
      case VIEW_MOBILE:
        return 'Mobile';
      default:
        return 'Desktop';
    }
  }.property('viewMode'),

  tagName: 'nav',

  classNames: ['step-navigation', 'links-wrapper'],

  didRender () {
    this._super(...arguments);
    this.updateProgress(this.$('li.active'));
  },

  updateProgress (element) {
    this.$('.step-links__item').removeClass('done');
    this.$(element).prevAll('li').find('.step-links__item').addClass('done');
  },

  actions: {
    updateProgress (e) {
      this.updateProgress(this.$(e.target).parents('li'));
    },

    toggleView () {
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

    closeEditor() {
      this.sendAction('closeEditor');
    }
  }

});
