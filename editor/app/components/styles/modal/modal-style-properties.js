import Ember from 'ember';

import HasPlacement from '../../../mixins/has-placement-mixin';
import HasTriggerOptions from '../../../mixins/has-trigger-options-mixin';
import ElementSubtype from '../../../mixins/element-subtype-mixin';

export default Ember.Component.extend(HasPlacement, HasTriggerOptions, ElementSubtype, {
  placementOptions: [
    {value: 'middle', label: 'Middle'},
    {value: 'top', label: 'Top'}
  ]
});
