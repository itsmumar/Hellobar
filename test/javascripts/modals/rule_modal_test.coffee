#= require modal
#= require modals/rule_modal

test 'RuleModal constructor properly sets is_between to true for conditions that have a "between" operand', ->
  expect(2)

  options =
    ruleData:
      conditions: [
        {
          segment: 'DateCondition'
          operand: 'between'
        },
        {
          segment: 'DateCondition'
          operand: 'after'
        }
      ]

  modal = new RuleModal(options)
  modal.open()
  betweenCondition = modal.ruleData.conditions[0]
  afterCondition = modal.ruleData.conditions[1]

  equal betweenCondition.is_between, true, 'properly sets conditions with an "in between operand"'
  equal afterCondition.is_between, undefined, 'does not set between to anything when operand is not in between'

asyncTest 'RuleModal._renderValue($condition)', (assert) ->
  expect(6)

  options =
    ruleData:
      name: 'Rule name'
      conditions: [
        segment: 'DeviceCondition'
      ]

  modal = new RuleModal(options)

  modal.$modal.on "open", =>
    $condition = modal.$modal.find('.condition-block:not(".no-condition-message"):first')

    modal._renderValue($condition, { segment: 'DeviceCondition' })
    $condition.find('select.condition-segment').val('DeviceCondition').trigger('change')
    equal $condition.find('.device').prop('disabled'), false, 'it enables the device value when the segment is DeviceCondition'
    equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DeviceCondition'

    modal._renderValue($condition, { segment: 'UrlCondition' })
    $condition.find('select.condition-segment').val('UrlCondition').trigger('change')
    equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is UrlCondition'
    equal $condition.find('.url').prop('disabled'), false, 'it enables the url value when the segment is UrlCondition'

    modal._renderValue($condition, { segment: 'DateCondition', operand: 'before' })
    $condition.find('select.condition-segment').val('DateCondition').trigger('change')
    $condition.find('select.condition-operand').val('before').trigger('change')
    equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is DateCondition'
    equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DateCondition'

    QUnit.start()

  modal.open()

module 'RuleModal interactions',
  setup: ->
    @modal = new RuleModal(
      ruleData:
        name: 'Name'
        siteID: 1
    )

    $(document).ajaxComplete =>
      @modal.$modal.trigger('ajax-complete')

  teardown: ->
    @modal.$modal.unbind('ajax-complete')
    @modal.close()

asyncTest 'RuleModal closes the modal on a successful form submission event', (assert) ->
  expect(1)

  $('.rules-modal').remove()

  options =
    ruleData:
      name: 'Name'
      siteID: 1

  modal = new RuleModal(options)

  modal.$modal.on "open", =>
    modal.$modal.find('form').submit()
    equal $('.rules-modal .show-modal').length, 0, 'removes the modal from the DOM after form submission'
    start()

  modal.open()

module 'RuleModal filtering out operands'

test '_validOperands()', ->
  options =
    ruleData:
      name: 'Rule name'
      conditions: [{}]
  modal = new RuleModal(options)

  deepEqual modal._validOperands('DeviceCondition'), ['is', 'is_not'], 'has a valid value for device'
  deepEqual modal._validOperands('DateCondition'), ['is', 'is_not', 'before', 'after', 'between'], 'has a valid value for date'
  deepEqual modal._validOperands('UrlCondition'), ['is', 'is_not', 'includes', 'does_not_include'], 'has a valid value for url'
