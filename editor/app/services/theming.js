import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({

  applicationSettings: Ember.inject.service(),
  availableThemes: Ember.computed.alias('applicationSettings.settings.available_themes'),

  defaultGenericTheme: function() {
    return _.find(this.get('availableThemes'), (theme) => theme.type === 'generic');
  }.property('availableThemes'),

  autodetectedTheme() {
    return {
      name: 'Autodetected',
      type: 'generic',
      id: 'autodetected',
      fonts: [
        'open_sans',
        'source_pro',
        'helvetica',
        'arial',
        'georgia'
      ],
      'element_types': ['Bar', 'Modal', 'Slider', 'Takeover'],
      defaults: {},
      image: {
        position_default: 'left',
        position_selectable: true
      }
    };

  },

  // TODO REFACTOR implement
  currentThemeIsGeneric: true,
  currentThemeIsTemplate: false,
  currentTheme: Ember.computed.alias('defaultGenericTheme'),

  currentThemeName: (function () {
    const theme = this.get('currentTheme');
    return theme ? theme.name : '';
  }).property('currentTheme')


  // TODO REFACTOR adopt (move to modelLogic?)
  /*themeChanged: Ember.observer('currentThemeName', function () {
      return Ember.run.next(this, function () {
          return this.setProperties({
            'model.image_placement': this.getImagePlacement()
          });
        }
        //'model.use_default_image' : false
      );
    }
  )*/

});
