import Ember from 'ember';

export default Ember.Component.extend({

  isOpen: false,
  tabindex: -1,

  classNames: ['custom-select-wrapper'],
  classNameBindings: ['isOpen:is-open'],
  attributeBindings: ['tabindex'], // to make component focusable

  _setSelectedOption: ( function () {
    return this.set('currentChoice', this.get('options').findBy('key', this.get('choice')));
  }).observes('choice').on('init'),

  focusOut() {
    return this.set("isOpen", false);
  },

  click(event) {
    event.stopPropagation();
    this.toggleProperty("isOpen");
    this.$el.find('.custom-select-dropdown').toggleClass('is-visible');
  },

  actions: {
    optionSelected(option) {
      (typeof event !== 'undefined') && event.stopPropagation();
      this.sendAction('action', option);
      this.set("isOpen", false);
      this.$el.find('.custom-select-dropdown').removeClass('is-visible');
    }
  }
});


