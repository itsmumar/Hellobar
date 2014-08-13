#= require modal
#= require modals/rule_modal

module 'RuleModal.open',
  setup: ->
    segments =    '<select class="condition-segment">'
    segments +=     '<option value="CountryCondition"></option>'
    segments +=     '<option value="DeviceCondition"></option>'
    segments +=     '<option value="DateCondition"></option>'
    segments +=     '<option value="UrlCondition"></option>'
    segments +=   '</select>'

    operands =    "<select class='condition-operand'>"
    operands +=     "<option value='is'></option>"
    operands +=     "<option value='is_not'></option>"
    operands +=     "<option value='is_before'></option>"
    operands +=     "<option value='is_after'></option>"
    operands +=     "<option value='is_between'></option>"
    operands +=     "<option value='includes'></option>"
    operands +=     "<option value='excludes'></option>"
    operands +=   "</select>"

    condition =  "<div class='condition-block'>"
    condition +=   "#{segments}"
    condition +=   "#{operands}"
    condition += "</div>"
    $modal = $("<div>#{condition}</div>").clone()
    @modal = new RuleModal($modal)
    @modal.newConditionTemplate = ->
      $modal.html()

test 'rendering the correct operand for CountryCondition', ->
  expect(1)

  @modal.$modal.find('select.condition-segment').val('CountryCondition')
  operands = @modal.open().find('select.condition-operand option').map ->
    @value

  deepEqual $.makeArray(operands), ['is', 'is_not'], 'filters the correct operands for CountryCondition'

test 'rendering the correct operand for DeviceCondition', ->
  expect(1)

  @modal.$modal.find('select.condition-segment').val('DeviceCondition')
  operands = @modal.open().find('select.condition-operand option').map ->
    @value

  deepEqual $.makeArray(operands), ['is', 'is_not'], 'filteres the correct operands for DeviceCondition'

test 'rendering the correct operand for DateCondition', ->
  expect(1)

  @modal.$modal.find('select.condition-segment').val('DateCondition')
  operands = @modal.open().find('select.condition-operand option').map ->
    @value

  deepEqual $.makeArray(operands), ['is_before', 'is_after', 'is_between'], 'filteres the correct operands for DateCondition'

test 'rendering the correct operand for UrlCondition', ->
  expect(1)

  @modal.$modal.find('select.condition-segment').val('UrlCondition')
  operands = @modal.open().find('select.condition-operand option').map ->
    @value

  deepEqual $.makeArray(operands), ['includes', 'excludes'], 'filteres the correct operands for UrlCondition'

test 'RuleModal._dateClasses(operand)', ->
  $modal = $('<div></div>')
  modal = new RuleModal($modal)

  equal modal._dateClasses('is_before'), '.end_date.value'
  equal modal._dateClasses('is_after'), '.start_date.value'
  equal modal._dateClasses('is_between'), '.start_date.value, .end_date.value'

test 'RuleModal._renderValue($condition)', (assert) ->
  dom =  '<div>'
  dom +=   '<select class="condition-segment">'
  dom +=     '<option value="CountryCondition">country</option>'
  dom +=     '<option value="DeviceCondition">device</option>'
  dom +=     '<option value="DateCondition">date</option>'
  dom +=     '<option value="UrlCondition">url</option>'
  dom +=   '</select>'
  dom +=   '<select class="condition-operand" id="rule_conditions_attributes_0_operand" name="rule[conditions_attributes][0][operand]"><option value=""></option>'
  dom +=     '<option value="is_after">is after</option>'
  dom +=     '<option value="is_before">is before</option>'
  dom +=     '<option value="is_between">is between</option>'
  dom +=     '<option value="is">is</option>'
  dom +=     '<option value="is_not">is not</option>'
  dom +=     '<option value="includes">includes</option>'
  dom +=     '<option value="excludes">excludes</option>'
  dom +=   '</select>'
  dom +=   '<div class="choice-wrapper date-choice"><input class="start_date value">'
  dom +=   '<input class="end_date value"></div>'
  dom +=   '<div class="choice-wrapper url-choice"><input class="url value"></div>'
  dom +=   '<div class="choice-wrapper country-choice"><select class="select country value"></select></div>'
  dom +=   '<div class="choice-wrapper device-choice"><select class="select device value"></select></div>'
  dom +=   '<form></form>'
  dom += '</div>'

  $modal = $("<div><form></form></div>")
  modal = new RuleModal($modal)
  $condition = $(dom)

  $condition.find('select.condition-segment').val('CountryCondition')
  modal._renderValue($condition)
  equal $condition.find('.country').prop('disabled'), false, 'it enables the country value when the segment is CountryCondition'
  equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is CountryCondition'
  equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is CountryCondition'
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is CountryCondition'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is CountryCondition'

  $condition.find('select.condition-segment').val('DeviceCondition')
  modal._renderValue($condition)
  equal $condition.find('.country').prop('disabled'), true, 'it disables the country value when the segment is DeviceCondition'
  equal $condition.find('.device').prop('disabled'), false, 'it enables the device value when the segment is DeviceCondition'
  equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DeviceCondition'
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is DeviceCondition'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is DeviceCondition'

  $condition.find('select.condition-segment').val('UrlCondition')
  modal._renderValue($condition)
  equal $condition.find('.country').prop('disabled'), true, 'it disables the country value when the segment is UrlCondition'
  equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is UrlCondition'
  equal $condition.find('.url').prop('disabled'), false, 'it enables the url value when the segment is UrlCondition'
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is UrlCondition'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is UrlCondition'

  $condition.find('select.condition-segment').val('DateCondition')
  $condition.find('select.condition-operand').val('is_before')
  modal._renderValue($condition)
  equal $condition.find('.country').prop('disabled'), true, 'it disables the country value when the segment is DateCondition'
  equal $condition.find('.device').prop('disabled'), true, 'it disables the device value when the segment is DateCondition'
  equal $condition.find('.url').prop('disabled'), true, 'it disables the url value when the segment is DateCondition'

  $condition.find('select.condition-operand').val('is_before')
  modal._renderValue($condition)
  equal $condition.find('.start_date').prop('disabled'), true, 'it disables the start_date value when the segment is DateCondition and the operand is is_before'
  equal $condition.find('.end_date').prop('disabled'), false, 'it enables the end_date value when the segment is DateCondition and the operand is is_before'

  $condition.find('select.condition-operand').val('is_after')
  modal._renderValue($condition)
  equal $condition.find('.start_date').prop('disabled'), false, 'it enables the start_date value when the segment is DateCondition and the operand is is_after'
  equal $condition.find('.end_date').prop('disabled'), true, 'it disables the end_date value when the segment is DateCondition and the operand is is_after'

  $condition.find('select.condition-operand').val('is_between')
  modal._renderValue($condition)
  equal $condition.find('.start_date').prop('disabled'), false, 'it enables the start_date value when the segment is DateCondition and the operand is is_between'
  equal $condition.find('.end_date').prop('disabled'), false, 'it enables the end_date value when the segment is DateCondition and the operand is is_between'

module 'RuleModal interactions'

asyncTest 'RuleModal closes the modal on a successful form submission event', (assert) ->
  $dom = $('<div class="modal-wrapper show-modal"><form action="url" method="post"></form></div>')
  $form = $dom.find('form')
  modal = new RuleModal($dom)

  $.mockjax
    url: $form[0].action
    type: 'post'
    status: 200
    responseText: '{}'

  $form.submit()

  debounce (done) ->
    equal $($dom).hasClass('show-modal'), false, 'closes the modal after form submission'
    done()

module 'RuleModal filtering out operands'

test '_validOperands()', ->
  $dom = $('<div></div>')
  modal = new RuleModal($dom)

  deepEqual modal._validOperands('CountryCondition'), ['is', 'is_not'], 'has a valid value for country'
  deepEqual modal._validOperands('DeviceCondition'), ['is', 'is_not'], 'has a valid value for device'
  deepEqual modal._validOperands('DateCondition'), ['is_before', 'is_after', 'is_between'], 'has a valid value for date'
  deepEqual modal._validOperands('UrlCondition'), ['includes', 'excludes'], 'has a valid value for url'

test '_filteredOperands(segment)', ->
  $dom = $('<div></div>')
  modal = new RuleModal($dom)
  isOption = '<option value="is"></option>'
  isNotOption = '<option value="is_not"></option>'

  modal.newConditionTemplate = ->
    template =  "<div>"
    template +=   "<select class='condition-operand'>#{isOption}</select>"
    template += "</div>"

  equal modal.filteredOperands('CountryCondition').val(), $(isOption).val()

  modal.newConditionTemplate = ->
    template =  "<div>"
    template +=   "<select class='condition-operand'>#{isOption}#{isNotOption}</select>"
    template += "</div>"

  expectedValue = modal.filteredOperands("CountryCondition").map -> @value

  deepEqual $.makeArray(expectedValue), ["is", "is_not"], 'it pulls all option elements that match'
