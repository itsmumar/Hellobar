import Ember from 'ember';
import _ from 'lodash/lodash';

import HasPlacement from '../../../mixins/has-placement-mixin';
import HasTriggerOptions from '../../../mixins/has-trigger-options-mixin';

export default Ember.Component.extend(HasPlacement, HasTriggerOptions, {

  placementOptions: [
    {value: 'bottom-right', label: 'Bottom Right'},
    {value: 'bottom-left', label: 'Bottom Left'}
  ],

  soundOptions: [
    {value: 'bell', label: 'Bell'},
    {value: 'none', label: 'No sound'}
  ],

  selectedSoundOption: (function () {
    const sound = this.get('model.sound');
    const options = this.get('soundOptions');
    const selectedOption = _.find(options, (option) => option.value === sound);
    if (selectedOption) {
      return selectedOption;
    } else {
      const defaultOption = options[0];
      Ember.run.next(() => this.set('model.sound', defaultOption.value));
      return defaultOption;
    }
  }).property('model.sound'),

  actions: {
    selectSound(soundOption) {
      this.set('model.sound', soundOption.value);
    }
  }

});
