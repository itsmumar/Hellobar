module "editor colors",
  setup: ->
    @route = getModule("route:application")
    visit "colors"

colorsTab = -> find(".step-links li a[href^='#/colors']")

test "it should change to tab", ->
  visit "settings" # reset
  click(colorsTab()).andThen =>
    equal find(".step-title").text(), "Colors", "Tab did not switch to colors"

asyncTest "can change the background color", ->
  expect(1)
  click(colorsTab()).andThen =>
    click(findLabeled("Background").find(".color-select-block")).andThen =>
      setTimeout ( ->
        colorWell = find(".color-dropdown .color-preview[style='background-color:#ffffff']")
        click(colorWell).andThen =>
          bar = hbFrame().find("#hellobar")
          equal bar.css('background-color'), 'rgb(255, 255, 255)', "New color should equal #fff"
          QUnit.start()
      ), 500
