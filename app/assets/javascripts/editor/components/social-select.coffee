HelloBar.SocialSelectComponent = Ember.Component.extend

  tagName: 'ul'

  classNames: ['social-select']
  classNameBindings: ['isSelected']

  isSelected: Ember.computed.notEmpty('selection')


#-----------  Social Option Child Views  -----------#

HelloBar.SocialOption = Ember.View.extend

  tagName: 'li'

  classNameBindings: ['content.service', 'isSelected']

  isSelected: ( ->
    Ember.isEqual(@get('content.value'), @get('parentView.selection'))
  ).property('parentView.selection')

  click: (event) ->
    if !@get('isSelected')
      @set('parentView.selection', @get('content.value'))
    else if event.target.className == 'icon-close'
      @set('parentView.selection', null)
    false

