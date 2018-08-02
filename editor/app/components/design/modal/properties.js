import Ember from 'ember';
import HasPlacement from '../../../mixins/has-placement-mixin';

export default Ember.Component.extend(HasPlacement, {
  placementOptions: [
    {value: 'middle', label: 'Middle'},
    {value: 'top', label: 'Top'}
  ]
});
