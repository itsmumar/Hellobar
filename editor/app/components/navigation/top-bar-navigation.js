/* globals UnsavedChangesModal */

import Ember from 'ember';
import { VIEW_DESKTOP, VIEW_TABLET, VIEW_MOBILE } from '../../constants';

export default Ember.Component.extend({
  classNames: ['top-bar-navigation'],

  tagName: 'nav',

  bus: Ember.inject.service(),
  saveSiteElementService: Ember.inject.service(),
  modelLogic: Ember.inject.service(),

  isDesktop: Ember.computed.equal('viewMode', VIEW_DESKTOP),
  isTablet: Ember.computed.equal('viewMode', VIEW_TABLET),
  isMobile: Ember.computed.equal('viewMode', VIEW_MOBILE),

  init() {
    this._super();
    this._subscribeToValidationEvents();
    this.set('dashboardURL', `/sites/${ window.siteID }/site_elements`);
  },

  _subscribeToValidationEvents() {
    this.get('bus').subscribe('hellobar.core.validation.failed', (failures) => {
      this.set('validationMessages', failures.map(failure => failure.error));
    });
    this.get('bus').subscribe('hellobar.core.validation.succeeded', () => {
      this.set('validationMessages', null);
    });
  },

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

  actions: {
    setView(viewMode) {
      if (this.get('modelLogic.model.element_subtype') === 'call') {
        return;
      }
      this.set('viewMode', viewMode);
    },

    cancel() {
      if (this.get('modelLogic.isTypeSelected') && !this.get('modelLogic.model.isSaved')) {
        const options = {
          dashboardURL: this.get('dashboardURL'),
          doSave: () => {
            this.send('saveAndClose');
          }
        };
        new UnsavedChangesModal(options).open();

      } else {
        window.location = this.get('dashboardURL');
      }
    },

    saveAndClose () {
      this.get('saveSiteElementService').save().then(() => {
        window.location = this.get('dashboardURL');
      });
    },

    saveAndPublish () {
      if (this.get('modelLogic.isTypeSelected')) {
        this.get('saveSiteElementService').saveAndPublish();
      }
    },

    save () {
      if (this.get('modelLogic.isTypeSelected')) {
        this.get('saveSiteElementService').save().then(() => {
          window.location = this.get('dashboardURL');
      });
      }
    }
  }
});
