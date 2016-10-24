HelloBar.PopupHintComponent = Ember.Component.extend

  classNames: ['popup-hint']

  # classNameBindings: ['visible']

  visible: false

  onVisibleChange: (->
    value = @get('visible')
    $element = this.$()
    if value
      rect = $element[0].getBoundingClientRect()
      this.$('.js-popup-hint-content').css({left: (rect.left + 30) + 'px', top: (rect.top - 28) + 'px'})
      $element.addClass('visible')
    else
      $element.removeClass('visible')

  ).observes('visible')




