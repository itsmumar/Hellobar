/* globals TempUserUnsavedChangesModal, UnsavedChangesModal */

import Ember from 'ember';

import MobileMixin from './application.mixin.mobile';

export default Ember.Controller.extend(MobileMixin, {

  bus: Ember.inject.service(),
  inlineEditing: Ember.inject.service(),
  palette: Ember.inject.service(),
  theming: Ember.inject.service(),
  modelValidation: Ember.inject.service(),
  applicationSettings: Ember.inject.service(),

  goal: Ember.computed.alias('model.element_subtype'),
  style: Ember.computed.alias('model.type'),

  init() {
    this.get('modelValidation').initializeValidation();
    this._initializeInlineEditing();
    this._subscribeToBusEvents();
  },

  _initializeInlineEditing() {
    Ember.run.next(() => {
      this.get('inlineEditing').preconfigure(this.get('model.site.capabilities'));
      this.get('inlineEditing').setModelHandler(this);
    });
  },

  _subscribeToBusEvents() {
    this.get('bus').subscribe('hellobar.core.application.initialized', (/* params */) => {
      $('body').removeClass('loading');
      Ember.run.next(() => this.get('palette').detectColorPalette(this));
    });
  },


  //-----------  User  -----------#

  currentUser: Ember.computed.alias('applicationSettings.settings.current_user'),

  isTemporaryUser: function () {
    return this.get('currentUser') && this.get('currentUser').status === 'temporary';
  }.property('currentUser'),

  //-----------  State Default  -----------#

  queryParams: ['rule_id'],

  isFullscreen: false,
  saveSubmitted: false,
  modelIsDirty: false,
  rule_id: null,

  isCallGoal: Ember.computed.equal('model.element_subtype', 'call'),

  setRuleID: (function () {
    const ruleId = parseInt(this.get('rule_id'));
    // if both model and rule_id parameter exist
    if (this.get('model') && ruleId >= 0) {
      this.set('model.rule_id', ruleId);
    }
  }).observes('rule_id', 'model'),

  //-----------  Actions  -----------#

  actions: {

    closeEditor() {
      if (this.get('isTemporaryUser')) {
        new TempUserUnsavedChangesModal().open();
      } else {
        const dashboardURL = `/sites/${window.siteID}/site_elements`;
        if (this.get('modelIsDirty')) {
          const options = {
            dashboardURL,
            doSave: () => {
              this.send('saveSiteElement');
            }
          };
          new UnsavedChangesModal(options).open();
        } else {
          window.location = dashboardURL;
        }
      }
    }
  }
});
