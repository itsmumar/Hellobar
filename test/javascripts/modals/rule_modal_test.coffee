#= require modal
#= require modals/rule_modal

test 'RuleModal._valueClass(segment, operand)', ->
  $modal = $('<div></div>')
  modal = new RuleModal($modal)

  equal modal._valueClass('DateCondition', 'is_before'), '.end_date.value'
  equal modal._valueClass('DateCondition', 'is_after'), '.start_date.value'
  equal modal._valueClass('DateCondition', 'is_between'), '.start_date.value, .end_date.value'
  equal modal._valueClass('UrlCondition', 'anything'), '.url.value'

test 'RuleModal._renderValue($condition)', (assert) ->
  $modal = $('<div class="conditions"><div class="row condition"><div class="col-md-10"><div class="form-group select optional rule_conditions_segment"><div><select class="select optional form-control" id="rule_conditions_attributes_0_segment" name="rule[conditions_attributes][0][segment]"><option value=""></option>
<option value="CountryCondition">country</option>
<option value="DeviceCondition">device</option>
<option selected="selected" value="DateCondition">date</option>
<option value="UrlCondition">url</option></select></div></div><div class="form-group select optional rule_conditions_operand"><div><select class="select optional form-control" id="rule_conditions_attributes_0_operand" name="rule[conditions_attributes][0][operand]"><option value=""></option>
<option selected="selected" value="is_after">is after</option>
<option value="is_before">is before</option>
<option value="is_between">is between</option>
<option value="is">is</option>
<option value="is_not">is not</option>
<option value="includes">includes</option>
<option value="excludes">excludes</option></select></div></div><input class="start_date value" disabled="disabled" id="rule_conditions_attributes_0_value" name="rule[conditions_attributes][0][value][start_date]" type="date" value="2014-07-16"><input class="end_date value" disabled="disabled" id="rule_conditions_attributes_0_value" name="rule[conditions_attributes][0][value][end_date]" type="date"><input class="url value" disabled="disabled" id="rule_conditions_attributes_0_value" name="rule[conditions_attributes][0][value]" type="text"><div class="form-group hidden rule_conditions__destroy"><div><input class="hidden form-control" id="rule_conditions_attributes_0__destroy" name="rule[conditions_attributes][0][_destroy]" type="hidden" value="false"></div></div></div><div class="col-md-2 actions"><a class="remove" href="#">-</a><a class="add" href="#">+</a></div></div><input id="rule_conditions_attributes_0_id" name="rule[conditions_attributes][0][id]" type="hidden" value="1"></div>')
  modal = new RuleModal($modal)
  modal.filteredOperands = -> [$('<option value="is_after"></option>')[0]]
  modal.open()

  equal $modal.find('input[name*=end_date]').css('display'), "none", "end_date must be hidden"
  equal $modal.find('input[name*=start_date]').val(), "2014-07-16", "Date was not rendered, was #{$modal.find('input[name*=start_date]').val()}"
  equal $modal.find('select[name*=operand]').val(), "is_after", "Is after must be rendered"

module 'RuleModal interactions'

asyncTest 'RuleModal closes the modal on a successful form submission event', (assert) ->
  expect(1)

  $dom = $('<div class="modal-wrapper show-modal"><form action="url" method="post"></form></div>')
  $form = $dom.find('form')
  modal = new RuleModal($dom)

  $.mockjax
    url: $form[0].action
    type: 'post'
    status: 200
    responseText: '{}'

  $form.submit()

  setTimeout (->
    equal $($dom).hasClass('show-modal'), false, 'closes the modal after form submission'
    start()
  ), 500

test 'removing a new condition', ->

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
    template =  "<div class='placeholder'>"
    template +=   "<div id='operand'>#{isOption}</div>"
    template += "</div>"

  equal modal.filteredOperands('CountryCondition').val(), $(isOption).val()

  modal.newConditionTemplate = ->
    template =  "<div class='placeholder'>"
    template +=   "<div id='operand'>#{isOption}#{isNotOption}</div>"
    template += "</div>"

  expectedValue = modal.filteredOperands("CountryCondition").map -> @value

  deepEqual $.makeArray(expectedValue), ["is", "is_not"], 'it pulls all option elements that match'
