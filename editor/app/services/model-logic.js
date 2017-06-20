/* globals UpgradeAccountModal */

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
    this.set('model', model);
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

  setImageProps (props) {
    const {
      imageID,
      imagePlacement,
      imageUrl,
      imageSmallUrl,
      imageMediumUrl,
      imageLargeUrl,
      imageModalUrl,
      imageType = null
    } = props;

    const properties = {
      'model.active_image_id': imageID,
      'model.image_placement': imagePlacement,
      'model.image_url': imageUrl,
      'model.image_small_url': imageSmallUrl || imageUrl,
      'model.image_medium_url': imageMediumUrl || imageUrl,
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
      const elementType = this.get('model.type');
      if (elementType === 'Modal' || elementType === 'Takeover') {
        cookieSettings = {
          duration: 0,
          success_duration: 0
        };
      } else {
        cookieSettings = {
          duration: 0,
          success_duration: 0
        };
      }

      this.set('model.settings.cookie_settings', cookieSettings);
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
    const canRemoveBranding = this.get('model.site.capabilities.remove_branding');

    if (!isBranded && !canRemoveBranding) {
      this.set('model.show_branding', true);
      this.promptUpgrade('show_branding', isBranded, 'remove branding');
    }
  }.observes('model.show_branding'),

  promptUpgradeWhenEnablingHiding: function () {
    const isClosable = this.get('model.closable');
    const canBeClosable = this.get('model.site.capabilities.closable');

    if (isClosable && !canBeClosable) {
      this.set('model.closable', false);
      const elementTypeName = (this.get('model.type') || 'Bar').toLowerCase();
      this.promptUpgrade('closable', isClosable, `allow hiding a ${elementTypeName}`);
    }
  }.observes('model.closable'),

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
  }

});
