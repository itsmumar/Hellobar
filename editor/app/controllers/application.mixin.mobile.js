import Ember from 'ember';

export default Ember.Mixin.create({

  isMobile: false,

  forceMobileModeForCall: function () {
    if (this.get('model.element_subtype') === 'call') {
      this.set('isMobile', true);
    }
  }.observes('model.element_subtype'),

  actions: {
    toggleMobile() {
      this.toggleProperty('isMobile');
      return false;
    }
  }

});
