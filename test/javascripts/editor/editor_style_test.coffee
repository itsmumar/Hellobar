module "editor style",
  setup: ->
    @route = getModule("route:application")
    visit "style"

styleTab = -> find(".step-links li a[href^='#/style']")

test "it should change to tab", ->
  visit "settings" # reset
  click(styleTab()).andThen =>
    equal find(".step-title").text(), "Bar", "Tab did not switch to bar"

test "it should offer a switch for Hello Bar branding", ->
  click(styleTab()).andThen =>
    label = findLabeled("Hello Bar branding")
    equal label.hasClass('is-selected'), true, "Bar should have H logo by default"

asyncTest "switch for Hello Bar branding toggles off", ->
  expect(1)
  click(styleTab()).andThen =>
    click(findLabeled("Hello Bar branding")).andThen =>
      setTimeout ( ->
        logo = find("iframe#hellobar_container").contents().find(".hellobar_logo")
        equal logo.is(":visible"), false, "Logo should be hidden and is not"
        QUnit.start()
      ), 2000


test "it should offer a switch for Allow to hide bar", ->
  click(styleTab()).andThen =>
    label = findLabeled("Allow to hide bar")
    equal label.hasClass('is-selected'), false, "Bar should not hide by default"
    