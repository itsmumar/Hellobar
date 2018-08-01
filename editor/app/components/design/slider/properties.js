import Ember from 'ember';
import HasPlacement from '../../../mixins/has-placement-mixin';

export default Ember.Component.extend(HasPlacement, {
  placementOptions: [
    {value: 'bottom-right', label: 'Bottom right'},
    {value: 'top-right', label: 'Top right'},
    {value: 'bottom-left', label: 'Bottom left'},
    {value: 'top-left', label: 'Top left'}
  ]
});
