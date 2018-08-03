import Ember from 'ember';
import HasPlacement from '../../../mixins/has-placement-mixin';

export default Ember.Component.extend(HasPlacement, {
  elementPlacement: Ember.inject.service(),

  placementOptions: Ember.computed.alias('elementPlacement.modalPlacement')
});
