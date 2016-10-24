HelloBar.ToggleSwitchComponent = Ember.Component.extend({

  classNames: ['toggle-switch'],
  classNameBindings: ['displayValue:is-selected'],
  attributeBindings: ['tabindex'],

  //-----------  Trigger Changes  -----------#

  init() {
    this._setDisplayValue();
    this._super();
    return this.on('change', this, this._elementValueDidChange);
  },

  click() {
    return this._elementValueDidChange();
  },

  //-----------  Persist Changes to Model  -----------#

  _elementValueDidChange() {
    this.toggleProperty('switch');
    return this._setDisplayValue();
  },

  _setDisplayValue: ( function() {
    return this.set('displayValue', this.get('inverted') ? !this.get('switch') : this.get('switch'));
  }).observes('switch')
});
