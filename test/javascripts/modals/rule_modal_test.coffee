#= require rule_modal

test 'RuleModal.constructor', ->
  $dom = $('<div></div>')
  modal = new RuleModal($dom)

  equal modal.$modal, $dom, 'sanity check'

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

    $($dom).find('a.cancel').click()

    equal $dom.hasClass('show-modal'), false, 'binds the cancel anchor to close the modal'

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
