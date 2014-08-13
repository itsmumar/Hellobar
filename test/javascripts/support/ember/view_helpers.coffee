Ember.Test.registerHelper 'clickOn', (app, text, scope) ->
  click("*:contains(#{text})", scope)

Ember.Test.registerHelper 'includes', (app, text, search, errorMessage) ->
  errorMessage ||= "Text did not include `#{search}`"
  ok text.indexOf(search) > -1, errorMessage

Ember.Test.registerHelper 'select', (app, text, scope="") ->
  selector = Ember.$.trim "#{scope} select option:contains(#{text})"
  Ember.$(selector).prop('selected', 'selected').trigger('change')

Ember.Test.registerHelper 'findLabeled', (app, labelText, scope="", errorMessage=null) ->
  errorMessage ||= "No label with text `#{labelText}`"
  selector = Ember.$.trim "#{scope} label:contains(#{labelText})"
  label = Ember.$(selector)
  if inputID = label.attr('for')
    Ember.$(inputID)
  else if (toggle = label.find('.toggle-switch')).length > 0
    toggle
  else
    bestCandidate = $(label.next()[0])
    if bestCandidate.is('input, select, textarea, .ember-view.color-select')
      bestCandidate
    else
      bestCandidate.find('input, select, textarea')

Ember.Test.registerHelper 'hbFrame', (app) ->
  find("iframe#hellobar_container").contents()
