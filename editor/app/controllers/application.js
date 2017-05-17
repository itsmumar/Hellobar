import Ember from 'ember';
import _ from 'lodash/lodash';

import MobileMixin from './application.mixin.mobile';
import TypeAndSubtypeMixin from './application.mixin.type-and-subtype';
import UpgradingMixin from './application.mixin.upgrading';

export default Ember.Controller.extend(
  MobileMixin,
  TypeAndSubtypeMixin,
  UpgradingMixin, {

    bus: Ember.inject.service(),
    inlineEditing: Ember.inject.service(),
    palette: Ember.inject.service(),
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
      this.get('bus').subscribe('hellobar.core.application.initialized', params => {
        $('body').removeClass('loading');
        Ember.run.next(() => this.get('palette').detectColorPalette(this));
      });
    },


    //-----------  User  -----------#

    currentUser: Ember.computed.alias('applicationSettings.settings.current_user'),

    isTemporaryUser: function () {
      return this.get('currentUser') && this.get('currentUser').status === 'temporary';
    }.property('currentUser'),

    //-----------  Step Tracking  -----------#

    // Tracks global step tracking
    // (primarily observed by the step-navigation component)

    prevRoute: null,
    nextRoute: null,
    currentStep: false,
    cannotContinue: true,

    //-----------  State Default  -----------#

    queryParams: ['rule_id'],

    isFullscreen: false,
    saveSubmitted: false,
    modelIsDirty: false,
    rule_id: null,

    doneButtonText: (() => 'Save & Publish').property(),

    setRuleID: (function () {
      const ruleId = parseInt(this.get('rule_id'));
      // if both model and rule_id parameter exist
      if (this.get('model') && ruleId >= 0) {
        this.set('model.rule_id', ruleId);
      }
    }).observes('rule_id', 'model'),

    //-----------  Actions  -----------#

    actions: {

      toggleFullscreen() {
        this.toggleProperty('isFullscreen');
        return false;
      },

      toggleModal() {
        this.set('modal', null);
        return false;
      },

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
