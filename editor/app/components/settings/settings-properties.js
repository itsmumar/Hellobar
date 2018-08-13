import _ from 'lodash/lodash';
import Ember from 'ember';

import HasTriggerOptions from '../../mixins/has-trigger-options-mixin';
import ElementSubtype from '../../mixins/element-subtype-mixin';

export default Ember.Component.extend(HasTriggerOptions, ElementSubtype, {
  /**
   * @property {object} Application model
   */
  model: null,

  isBar: Ember.computed.equal('model.type', 'Bar'),
  isAlert: Ember.computed.equal('model.type', 'Alert'),
  isNotAlert: Ember.computed.not('isAlert'),

  soundOptions: [
    {value: 'bell', label: 'Bell'},
    {value: 'none', label: 'No sound'}
  ],

  canWiggle: function () {
    const goal = this.get('model.element_subtype');
    const type = this.get('model.type');
    return type === 'Bar' && (goal === 'traffic' || goal  === 'email');
  }.property('model.element_subtype', 'model.type'),

  canHideElement: function () {
    const type = this.get('model.type');
    return type === 'Bar' || type === 'Slider';
  }.property('model.type'),

  pushesText: function () {
    if (this.get('model.placement') === 'bar-top') {
      return 'Pushes page down';
    } else {
      return 'Pushes page up';
    }
  }.property('model.placement'),

  elementTypeName: function () {
    return this.get('model.type').toLowerCase();
  }.property('model.type'),

  selectedSoundOption: (function () {
    const sound = this.get('model.sound');
    const options = this.get('soundOptions');
    const selectedOption = _.find(options, (option) => option.value === sound);
    if (selectedOption) {
      return selectedOption;
    } else {
      const defaultOption = options[0];
      Ember.run.next(() => this.set('model.sound', defaultOption.value));
      return defaultOption;
    }
  }).property('model.sound'),

  actions: {
    selectSound(soundOption) {
      this.set('model.sound', soundOption.value);
    }
  }
});
