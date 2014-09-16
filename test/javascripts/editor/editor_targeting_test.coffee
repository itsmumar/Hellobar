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

test 'it should be able to create a new rule', ->
  $('.show-modal').remove()
  click('a.edit-rule')

  andThen ->
    $modal = $('.modal-wrapper.show-modal.rules-modal')
    equal $modal.find('h5').text(), 'New Rule', 'we are in the new rule modal'
    equal $modal.find('select[name="rule[match]"]').val(), 'all', 'match is set to all by default'
    equal $modal.find('input[name="rule[name]"]').val(), 'Other...', 'name is other by default'
    equal $modal.find('.condition-block:not(".no-condition-message")').length, 0, 'there should be no conditions'

    $modal.find('input[name="rule[priority]"]').val('100')
    $modal.find('select[name="rule[match]"]').val('any')
    $modal.find('input[name="rule[name]"]').val('super duper')

    # create conditions
    addCondition = $modal.find('.condition-add:first')
    addCondition.click()
    equal $modal.find('.condition-block:not(".no-condition-message")').length, 1, 'builds a new condition'

    equal $modal.find('.device.value:visible').length, 1, 'device is visible by default'

    $modal.find('.condition-segment').val('UrlCondition').trigger('change')
    equal $modal.find('.device.value:visible').length, 0, 'device is hidden'
    equal $modal.find('.url.value:visible').length, 1, 'url is shown when selected'

    $modal.remove()
