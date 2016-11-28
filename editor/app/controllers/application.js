import Ember from 'ember';

export default Ember.Controller.extend({

  init() {
    Ember.run.next(() => {
        if (this.get('model.id') === null) {
          return this.applyCurrentTheme();
        }
      }
    );
    return HelloBar.inlineEditing.setModelHandler(this);
  },


  //-----------  User  -----------#

  currentUser: ( () => window.currentUser).property(),
  isTemporaryUser: ( function () {
    return this.get('currentUser') && this.get('currentUser').status === 'temporary';
  }).property('currentUser'),

  //-----------  Step Tracking  -----------#

  // Tracks global step tracking
  // (primarily observed by the step-navigation component)

  prevRoute: null,
  nextRoute: null,
  currentStep: false,
  cannotContinue: true,

  //-----------  Color Palette  -----------#

  // Generates color palette from screengrab
  // (primarily observed by the color-picker component)

  colorPalette: [],
  focusedColor: null,

  //-----------  Element Preview  -----------#

  // Render the element in the preview pane whenever style-affecting attributes change

  renderPreview: ( function () {
    return Ember.run.debounce(this, this.doRenderPreview, 500);
  }).observes(
    "model.answer1",
    "model.answer1caption",
    "model.answer1link_text",
    "model.answer1response",
    "model.answer2",
    "model.answer2caption",
    "model.answer2link_text",
    "model.answer2response",
    "model.background_color",
    "model.border_color",
    "model.button_color",
    "model.caption",
    "model.closable",
    "model.element_subtype",
    "model.email_placeholder",
    "model.font_id",
    "model.headline",
    "model.image_placement",
    "model.image_url",
    "model.link_color",
    "model.link_style",
    "model.link_text",
    "model.name_placeholder",
    "model.phone_country_code",
    "model.phone_number",
    "model.placement",
    "model.pushes_page_down",
    "model.question",
    "model.remains_at_top",
    "model.settings.buffer_message",
    "model.settings.buffer_url",
    "model.settings.collect_names",
    "model.settings.fields_to_collect",
    "model.settings.link_url",
    "model.settings.message_to_tweet",
    "model.settings.pinterest_description",
    "model.settings.pinterest_full_name",
    "model.settings.pinterest_image_url",
    "model.settings.pinterest_url",
    "model.settings.pinterest_user_url",
    "model.settings.twitter_handle",
    "model.settings.url_to_like",
    "model.settings.url_to_plus_one",
    "model.settings.url_to_share",
    "model.settings.url_to_tweet",
    "model.settings.url",
    "model.settings.use_location_for_url",
    "model.show_after_convert",
    "model.show_branding",
    "model.size",
    "model.text_color",
    "model.theme_id",
    "model.type",
    "model.use_question",
    "model.view_condition",
    "model.wiggle_button",
    "isFullscreen",
    "isMobile"
  ).on("init"),

  renderPreviewWithAnimations: ( function () {
    return Ember.run.debounce(this, this.doRenderPreview, true, 500);
  }).observes("model.animated").on("init"),

  doRenderPreview(withAnimations = false) {
    let previewElement = $.extend({}, this.get("model"), {
        animated: withAnimations && this.get("model.animated"),
        hide_destination: true,
        open_in_new_window: this.get("model.open_in_new_window"),
        primary_color: this.get("model.background_color"),
        pushes_page_down: this.get("model.pushes_page_down"),
        remains_at_top: this.get("model.remains_at_top"),
        secondary_color: this.get("model.button_color"),
        show_border: false,
        size: this.get("model.size"),
        subtype: this.get("model.element_subtype"),
        tab_side: "right",
        template_name: this.get("model.type").toLowerCase() + "_" + (this.get("model.element_subtype") || "traffic"),
        thank_you_text: "Thank you for signing up!",
        wiggle_button: this.get("model.wiggle_button"),
        wiggle_wait: 0,
        font: this.getFont().value,
        google_font: this.getFont().google_font
      }
    );

    HB.isPreviewMode = true;
    HB.previewMode = this.get('isMobile') ? 'mobile' : 'fullscreen';
    HB.removeAllSiteElements();
    HB.addToPage(HB.createSiteElement(previewElement));
    return HB.isMobileWidth = "changed";
  },


  // Sets a callback on the preview script to rerender the preview after the user
  // closes the element
  setRerenderOnClose: ( function () {
    let that = this;
    let callback = function () {
      let delayedFunc = () => Ember.run.debounce(that, that.doRenderPreview, false, 500);
      return setTimeout(delayedFunc, 1000);
    };

    return HB.on("elementDismissed", callback);
  }).on('init'),

  //-----------  State Default  -----------#

  // Tracks global application states & catches actions
  // (primarily observed by the application-view)

  queryParams: ['rule_id'],
  isMobile: false,
  isFullscreen: false,
  saveSubmitted: false,
  modelIsDirty: false,
  rule_id: null,

  doneButtonText: (() => "Save & Publish").property(),

  setRuleID: (function () {
    let ruleId = parseInt(this.get("rule_id"));
    // if both model and rule_id parameter exist
    if (this.get("model") && ruleId >= 0) {
      return this.set("model.rule_id", ruleId);
    }
  }).observes("rule_id", "model"),

  // Model properties are all updated when the model is initially loaded, but we only want to set this flag on any property changes
  // that happen AFTER that initialization. By using an observesBefore here and only setting the flag if the property being changed
  // is not null or undefined before the change, we avoid setting the flag until the property has had an initial value set.

  setModelIsDirty: ( function (obj, keyName) {
    if (!!this.get(keyName)) {
      return this.set("modelIsDirty", true);
    }
  }).observesBefore(
    "model.animated",
    "model.answer1",
    "model.answer1caption",
    "model.answer1link_text",
    "model.answer1response",
    "model.answer2",
    "model.answer2caption",
    "model.answer2link_text",
    "model.answer2response",
    "model.background_color",
    "model.border_color",
    "model.button_color",
    "model.caption",
    "model.closable",
    "model.contact_list_id",
    "model.element_subtype",
    "model.email_placeholder",
    "model.font_id",
    "model.headline",
    "model.image_placement",
    "model.image_url",
    "model.link_color",
    "model.link_style",
    "model.link_text",
    "model.name_placeholder",
    "model.phone_country_code",
    "model.phone_number",
    "model.placement",
    "model.pushes_page_down",
    "model.question",
    "model.remains_at_top",
    "model.settings.buffer_message",
    "model.settings.buffer_url",
    "model.settings.collect_names",
    "model.settings.link_url",
    "model.settings.message_to_tweet",
    "model.settings.pinterest_description",
    "model.settings.pinterest_full_name",
    "model.settings.pinterest_image_url",
    "model.settings.pinterest_url",
    "model.settings.pinterest_user_url",
    "model.settings.redirect_url",
    "model.settings.redirect",
    "model.settings.twitter_handle",
    "model.settings.url_to_like",
    "model.settings.url_to_plus_one",
    "model.settings.url_to_share",
    "model.settings.url_to_tweet",
    "model.settings.url",
    "model.settings.use_location_for_url",
    "model.show_after_convert",
    "model.show_branding",
    "model.size",
    "model.text_color",
    "model.theme_id",
    "model.type",
    "model.use_question",
    "model.wiggle_button",
    "model.use_default_image"
  ),

  //---------------- Font Helpers ----------------#

  getFont() {
    let fontId = this.get("model.font_id");
    return _.find(availableFonts, font => font.id === fontId
    );
  },

  //-----------  Phone Number Helpers  -----------#

  isCallType: Ember.computed.equal('model.element_subtype', 'call'),

  setPhoneDefaults: (function () {
    if (this.get('model.element_subtype') === 'call') {
      return this.set("isMobile", true);
    }
  }).observes("model.element_subtype").on("init"),

  formatPhoneNumber: (function () {
    let phone_number = this.get("phone_number") || this.get("model.phone_number");
    let country_code = this.get("model.phone_country_code");

    if (country_code === "XX") { // custom country code
      this.set("model.phone_number", phone_number);
      return this.set("phone_number", phone_number);
    } else if (isValidNumber(phone_number, country_code)) {
      this.set("phone_number", formatLocal(country_code, phone_number));
      return this.set("model.phone_number", formatE164(country_code, phone_number));
    } else {
      return this.set("model.phone_number", null);
    }
  }).observes("model.phone_number", "phone_number", "model.phone_country_code"),

  applyCurrentTheme() {
    let allThemes = availableThemes;
    let currentThemeId = this.get('model.theme_id');
    let currentTheme = _.find(allThemes, theme => currentThemeId === theme.id);
    let themeStyleDefaults = currentTheme.defaults[this.get('model.type')] || {};
    return _.each(themeStyleDefaults, (value, key) => {
        return this.set(`model.${key}`, value);
      }
    );
  },

  onCurrentThemeChanged: (function () {
    if (this.get('originalTheme').theme_id === this.get('model.theme_id')) {
      return _.each(this.get('originalTheme'), (value, key) => {
          return this.set(`model.${key}`, value);
        }
      );
    } else {
      return this.applyCurrentTheme();
    }
  }).observes('model.theme_id'),

  //-----------  Actions  -----------#

  actions: {

    toggleFullscreen() {
      this.toggleProperty('isFullscreen');
      return false;
    },

    toggleMobile() {
      if (this.get("model.element_subtype") !== "call") {
        this.toggleProperty('isMobile');
      }
      return false;
    },

    toggleModal() {
      this.set('modal', null);
      return false;
    },

    saveSiteElement() {
      this.toggleProperty('saveSubmitted');
      return true;
    },

    closeEditor() {
      if (this.get('isTemporaryUser')) {
        return new TempUserUnsavedChangesModal().open();
      } else {
        let dashboardURL = `/sites/${window.siteID}/site_elements`;

        if (this.get("modelIsDirty")) {
          let options = {
            dashboardURL,
            doSave: () => {
              return this.send("saveSiteElement");
            }
          };

          return new UnsavedChangesModal(options).open();
        } else {
          return window.location = dashboardURL;
        }
      }
    }
  }
});
