import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['toggle-switch'],
  classNameBindings: ['displayValue:is-selected'],
  attributeBindings: ['tabindex'],

  //-----------  Trigger Changes  -----------#

  init() {
    this._setDisplayValue();
    this._super();
    this.on('change', this, this._elementValueDidChange);
  },

  click() {
    this._elementValueDidChange();
  },

  //-----------  Persist Changes to Model  -----------#

  _elementValueDidChange() {
    this.toggleProperty('switch');
    this._setDisplayValue();
  },

  _setDisplayValue: function () {
    this.set('displayValue', this.get('inverted') ? !this.get('switch') : this.get('switch'));
  }.observes('switch')
});
