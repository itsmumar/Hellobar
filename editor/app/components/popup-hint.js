import Ember from 'ember';

export default Ember.Component.extend({

  classNames: ['popup-hint'],

  // classNameBindings: ['visible']

  visible: false,

  onVisibleChange: (function () {
    let value = this.get('visible');
    let $element = this.$();
    if (value) {
      let rect = $element[0].getBoundingClientRect();
      this.$('.js-popup-hint-content').css({left: (rect.left + 30) + 'px', top: (rect.top - 28) + 'px'});
      return $element.addClass('visible');
    } else {
      return $element.removeClass('visible');
    }

  }).observes('visible')
});




