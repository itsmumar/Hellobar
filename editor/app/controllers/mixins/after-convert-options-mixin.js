import Ember from 'ember';

// TODO this mixin isn't used, we should delete it and all references to it
export default Ember.Mixin.create({

  showAfterConvertOptions: [
    {value: true, label: 'Continue showing even after the visitor responds'},
    {value: false, label: 'Stop showing after the visitor provides a response'}
  ],

  hideShowAfterConvertOptions: Ember.computed.equal('model.element_subtype', 'announcement')
});
