import Ember from 'ember';

export default Ember.Mixin.create({

  isMobile: false,

  forceMobileBarForCall: function () {
    if (this.get('model.element_subtype') === 'call') {
      this.set('isMobile', true);
    }
  }.observes('model.element_subtype'),

  manageMobileOnTypeAndSubtypeChange: function () {
    const elementType = this.get('model.type');
    const currentTheme = this.get('theming.currentTheme');
    const elementSubtype = this.get('model.element_subtype');
    const isMobile = this.get('isMobile');
    if (elementType !== 'Bar' && currentTheme.type === 'generic' && elementSubtype !== 'call' && isMobile) {
      this.toggleProperty('isMobile');
    }
    if (elementSubtype === 'call' && !isMobile) {
      this.toggleProperty('isMobile');
    }
  }.observes('model.element_subtype', 'model.type')

});
