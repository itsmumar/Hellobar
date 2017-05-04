import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['i-need-help'],

  activated: false,

  actions: {
    onToggle() {
      this.toggleProperty('activated');
    },

    onCancel() {
      this.set('activated', false);
    }
  }

});

