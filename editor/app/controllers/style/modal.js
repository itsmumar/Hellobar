import Ember from 'ember';

export default Ember.Controller.extend(HelloBar.HasPlacement, HelloBar.HasTriggerOptions, HelloBar.AfterConvertOptions, {

  placementOptions: [
    {value: 'middle', label: 'Middle'},
    {value: 'top', label: 'Top'}
  ]
});
