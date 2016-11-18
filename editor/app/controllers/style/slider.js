import Ember from 'ember';

export default Ember.Controller.extend(HelloBar.HasPlacement, HelloBar.HasTriggerOptions, HelloBar.AfterConvertOptions, {

  placementOptions: [
    {value: 'bottom-right', label: 'Bottom Right'},
    {value: 'top-right', label: 'Top Right'},
    {value: 'bottom-left', label: 'Bottom Left'},
    {value: 'top-left', label: 'Top Left'}
  ]
});
