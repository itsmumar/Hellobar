import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Service.extend({
  availableThemes: Ember.computed.alias('applicationSettings.settings.available_themes'),
  applicationSettings: Ember.inject.service(),

  defaultGenericTheme() {
    return _.find(this.get('availableThemes'), (theme) => theme.type === 'generic');
  },

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
  currentThemeIsTemplate: false

});
