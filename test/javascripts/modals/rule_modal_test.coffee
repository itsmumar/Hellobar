#= require rule_modal

test 'RuleModal.constructor', ->
  $dom = $('<div></div>')
  modal = new RuleModal($dom)

  equal modal.$modal, $dom, 'sanity check'

test 'RuleModal.open()', ->
  $dom = $('<div></div>')
  modal = new RuleModal($dom)

  modal.open()

  equal $dom.hasClass('show-modal'), true, 'adds the correct class when opening the modal'

test 'RuleModal.close()', ->
  $dom = $('<div class="show-modal"></div>')
  modal = new RuleModal($dom)

  modal.close()

  equal $dom.hasClass('show-modal'), false, 'removes the correct class when closing the modal'

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
  modal.open()

  equal $modal.find('input[name*=end_date]').css('display'), "none", "end_date must be hidden"
  equal $modal.find('input[name*=start_date]').val(), "2014-07-16", "Date was not rendered, was #{$modal.find('input[name*=start_date]').val()}"
  equal $modal.find('select[name*=operand]').val(), "is_after", "Is after must be rendered"

test 'RuleModal interactions', ->
  test 'RuleModal binds to escape keypress closes the modal', ->
    $dom = $('<div class="show-modal"></div>')
    modal = new RuleModal($dom)

    escapePress = $.Event('keyup')
    escapePress.keyCode = 27
    $(document).trigger(escapePress)

    equal $dom.hasClass('show-modal'), false, 'binds the escape key to close the modal'

  test 'RuleModal binds to the cancel anchor to close the modal', ->
    $dom = $('<div class="show-modal"><a class="cancel">DIE</a></div>')
    modal = new RuleModal($dom)

    $dom.find('a.cancel').click()

    equal $dom.hasClass('show-modal'), false, 'binds the cancel anchor to close the modal'

  test 'RuleModal closing based on where the user clicks', ->
    $dom = $('<div class="modal-wrapper show-modal"><div class="modal-block"></div></div>')
    modal = new RuleModal($dom)

    $dom.find('.modal-block').click()
    equal $dom.hasClass('show-modal'), true, 'keeps the modal open like a BOSS'

    $dom.click()
    equal $dom.hasClass('show-modal'), false, 'closes the modal like a FINAL LEVEL BOSS'

  asyncTest 'RuleModal closes the modal on a successful form submission event', (assert) ->
    expect(2)

    $dom = $('<div class="modal-wrapper show-modal"><form action="url" method="post"></form></div>')
    $form = $dom.find('form')
    modal = new RuleModal($dom)

    $.mockjax(
      url: $form[0].action
      type: 'post'
      status: 200
      responseText: '{}'
    )

    $form.submit()

    setTimeout (->
      assert.equal $($dom).hasClass('show-modal'), false, 'closes the modal after form submission'
      QUnit.start()
    ), 500
