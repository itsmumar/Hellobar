import Ember from 'ember';
import _ from 'lodash/lodash';

export default Ember.Mixin.create({

  selectedPlacementOption: function () {
    const placement = this.get('model.placement');
    const options = this.get('placementOptions');
    const selectedOption = _.find(options, (option) => option.value === placement);
    if (selectedOption) {
      return selectedOption;
    } else {
      const defaultOption = options[0];
      Ember.run.next(() => this.set('model.placement', defaultOption.value));
      return defaultOption;
    }
  }.property('model.placement'),

  actions: {
    selectPlacement(placementOption) {
      placementOption && placementOption.value && this.set('model.placement', placementOption.value);
    }
  }

});
