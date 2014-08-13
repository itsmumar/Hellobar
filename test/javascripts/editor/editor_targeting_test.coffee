module "editor targeting",
  setup: ->
    @route = getModule("route:application")
    visit "targeting"

targetingTab = -> find(".step-links li a[href^='#/targeting']")

test "it should change to targeting", ->
  click(targetingTab()).andThen =>
    equal find(".step-title").text(), "Targeting", "Tab did not switch to Targeting"

test "it should select 'who sees this'", ->
  click(targetingTab()).andThen =>
    select = findLabeled('When should they see this?')
    option = $(select).find("option:contains(When a visitor is leaving)")
    $(option).prop('selected', true).trigger('change')

    found = false
    $('.step-wrapper p').each ->
      found = true if $.trim($(this).text()) is "This bar will appear when a visitor moves their mouse out of the window."

    ok found, "Text did not change"
