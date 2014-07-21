#= require modal

test 'Modal.constructor', ->
  $dom = $('<div></div>')
  modal = new Modal($dom)

  equal modal.$modal, $dom, 'sanity check'

test 'Modal.open()', ->
  $dom = $('<div></div>')
  modal = new Modal($dom)

  modal.open()

  equal $dom.hasClass('show-modal'), true, 'adds the correct class when opening the modal'

test 'Modal.close()', ->
  $dom = $('<div class="show-modal"></div>')
  modal = new Modal($dom)

  modal.close()

  equal $dom.hasClass('show-modal'), false, 'removes the correct class when closing the modal'

module 'Modal interactions'

test 'Modal binds to escape keypress closes the modal', ->
  $dom = $('<div class="show-modal"></div>')
  modal = new Modal($dom)

  escapePress = $.Event('keyup')
  escapePress.keyCode = 27
  $(document).trigger(escapePress)

  equal $dom.hasClass('show-modal'), false, 'binds the escape key to close the modal'

test 'Modal binds to the cancel anchor to close the modal', ->
  $dom = $('<div class="show-modal"><a class="cancel">DIE</a></div>')
  modal = new Modal($dom)

  $dom.find('a.cancel').click()

  equal $dom.hasClass('show-modal'), false, 'binds the cancel anchor to close the modal'

test 'Modal closing based on where the user clicks', ->
  $dom = $('<div class="modal-wrapper show-modal"><div class="modal-block"></div></div>')
  modal = new Modal($dom)

  $dom.find('.modal-block').click()
  equal $dom.hasClass('show-modal'), true, 'keeps the modal open like a BOSS'

  $dom.click()
  equal $dom.hasClass('show-modal'), false, 'closes the modal like a FINAL LEVEL BOSS'
