import Ember from 'ember';

export default Ember.Service.extend({


  options: [
    {value: 'immediately', label: 'Immediately'},
    {value: 'exit-intent', label: 'Exit intent (user begins to leave your site)'},
    {value: 'wait-5', label: '5 second delay'},
    {value: 'wait-10', label: '10 second delay'},
    {value: 'wait-15', label: '15 second delay'},
    {value: 'wait-20', label: '20 second delay'},
    {value: 'wait-25', label: '25 second delay'},
    {value: 'wait-30', label: '30 second delay'},
    {value: 'wait-45', label: '45 second delay'},
    {value: 'wait-60', label: '60 second delay'},
    {value: 'wait-120', label: '2 minutes delay'},
    {value: 'scroll-some', label: 'After scrolling a little'},
    {value: 'scroll-middle', label: 'After scrolling to middle'},
    {value: 'scroll-to-bottom', label: 'After scrolling to bottom'},
  ],
  nonBarOptions: [
    {value: 'exit-intent', label: 'Exit intent (user begins to leave your site)'},
    {value: 'wait-5', label: '5 second delay'},
    {value: 'wait-10', label: '10 second delay'},
    {value: 'wait-15', label: '15 second delay'},
    {value: 'wait-20', label: '20 second delay'},
    {value: 'wait-25', label: '25 second delay'},
    {value: 'wait-30', label: '30 second delay'},
    {value: 'wait-45', label: '45 second delay'},
    {value: 'wait-60', label: '60 second delay'},
    {value: 'wait-120', label: '2 minutes delay'},
    {value: 'scroll-some', label: 'After scrolling a little'},
    {value: 'scroll-middle', label: 'After scrolling to middle'},
    {value: 'scroll-to-bottom', label: 'After scrolling to bottom'},
  ],

  alertDefaultTrigger: 'wait-5',
  barDefaultTrigger: 'wait-5',
  modalDefaultTrigger: 'wait-10',
  takeoverDefaultTrigger: 'exit-intent',
  sliderDefaultTrigger: 'wait-10',

  defaultTriggerFor (type) {
    const method = `${ type.toLowerCase() }DefaultTrigger`;
    return this.get(method);
  },

  updateTrigger (component, type) {
    const defaultTrigger = this.defaultTriggerFor(type);
    component.set('model.view_condition', defaultTrigger);
  }
});
