import Ember from 'ember';

import HasPlacement from '../../../mixins/has-placement-mixin';
import HasTriggerOptions from '../../../mixins/has-trigger-options-mixin';

export default Ember.Component.extend(HasPlacement, HasTriggerOptions, {

  placementOptions: [
    {value: 'bottom-right', label: 'Bottom Right'},
    {value: 'top-right', label: 'Top Right'},
    {value: 'bottom-left', label: 'Bottom Left'},
    {value: 'top-left', label: 'Top Left'}
  ]

});
