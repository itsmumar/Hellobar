import Ember from 'ember';
import _ from 'lodash/lodash';

// GLOBALS: isValidNumber, formatLocal functions
const isValidNumber = window.isValidNumber;
const formatLocal = window.formatLocal;

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
    this.get('bus').subscribe('hellobar.core.fields.changed', (params) => {
      this.notifyPropertyChange('model.settings.fields_to_collect');
    });
  },


  // ------ Fields handling

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
      if (currentTheme && (currentTheme.type === 'template')) {
        // FIXME I think we should trigger `themeChanged` event
        // if not, we should at least update whole `theme` object here
        this.set('model.theme_id', 'autodetected');
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

    return this.setProperties({
      'model.active_image_id': imageID,
      'model.image_placement': imagePlacement,
      'model.image_url': imageUrl,
      'model.image_small_url': imageSmallUrl || imageUrl,
      'model.image_medium_url': imageMediumUrl || imageUrl,
      'model.image_large_url': imageLargeUrl || imageUrl,
      'model.image_modal_url': imageModalUrl || imageUrl,
      'model.image_type': imageType
    });
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
