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
      console.log 'selected'
      @set('parentView.selection', @get('content.value'))
    else if event.target.className == 'icon-close'
      console.log 'deselected'
      @set('parentView.selection', null)
    false

