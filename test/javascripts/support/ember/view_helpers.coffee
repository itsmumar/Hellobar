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
  else
    bestCandidate = label.next()
    if bestCandidate.is('input, select, textarea')
      bestCandidate
    else
      bestCandidate.find('input, select, textarea')
