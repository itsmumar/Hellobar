import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['popup-hint'],

  visible: false,

  $clonedHintContent: null,

  onVisibleChange: (function () {
    const value = this.get('visible');
    const $element = this.$();
    if (value) {
      const rect = $element[0].getBoundingClientRect();
      this.$clonedHintContent = this.$('.js-popup-hint-content').clone(false);
      this.$clonedHintContent.css({
        display: 'block',
        left: (rect.left + 30) + 'px',
        top: (rect.top - 28) + 'px'
      }).appendTo($('#popup-container'));
    } else {
      if (this.$clonedHintContent) {
        this.$clonedHintContent.remove();
        this.$clonedHintContent = null;
      }
    }
  }).observes('visible')
});
