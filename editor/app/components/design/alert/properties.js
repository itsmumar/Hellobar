import _ from 'lodash/lodash';
import Ember from 'ember';
import HasPlacement from '../../../mixins/has-placement-mixin';

export default Ember.Component.extend(HasPlacement, {
  placementOptions: [
    {value: 'bottom-right', label: 'Bottom right'},
    {value: 'bottom-left', label: 'Bottom left'}
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
