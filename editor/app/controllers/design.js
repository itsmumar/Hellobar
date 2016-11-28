import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Controller.extend({

  applicationController: Ember.inject.controller('application'),

  needs: ['application'],

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

  selectedImagePlacementOption: (function() {
    const imagePlacement = this.get('model.image_placement');
    const options = this.get('imagePlacementOptions');
    return _.find(options, imagePlacement);
  }).property('model.image_placement'),

  //-------------- Helpers ----------------#

  isABar: Ember.computed.equal('model.type', 'Bar'),

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
    let positionIsSelectable = this.get('currentTheme.image.position_selectable');
    let imageIsbackground = (this.get('model.image_placement') === 'background');
    let positionIsEmpty = Ember.isEmpty(this.get('model.image_placement'));

    if (!positionIsSelectable) {
      return this.get('currentTheme.image.position_default');
    } else if (imageIsbackground || positionIsEmpty) {
      return this.get('currentTheme.image.position_default');
    } else {
      return this.get('model.image_placement');
    }
  },

  //----------- Theme Settings  -----------#

  themeOptions: availableThemes,

  currentTheme: Ember.computed('model.theme_id', 'themeOptions', function () {
      return _.find(this.get('themeOptions'), theme => theme.id === this.get('model.theme_id'));
    }
  ),

  // Editor UI Properties
  imageUploadCopy: Ember.computed.oneWay('currentTheme.image.upload_copy'),
  showImagePlacementField: Ember.computed.oneWay('currentTheme.image.position_selectable'),

  // Site Element Theme Properties
  themeChanged: Ember.observer('currentTheme', function () {
      return Ember.run.next(this, function () {
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
    let imageID = this.get('currentTheme.image_upload_id');
    let imageUrl = this.get('currentTheme.image.default_url');
    return this.send('setImageProps', imageID, imageUrl, 'default');
  },

  // Workaround for known Ember.Select issues: https://github.com/emberjs/ember.js/issues/4150
  emberSelectWorkaround: Ember.observer('currentTheme', function () {
      this.set('showImagePlacementField', false);
      return Ember.run.next(this, function () {
          return this.set('showImagePlacementField', this.get('currentTheme.image.position_selectable'));
        }
      );
    }
  ),

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
        return _.map(foundTheme.fonts, fontId =>
            _.find(availableFonts, font => font.id === fontId
            )
        );
      } else {
        return availableFonts;
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
    }
  }).observes('model.use_question').on('init'),

  setHBCallbacks: ( () =>
      // Listen for when question answers are pressed and change the question tabs
      // TODO refactor (use ivy-tabs features)
      HB.on && HB.on("answerSelected", choice => {
          this.set('model.paneSelectedIndex', choice);
          this.set('paneSelection', (this.get('paneSelection') || 0) + 1);
          return this.send(`showResponse${choice}`);
        }
      )
  ).on("init"),

  //-----------  Color Tracking  -----------#

  recentColors: ['ffffff', 'ffffff', 'ffffff', 'ffffff'],
  siteColors: Ember.computed.alias('controllers.application.colorPalette'),
  focusedColor: Ember.computed.alias('controllers.application.focusedColor'),

  showAdditionalColors: Ember.computed.equal('model.type', 'Bar'),

  trackColorView: (function () {
    if (trackEditorFlow && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person("Editor Flow", {
        step: "Color Settings",
        goal: this.get("model.element_subtype"),
        style: this.get("model.type")
      });
    }
  }).observes('model').on('init'),

  //-----------  Analytics  -----------#

  trackTextView: (function () {
    if (trackEditorFlow && !Ember.isEmpty(this.get('model'))) {
      return InternalTracking.track_current_person("Editor Flow", {
        step: "Content Settings",
        goal: this.get("model.element_subtype"),
        style: this.get("model.type")
      });
    }
  }).observes('model').on('init'),

  actions: {

    selectTheme(theme) {
      // TODO handle action (set model.theme_id)
      console.log(theme);
    },

    selectImagePlacement(imagePlacement) {
      this.set('model.image_placement', imagePlacement.value);
    },

    eyeDropperSelected() {
      let type = this.get('model.type');
      if (type === 'Modal' || type === 'Takeover') {
        this.set('focusedColor', null);
      }
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
      HB.showResponse = null;
      this.set('questionTabSelection', 'TabQuestion');
      return this.get('applicationController').renderPreview();
    },

    showResponse1() {
      HB.showResponse = 1;
      this.set('questionTabSelection', 'TabAnswer1');
      return this.get('applicationController').renderPreview();
    },

    showResponse2() {
      HB.showResponse = 2;
      this.set('questionTabSelection', 'TabAnswer2');
      return this.get('applicationController').renderPreview();
    }
  }
});
