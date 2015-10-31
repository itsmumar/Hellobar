module "editor text and content",
  setup: ->
    @route = getModule("route:application")
    visit "text"

textTab = -> find(".step-links li a[href^='#/text']")

test "can change the bar text", ->
  click(textTab()).andThen =>
    fillIn(findLabeled("Headline"), "My test's bar text").then =>
      equal @route.controller.get("model.headline"), "My test's bar text", "Text wasn't equal"

test "can change the link text", ->
  click(textTab()).andThen =>
    fillIn(findLabeled("Link text"), "Go there now").then =>
      message = hbFrame().find(".hb-button")
      equal @route.controller.get("model.link_text"), "Go there now", "Text wasn't equal"

test "can change the font-family", ->
  click(textTab()).andThen =>
    select = findLabeled("Font family")
    option = $(select).find('option[value^="Georgia"]')[0]
    $(option).prop('selected', true).trigger('change')
    equal @route.controller.get("model.font"), "Georgia,serif", "Font did not change"