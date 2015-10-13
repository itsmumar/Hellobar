#= require modal

test 'Modal.constructor', ->
  $dom = $('<div></div>')
  modal = new Modal($dom)

  equal modal.$modal, $dom, 'sanity check'

asyncTest 'Modal.open()', ->
  expect(2) # why two??

  $dom = $('<div></div>')
  modal = new Modal($dom)

  modal.$modal.on "open", =>
    equal $dom.hasClass('show-modal'), true, 'adds the correct class when opening the modal'
    QUnit.start()

  modal.open()

test 'Modal.close()', ->
  $dom = $('<div class="show-modal"></div>')
  modal = new Modal($dom)

  modal.close()

  equal $dom.hasClass('show-modal'), false, 'removes the correct class when closing the modal'

module 'Modal interactions'

asyncTest 'Modal binds to escape keypress closes the modal', ->
  expect(1)

  $dom = $('<div class="show-modal"></div>')
  modal = new Modal($dom)

  modal.$modal.on "open", =>
    escapePress = $.Event('keyup')
    escapePress.keyCode = 27
    $(document).trigger(escapePress)

    equal $dom.hasClass('show-modal'), false, 'binds the escape key to close the modal'
    QUnit.start()

  modal.open()

asyncTest 'Modal binds to the cancel anchor to close the modal', ->
  expect(1)

  $dom = $('<div class="show-modal"><a class="cancel">DIE</a></div>')
  modal = new Modal($dom)

  modal.$modal.on "open", =>
    $dom.find('a.cancel').click()

    equal $dom.hasClass('show-modal'), false, 'binds the cancel anchor to close the modal'
    QUnit.start()

  modal.open()

asyncTest 'Modal closing based on where the user clicks', ->
  expect(2)

  $dom = $('<div class="modal-wrapper show-modal"><div class="modal-block"></div></div>')
  modal = new Modal($dom)

  modal.$modal.on "open", =>
    $dom.find('.modal-block').click()
    equal $dom.hasClass('show-modal'), true, 'keeps the modal open like a BOSS'

    $dom.click()
    equal $dom.hasClass('show-modal'), false, 'closes the modal like a FINAL LEVEL BOSS'

    QUnit.start()

  modal.open()
