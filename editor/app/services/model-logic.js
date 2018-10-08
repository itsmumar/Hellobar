/* globals UpgradeAccountModal, UpdateGDPRSettingsPromtModal */

import Ember from 'ember';
import _ from 'lodash/lodash';

// GLOBALS: isValidNumber, formatLocal functions
const isValidNumber = window.isValidNumber;
const formatLocal = window.formatLocal;

const DEFAULT_FIELDS = [
  {
    id: 'some-long-id-1',
    type: 'builtin-email',
    is_enabled: true
  },
  {
    id: 'some-long-id-2',
    type: "builtin-phone",
    is_enabled: false
  },
  {
    id: 'some-long-id-3',
    type: 'builtin-name',
    is_enabled: false
  }
];

/**
 * @class ModelLogic
 * Contains observers bound to the application model.
 */
export default Ember.Service.extend({

  bus: Ember.inject.service(),
  theming: Ember.inject.service(),

  /**
   * @property {object}
   */
  model: null,

  setModel(model) {
    const currentModel = this.get('model') || {};
    const newModel = _.assign(currentModel, model);
    this.set('model', newModel);
    this.get('theming').setModel(newModel);
    this.set('model.isSaved', true);
  },


  // ------ Initialization, subscribing to events

  init() {
    this._trackFieldChanges();
  },

  _trackFieldChanges() {
    this.get('bus').subscribe('hellobar.core.fields.changed', (/* params */) => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    });
  },

  isTypeSelected: function () {
    return this.get('model.type') && this.get('model.element_subtype');
  }.property('model.type', 'model.element_subtype'),

  isPublished: function () {
    return this.get('isTypeSelected') && !this.get('model.paused_at') && !this.get('model.deactivated_at') && this.get('model.id');
  }.property('model.id', 'model.paused_at','model.deactivated_at', 'isTypeSelected'),

  isNotPublished: function () {
    return this.get('isTypeSelected') && (this.get('model.paused_at') && this.get('model.deactivated_at') || !this.get('model.id'));
  }.property('model.id', 'model.paused_at','model.deactivated_at', 'isTypeSelected'),

  // ------ Fields handling

  _setDefaultEmailValues: function () {
    const elementSubtype = this.get('model.element_subtype');

    if (elementSubtype === 'email') {
      const fieldsToCollect = this.get('model.settings.fields_to_collect');

      // set default fields to collect
      if (_.isEmpty(fieldsToCollect)) {
        this.set('model.settings.fields_to_collect', DEFAULT_FIELDS.slice());
      }

      // set default contact list if one exists
      const contactLists = this.get('model.site.contact_lists');
      const selectedId = this.get('model.contact_list_id');
      if (!selectedId && !_.isEmpty(contactLists)) {
        this.set('model.contact_list_id', contactLists[0].id);
      }
    }
  }.observes('model.element_subtype'),

  updateFieldsOnElementTypeChange: function () {
    if (this.get('model.type') === 'Bar') {
      const fields = Ember.copy(this.get('model.settings.fields_to_collect'));
      _.each(fields, (field) => {
        if (field && field.type && field.type.indexOf('builtin-') !== 0) {
          field.is_enabled = false;
        }
      });
      this.set('model.settings.fields_to_collect', fields);
    }

    if (this.get('model.type') === 'Takeover') {
      this.set('model.image_style', 'large');
    } else {
      this.set('model.image_style', 'medium');
    }

    if (this.get('model.type') === 'Alert') {
      this.set('model.show_branding', false);
    } else {
      this.set('model.show_branding', this.get('model.show_branding'));
    }
    var type = (this.get('model.type') === 'Takeover') || (this.get('model.type') === 'Modal') ? 'pop-up' : 'bar';
    this.set('model.default_email_thank_you_text', "Thanks for signing up! If you would like this sort of "+ type +" on your site...");
  }.observes('model.type'),

  // ------ Template handling

  _previousElementType: null,

  unsetTemplateOnElementTypeChanged: function () {
    const elementType = this.get('model.type');
    const currentTheme = this.get('theming.currentTheme');
    const previousElementType = this.get('_previousElementType');

    if (elementType && previousElementType && elementType !== previousElementType) {
      if (currentTheme && currentTheme.type === 'template') {
        this.get('theming').setThemeById('autodetect');
      }
    }

    this.set('_previousElementType', elementType);
  }.observes('model.type'),

  // ------ Image

  resetUploadedImage() {
    const properties = {
      'model.active_image_id': null,
      'model.image_url': null,
      'model.image_small_url': null,
      'model.image_medium_url': null,
      'model.image_large_url': null,
      'model.image_modal_url': null,
      'model.image_file_name': null
    };

    return this.setProperties(properties);
  },

  setImageProps (props) {
    const {
      imageID,
      imagePlacement,
      imageUrl,
      imageLargeUrl,
      imageModalUrl,
      imageType = null
    } = props;

    const properties = {
      'model.active_image_id': imageID,
      'model.image_placement': imagePlacement,
      'model.image_url': imageUrl,
      'model.image_large_url': imageLargeUrl || imageUrl,
      'model.image_modal_url': imageModalUrl || imageUrl,
      'model.image_type': imageType
    };

    if ('useDefaultImage' in props) {
      properties['model.use_default_image'] = props.useDefaultImage;
    }

    return this.setProperties(properties);
  },

  // ------ Rule settings

  setRule (rule) {
    this.set('model.rule_id', rule && rule.id);
    this.set('model.rule', rule);
    this.set('model.preset_rule_name', 'Saved');
  },

  // ------ Cookie settings

  initializeCookieSettings: function () {
    let cookieSettings = this.get('model.settings.cookie_settings');
    if (_.isEmpty(cookieSettings)) {
      this.set('model.settings.cookie_settings', {
        duration: 3,
        success_duration: 3
      });
    }
  }.observes('model'),


  // ------ Phone number formatting

  formatPhoneNumber: function () {
    const phoneNumber = this.get('model.phone_number');
    const countryCode = this.get('model.phone_country_code');
    if (countryCode !== 'XX' && isValidNumber(phoneNumber, countryCode)) {
      this.set('model.phone_number', formatLocal(countryCode, phoneNumber));
    }
  }.observes('model.phone_number', 'model.phone_country_code'),


  // ------ Force bar usage for calls

  forceMobileModeForCall: function () {
    if (this.get('model.element_subtype') === 'call') {
      this.set('model.type', 'Bar');
    }
  }.observes('model.element_subtype'),


  // ------ Upgrade checks

  promptUpgradeWhenRemovingBranding: function () {
    const isBranded = this.get('model.show_branding');
    const isAlert = this.get('model.type') === 'Alert';
    const canRemoveBranding = this.get('model.site.capabilities.remove_branding');

    if (!isAlert && !isBranded && !canRemoveBranding) {
      this.set('model.show_branding', true);
      this.promptUpgrade('show_branding', isBranded, 'remove Hello Bar logo, upgrade your subscription for');
    }
  }.observes('model.show_branding'),

  promptUpgradeWhenLeadingQuestion: function () {
    const questionOn = this.get('model.use_question');
    const canLeadingQuestion = this.get('model.site.capabilities.leading_question');
    if (!canLeadingQuestion && questionOn) {
      this.set('model.use_question', false);
      this.promptUpgrade('use_question', questionOn, 'enable Yes/No Questions, upgrade your subscription for');
    }
  }.observes('model.use_question'),


//   document.getElementById('myDiv').onmousedown = function() {
//   alert('New mouse down handler.');
// };

  promptImageOpacity: function () {
    const opacityValue = this.get('model.image_opacity');
    const canUseImageOpacity = this.get('model.site.capabilities.image_opacity');

    if (!canUseImageOpacity && opacityValue !== 100) {
      this.set('model.image_opacity', 100);
      this.promptUpgrade('image_opacity', opacityValue, 'unlock the next level of Hello Bar, upgrade your subscription for');
      throw "Requires a paid subscription";
    }
  }.observes('model.image_opacity'),

  promptImageOverlayOpacity: function () {
    const opacityOverlayValue = this.get('model.image_overlay_opacity');
    const canUseImageOverlayOpacity = this.get('model.site.capabilities.image_overlay_opacity');
    if (!canUseImageOverlayOpacity && opacityOverlayValue !== 0) {
      this.set('model.image_overlay_opacity', 0);
      this.promptUpgrade('image_overlay_opacity', opacityOverlayValue, 'unlock the next level of Hello Bar, upgrade your subscription for');
      throw "Requires a paid subscription";
    }
  }.observes('model.image_overlay_opacity'),

  promptUpdateGDPRWhenNotEnabled: function () {
    const isGDPREnabled = this.get('model.site.gdpr_enabled');
    const enableGDPR = this.get('model.enable_gdpr');

    if (!isGDPREnabled && enableGDPR) {
      this.set('model.enable_gdpr', false);
      this.promptUpdateSettings();
    }
  }.observes('model.enable_gdpr'),

  promptUpgrade(attr, val, message) {
    const view = this;
    new UpgradeAccountModal({
      site: this.get('model.site'),
      successCallback() {
        view.set('model.site.capabilities', this.site.capabilities);
        return view.set(`model.${attr}`, val);
      },
      upgradeBenefit: message
    }).open();
  },

  promptUpdateSettings() {
    new UpdateGDPRSettingsPromtModal().open();
  }
});
