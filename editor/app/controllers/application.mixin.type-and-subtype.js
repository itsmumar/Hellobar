import Ember from 'ember';

export default Ember.Mixin.create({

  isTopBarStyle: function() {
    return this.get('model.type') === 'Bar';
  }.property('model.type'),

  isNotTopBarStyle: function() {
    return this.get('model.type') !== 'Bar';
  }.property('model.type'),

  _checkMobileProperty() {
    const elementType = this.get('model.type');
    const currentTheme = this.get('currentTheme');
    const elementSubtype = this.get('model.element_subtype');
    const isMobile = this.get('isMobile');
    if (elementType !== 'Bar' && currentTheme.type === 'generic' && elementSubtype !== 'call' && isMobile) {
      this.toggleProperty('isMobile');
    }
    if (elementSubtype === 'call' && !isMobile) {
      this.toggleProperty('isMobile');
    }
  },

  previousElementType: null,

  onElementTypeChanged: function () {
    const elementType = this.get('model.type');
    const currentTheme = this.get('currentTheme');
    const previousElementType = this.get('previousElementType');
    if (elementType && previousElementType && elementType !== previousElementType) {
      if (currentTheme.type === 'template') {
        this.set('model.theme_id', this.get('theming').defaultGenericTheme().id);
      }
    }
    this.set('previousElementType', elementType);
    this._checkMobileProperty();
  }.observes('model.type'),


  onElementSubtypeChanged: function() {
    this._checkMobileProperty();
    const elementSubtype = this.get('model.element_subtype');
    if (elementSubtype === 'call') {
      this.set('model.type', 'Bar');
    }
  }.observes('model.element_subtype'),

  isCallType: Ember.computed.equal('model.element_subtype', 'call'),

  shouldShowMobileDesktopSwitch: function() {
    return this.get('isTopBarStyle') && !this.get('isCallType');
  }.property('isTopBarStyle', 'isCallType')

});
