#= require rule_modal

test 'RuleModal.constructor', ->
  $dom = $('<div></div>')
  modal = new RuleModal($dom)

  equal modal.$modal, $dom, 'sanity check'

test 'RuleModal.open()', ->
  $dom = $('<div"></div>')
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
