module "editor colors",
  setup: ->
    @route = getModule("route:application")
    visit "colors"
  teardown: ->
    find(".color-select.in-focus").each -> $(this).removeClass('in-focus')

colorsTab = -> find(".step-links li a[href^='#/colors']")

selectors =
  colorDropdown: '.in-focus .color-dropdown'
  colorPreview: '.color-preview'

test "it should change to tab", ->
  visit "settings" # reset
  click(colorsTab()).andThen =>
    equal find(".step-title").text(), "Colors", "Tab did not switch to colors"

asyncTest "can change the background color", ->
  expect(1)
  click(colorsTab()).andThen =>
    click(findLabeled("Background").find(".color-select-block")).andThen =>
      debounce (done) ->
        colorWell = find("#{selectors.colorDropdown} #{selectors.colorPreview}[style='background-color:#ffffff']")
        click(colorWell).andThen =>
          bar = hbFrame().find("#hellobar")
          equal bar.css('background-color'), 'rgb(255, 255, 255)', "New color should equal #fff"
          done()

asyncTest "can change the text color", ->
  expect(1)
  click(colorsTab()).andThen =>
    click(findLabeled("Text").find(".color-select-block")).andThen =>
      debounce (done) ->
        colorWell = find("#{selectors.colorDropdown} #{selectors.colorPreview}[style='background-color:#ff11dd']")
        click(colorWell).andThen =>
          barText = hbFrame().find("#hb_msg_container span")
          equal barText.css('color'), 'rgb(255, 17, 221)', "New color should equal #ff11dd"
          done()

asyncTest "can change the button background-color", ->
  expect(1)
  click(colorsTab()).andThen =>
    click(findLabeled("Button", "").find(".color-select-block")).andThen =>
      debounce (done) ->
        colorWell = find("#{selectors.colorDropdown} #{selectors.colorPreview}[style='background-color:#def1ff']")
        click(colorWell).andThen =>
          button = hbFrame().find(".hb-button")
          equal button.css('background-color'), 'rgb(222, 241, 255)', "New color should equal #DEF1FF"
          done()

asyncTest "can change the button text color", ->
  expect(1)
  click(colorsTab()).andThen =>
    click(findLabeled("Button Text").find(".color-select-block")).andThen =>
      debounce (done) ->
        colorWell = find("#{selectors.colorDropdown} #{selectors.colorPreview}[style='background-color:#4f4f4f']")
        click(colorWell).andThen =>
          buttonText = hbFrame().find(".hb-button")
          equal buttonText.css('color'), 'rgb(79, 79, 79)', "New color should equal #4F4F4F"
          done()
