# module "editor colors",
#   setup: ->
#     @route = getModule("route:application")
#     visit "colors"
#   teardown: ->
#     find(".color-select.in-focus").each ->
#       $(@).removeClass('in-focus')

# #-----------  Properties  -----------#

# cssColors =
#   red:    {hex: '#FF0000', rgb: 'rgb(255, 0, 0)',   r: 255, g: 0,   b: 0}
#   blue:   {hex: '#0000FF', rgb: 'rgb(0, 0, 255)',   r: 0,   g: 0,   b: 255}
#   green:  {hex: '#00FF00', rgb: 'rgb(0, 255, 0)',   r: 0,   g: 255, b: 0}
#   orange: {hex: '#FFA500', rgb: 'rgb(255, 165, 0)', r: 255, g: 165, b: 0}

# selectors =
#   colorDropdown: '.in-focus .color-dropdown'
#   colorPreview: '.color-preview'

# #-----------  Helpers  -----------#

# colorsTab = -> find(".step-links li a[href^='#/colors']")

# fillInColors = (color) ->
#   fillIn('.in-focus .r-val', cssColors[color].r)
#   fillIn('.in-focus .g-val', cssColors[color].g)
#   fillIn('.in-focus .b-val', cssColors[color].b)

# #-----------  Tests  -----------#

# test "it should change to tab", ->
#   visit "settings" # reset
#   click(colorsTab()).andThen =>
#     equal find(".step-title").text(), "Colors", "Tab did not switch to colors"

# asyncTest "can change the background color", ->
#   expect(1)
#   click(colorsTab()).andThen =>
#     click(findLabeled("Primary Color").find(".color-select-block")).andThen =>
#       debounce (done) ->
#         fillInColors('red').andThen =>
#           bar = hbFrame().find("#hellobar_bar")
#           equal bar.css('background-color'), cssColors['red'].rgb, "New color should equal " + cssColors['red'].hex
#           done()

# asyncTest "can change the text color", ->
#   expect(1)
#   click(colorsTab()).andThen =>
#     click(findLabeled("Text").find(".color-select-block")).andThen =>
#       debounce (done) ->
#         fillInColors('blue').andThen =>
#           barText = hbFrame().find("#hb_msg_container")
#           equal barText.css('color'), cssColors['blue'].rgb, "New color should equal " + cssColors['blue'].hex
#           done()

# asyncTest "can change the button background-color", ->
#   expect(1)
#   click(colorsTab()).andThen =>
#     click(findLabeled("Button").find(".color-select-block")).andThen =>
#       debounce (done) ->
#         fillInColors('green').andThen =>
#           button = hbFrame().find(".hb-cta")
#           equal button.css('background-color'), cssColors['green'].rgb, "New color should equal " + cssColors['green'].hex
#           done()

# asyncTest "can change the button text color", ->
#   expect(1)
#   click(colorsTab()).andThen =>
#     click(findLabeled("Button Text").find(".color-select-block")).andThen =>
#       debounce (done) ->
#         fillInColors('orange').andThen =>
#           buttonText = hbFrame().find(".hb-cta")
#           equal buttonText.css('color'), cssColors['orange'].rgb, "New color should equal " + cssColors['orange'].hex
#           done()
