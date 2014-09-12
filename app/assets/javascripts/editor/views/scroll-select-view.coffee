HelloBar.ScrollSelect = Ember.View.extend

  tagName: 'label'
  classNameBindings: ['isSelected']
 
  notSelected: Ember.computed.not('isSelected')
  isSelected: (->
    return (@get('controller.model.settings.display_when_scroll_type') == @get('type'))
  ).property('controller.model.settings.display_when_scroll_type')

  click: ->
    @set('controller.model.settings.display_when_scroll_type', @type)
