import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  applicationController: Ember.inject.controller('application'),
  applicationSettings: Ember.computed.alias('applicationController.applicationSettings.settings'),

  theming: Ember.inject.service(),
  fonts: Ember.inject.service(),

  availableFonts: Ember.computed.alias('fonts.availableFonts'),

  //-----------  Step Settings  -----------#

  step: 3,
  prevStep: 'style',
  nextStep: 'targeting',

  imagePlacementOptions: [
    {value: 'top', label: 'Top'},
    {value: 'bottom', label: 'Bottom'},
    {value: 'left', label: 'Left'},
    {value: 'right', label: 'Right'},
    {value: 'above-caption', label: 'Above Caption'},
    {value: 'below-caption', label: 'Below Caption'}
  ],

  selectedImagePlacementOption: (function () {
    const imagePlacement = this.get('model.image_placement');
    const options = this.get('imagePlacementOptions');
    return _.find(options, imagePlacement);
  }).property('model.image_placement'),

  //-------------- Helpers ----------------#

  isABar: Ember.computed.equal('model.type', 'Bar'),
  isCustom: Ember.computed.equal('model.type', 'Custom'),

  allowImages: Ember.computed('model.type', function () {
      return this.get('model.type') !== "Bar";
    }
  ),

  themeWithImage: Ember.computed('currentTheme.image_upload_id', function () {
      return !!this.get('currentTheme.image_upload_id');
    }
  ),

  useThemeImage: Ember.computed('model.use_default_image', function () {
      return this.get('model.use_default_image') && this.get('themeWithImage');
    }
  ),

  hasUserChosenImage: Ember.computed('model.image_url', 'model.image_type', function () {
      return this.get('model.image_url') && this.get('model.image_type') !== 'default';
    }
  ),

  getImagePlacement() {
    const positionIsSelectable = this.get('currentTheme.image.position_selectable');
    const imageIsBackground = (this.get('model.image_placement') === 'background');
    const positionIsEmpty = Ember.isEmpty(this.get('model.image_placement'));

    if (!positionIsSelectable || imageIsBackground || positionIsEmpty) {
      return this.get('currentTheme.image.position_default');
    } else {
      return this.get('model.image_placement');
    }
  },

  //----------- Theme Settings  -----------#

  currentThemeIsGeneric: Ember.computed.alias('applicationController.currentThemeIsGeneric'),
  currentThemeIsTemplate: Ember.computed.alias('applicationController.currentThemeIsTemplate'),
  currentTheme: Ember.computed.alias('applicationController.currentTheme'),

  // Editor UI Properties
  imageUploadCopy: Ember.computed.oneWay('currentTheme.image.upload_copy'),

  // Site Element Theme Properties
  themeChanged: Ember.observer('currentTheme', function () {
      Ember.run.next(this, function () {
          return this.setProperties({
            'model.image_placement': this.getImagePlacement()
          });
        }
      );
    }
  ),

  defaultImageToggled: ( function () {
    if (this.get('useThemeImage')) {
      return this.setDefaultImage();
    }
  }).observes('model.use_default_image').on('init'),

  setDefaultImage() {
    const imageID = this.get('currentTheme.image_upload_id');
    const imageUrl = this.get('currentTheme.image.default_url');
    this.send('setImageProps', imageID, imageUrl, 'default');
  },

  //-----------  Text Settings  -----------#

  hideLinkText: Ember.computed.match('model.element_subtype', /social|announcement/),
  showEmailPlaceholderText: Ember.computed.equal('model.element_subtype', 'email'),
  showNamePlaceholderText: Ember.computed('model.settings.fields_to_collect', function () {
      let nameField = _.find(this.get('model.settings.fields_to_collect'), field => field.type === 'builtin-name');
      return nameField && nameField.is_enabled;
    }
  ),

  fontOptions: Ember.computed('model.theme_id', function () {
      let foundTheme = _.find(availableThemes, theme => {
          return theme.id === this.get('model.theme_id');
        }
      );

      if (foundTheme && foundTheme.fonts) {
        return _.map(foundTheme.fonts, fontId => _.find(this.get('availableFonts'), font => font.id === fontId));
      } else {
        return this.get('availableFonts');
      }
    }
  ),

  //-----------  Questions Settings  -----------#

  showQuestionFields: Ember.computed.equal('model.use_question', true),

  setQuestionDefaults: ( function () {
    if (this.get('model.use_question')) {
      if (!this.get('model.question')) {
        this.set('model.question', this.get('model.question_placeholder'));
      }
      if (!this.get('model.answer1')) {
        this.set('model.answer1', this.get('model.answer1_placeholder'));
      }
      if (!this.get('model.answer2')) {
        this.set('model.answer2', this.get('model.answer2_placeholder'));
      }
      if (!this.get('model.answer1response')) {
        this.set('model.answer1response', this.get('model.answer1response_placeholder'));
      }
      if (!this.get('model.answer2response')) {
        this.set('model.answer2response', this.get('model.answer2response_placeholder'));
      }
      if (!this.get('model.answer1link_text')) {
        this.set('model.answer1link_text', this.get('model.answer1link_text_placeholder'));
      }
      if (!this.get('model.answer2link_text')) {
        return this.set('model.answer2link_text', this.get('model.answer2link_text_placeholder'));
      }
    } else {
      Ember.run.next(() => {
        hellobar('base.preview').setAnswerToDisplay(null);
      });
    }
  }).observes('model.use_question').on('init'),

  //-----------  Color Tracking  -----------#

  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff'],
  siteColors: Ember.computed.alias('applicationController.colorPalette'),
  focusedColor: Ember.computed.alias('applicationController.focusedColor'),

  showAdditionalColors: Ember.computed.equal('model.type', 'Bar'),

  trackColorView: (function () {
    if (this.get('applicationSettings.track_editor_flow') && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person("Editor Flow", {
        step: "Color Settings",
        goal: this.get("model.element_subtype"),
        style: this.get("model.type")
      });
    }
  }).observes('model').on('init'),

  //-----------  Analytics  -----------#

  trackTextView: (function () {
    if (this.get('applicationSettings.track_editor_flow') && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person("Editor Flow", {
        step: "Content Settings",
        goal: this.get("model.element_subtype"),
        style: this.get("model.type")
      });
    }
  }).observes('model').on('init'),

  //--------- Thank you editor support -----
  shouldShowThankYouEditor: Ember.computed.equal('model.element_subtype', 'email'),

  actions: {

    selectImagePlacement(imagePlacement) {
      this.set('model.image_placement', imagePlacement.value);
    },

    eyeDropperSelected() {
      this.set('focusedColor', null);
      return false;
    },

    openUpgradeModal() {
      let controller = this;
      return new UpgradeAccountModal({
        site: controller.get('model.site'),
        upgradeBenefit: 'customize your thank you text',
        successCallback() {
          return controller.set('model.site.capabilities', this.site.capabilities);
        }
      }).open();
    },

    setImageProps(imageID, imageUrl, imageType = null) {
      return this.setProperties({
        'model.active_image_id': imageID,
        'model.image_placement': this.getImagePlacement(),
        'model.image_url': imageUrl,
        'model.image_type': imageType
      });
    },

    showQuestion() {
      hellobar('base.preview').setAnswerToDisplay(null);
      this.set('questionTabSelection', 'TabQuestion');
      return this.get('applicationController').renderPreview();
    },

    showAnswer1() {
      hellobar('base.preview').setAnswerToDisplay(1);
      this.set('questionTabSelection', 'TabAnswer1');
      return this.get('applicationController').renderPreview();
    },

    showAnswer2() {
      hellobar('base.preview').setAnswerToDisplay(2);
      this.set('questionTabSelection', 'TabAnswer2');
      return this.get('applicationController').renderPreview();
    }
  }
});
