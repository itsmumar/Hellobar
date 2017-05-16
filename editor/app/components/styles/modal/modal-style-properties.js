import Ember from 'ember';

import HasPlacement from '../../../mixins/has-placement-mixin';
import HasTriggerOptions from '../../../mixins/has-trigger-options-mixin';

export default Ember.Component.extend(HasPlacement, HasTriggerOptions, {

  placementOptions: [
    {value: 'middle', label: 'Middle'},
    {value: 'top', label: 'Top'}
  ]

});
