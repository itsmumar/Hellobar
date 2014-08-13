module "editor text and content",
  setup: ->
    @route = getModule("route:application")
    visit "text"

textTab = -> find(".step-links li a[href^='#/text']")

test "can change the bar text", ->
  click(textTab()).andThen =>
  fillIn(findLabeled("Bar text"), "My test's bar text").then ->
    message = hbFrame().find("#hb_msg_container span")
    equal $.trim(message.text()), "My test's bar text", "Text wasn't equal"

test "can change the link text", ->
  click(textTab()).andThen =>
  fillIn(findLabeled("Link text"), "Go there now").then ->
    message = hbFrame().find(".hb-button")
    equal $.trim(message.text()), "Go there now", "Text wasn't equal"

asyncTest "can change the font-family", ->
  expect(2)
  click(textTab()).andThen =>
    select = findLabeled("Font family")
    option = $(select).find('option[value^="Georgia"]')[0]
    $(option).prop('selected', true).trigger('change')
    debounce (done) ->
      equal hbFrame().find(".hb-button").css('font-family'), "Georgia, serif", "Button font did not change"
      equal hbFrame().find("#hb_msg_container span").css('font-family'), "Georgia, serif", "Message font did not change"
      done()
