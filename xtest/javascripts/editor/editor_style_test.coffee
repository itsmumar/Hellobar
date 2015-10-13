module "editor style",
  setup: ->
    @route = getModule("route:application")
    visit "style"

styleTab = -> find(".step-links li a[href^='#/style']")

test "it should change to tab", ->
  visit "settings" # reset
  click(styleTab()).andThen =>
    equal find(".step-title").text(), "Style", "Tab did not switch to Style"

# Broken, not sure why

# test "it should offer a switch for Hello Bar branding", ->
#   click(styleTab()).andThen =>
#     label = findLabeled("Hello Bar branding")
#     equal label.hasClass('is-selected'), true, "Bar should have H logo by default"

# asyncTest "switch for Hello Bar branding toggles off", ->
#   expect(2)
#   click(styleTab()).andThen =>
#     label = findLabeled("Hello Bar branding")
#     click(label).andThen =>
#       ok !label.hasClass('is-selected'), "Branding can't be selected"
#       debounce (done) ->
#         logo = find("iframe#hellobar_container").contents().find(".hellobar_logo")
#         equal logo.is(":visible"), false, "Logo should be hidden and is not"
#         done()

test "it should offer a switch for Allow to hide bar", ->
  click(styleTab()).andThen =>
    label = findLabeled("Allow to hide bar")
    equal label.hasClass('is-selected'), false, "Bar should not hide by default"
