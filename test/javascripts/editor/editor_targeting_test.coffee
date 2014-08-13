module "editor targeting",
  setup: ->
    @route = getModule("route:application")
    visit "targeting"
  teardown: ->
    visit "settings"

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

test 'it should be able to create a new rule', ->
  click('a.edit-rule')

  andThen ->
    $modal = $('.modal-wrapper.show-modal')
    equal $modal.find('h5').text(), 'New Rule', 'we are in the new rule  modal'
    equal $modal.find('input[name="rule[priority]"]').val(), '', 'priority is not set by default'
    equal $modal.find('select[name="rule[match]"]').val(), 'all', 'match is set to all by default'
    equal $modal.find('input[name="rule[name]"]').val(), '', 'name is blank by default'
    equal $modal.find('.condition-block:not(".no-condition-message")').length, 0, 'there should be no conditions'

    $modal.find('input[name="rule[priority]"]').val('100')
    $modal.find('select[name="rule[match]"]').val('any')
    $modal.find('input[name="rule[name]"]').val('super duper')

    # create conditions
    addCondition = $modal.find('.condition-add:first')
    addCondition.click()
    equal $modal.find('.condition-block:not(".no-condition-message")').length, 1, 'builds a new condition'
    equal $modal.find('.country-choice:visible').length, 1, 'makes country condition visible by default'

    equal $modal.find('.device.value:visible').length, 0, 'device is hidden by default'
    $modal.find('.condition-segment').val('DeviceCondition').trigger('change')
    equal $modal.find('.device.value:visible').length, 1, 'shows device once selected'

    $modal.find('.condition-segment').val('UrlCondition').trigger('change')
    equal $modal.find('.device.value:visible').length, 0, 'device is hidden'
    equal $modal.find('.url.value:visible').length, 1, 'url is shown when selected'

    $modal.remove()
