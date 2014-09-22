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
  betweenCondition = modal.ruleData.conditions[0]
  afterCondition = modal.ruleData.conditions[1]

  equal betweenCondition.is_between, true, 'properly sets conditions with an "in between operand"'
  equal afterCondition.is_between, undefined, 'does not set between to anything when operand is not in between'


test 'RuleModal._dateClasses(operand)', ->
  expect(3)

  options =
    ruleData: 'Name'
  modal = new RuleModal(options)

  equal modal._dateClasses('before'), '.end_date.value'
  equal modal._dateClasses('after'), '.start_date.value'
  equal modal._dateClasses('between'), '.start_date.value, .end_date.value'

test 'RuleModal._renderValue($condition)', (assert) ->
  options =
    ruleData:
      name: 'Rule name'
      conditions: [
        segment: 'DeviceCondition'
      ]

  modal = new RuleModal(options)
  $modal = modal.open()
  $condition = $modal.find('.condition-block:not(".no-condition-message"):first')

  modal._renderValue($condition, { segment: 'DeviceCondition' })
  $condition.find('select.condition-segment').val('DeviceCondition').trigger('change')
  equal $condition.find('.device').prop('disabled'), false, 'it enables the device value when the segment is DeviceCondition'
  equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DeviceCondition'
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is DeviceCondition'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is DeviceCondition'

  modal._renderValue($condition, { segment: 'UrlCondition' })
  $condition.find('select.condition-segment').val('UrlCondition').trigger('change')
  equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is UrlCondition'
  equal $condition.find('.url').prop('disabled'), false, 'it enables the url value when the segment is UrlCondition'
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is UrlCondition'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is UrlCondition'

  modal._renderValue($condition, { segment: 'DateCondition' })
  $condition.find('select.condition-segment').val('DateCondition').trigger('change')
  $condition.find('select.condition-operand').val('before').trigger('change')
  equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is DateCondition'
  equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DateCondition'

  modal._renderValue($condition, { segment: 'DateCondition' })
  $condition.find('select.condition-operand').val('before').trigger('change')
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is DateCondition and the operand is before'
  equal $condition.find('.end_date').prop('disabled'), false, 'it enables the end_date value when the segment is DateCondition and the operand is before'

  modal._renderValue($condition, { segment: 'DateCondition' })
  $condition.find('select.condition-operand').val('after').trigger('change')
  equal $condition.find('.start_date').prop('disabled'), false, 'it enables the start_date value when the segment is DateCondition and the operand is after'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is DateCondition and the operand is after'

  modal._renderValue($condition, { segment: 'DateCondition' })
  $condition.find('select.condition-operand').val('between').trigger('change')
  equal $condition.find('.start_date').prop('disabled'), false, 'it enables the start_date value when the segment is DateCondition and the operand is between'
  equal $condition.find('.end_date').prop('disabled'), false, 'it enables the end_date value when the segment is DateCondition and the operand is between'

module 'RuleModal interactions',
  setup: ->
    @modal = new RuleModal(
      ruleData:
        name: 'Name'
        siteId: 1
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
      siteId: 1
  modal = new RuleModal(options)
  $modal = modal.open()

  $modal.find('form').submit()

  @modal.$modal.on "ajax-complete", =>
    equal $('.rules-modal .show-modal').length, 0, 'removes the modal from the DOM after form submission'
    start()

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
