#= require modal
context = describe

describe 'Modal.constructor', ->
  it 'instantiates with passed dom', ->
    $dom = $('<div></div>')
    modal = new Modal($dom)

    expect(modal.$modal).toEqual($dom)

describe 'Modal.open()', ->
  $dom = $('<div></div>')
  modal = new Modal($dom)

  beforeEach ->
    modal.open()
    jasmine.clock().tick(1)

  it 'adds the correct class when opening the modal', ->
    expect($dom.hasClass('show-modal')).toEqual(true)

describe 'Modal.close()', ->
  $dom = $('<div class="show-modal"></div>')
  modal = new Modal($dom)

  beforeEach ->
    modal.close()
    jasmine.clock().tick(501)

  it 'removes the correct class when closing the modal', ->
    expect($dom.hasClass('show-modal')).toEqual(false)

describe 'Modal interactions', ->
  context 'opened modal', ->
    $dom = $('
      <div class="modal-wrapper show-modal">
        <a class="cancel">Close Me</a>
        <div class="modal-block"></div>
      </div>')
    modal = new Modal($dom)

    beforeEach ->
      modal.open()
      jasmine.clock().tick(1)

    it 'is closed with an esc button press', ->
      escapePress = $.Event('keyup')
      escapePress.keyCode = 27
      $(document).trigger(escapePress)
      expect($dom.hasClass('show-modal')).toEqual(false)

    it 'is closed with a click on cancel link', ->
      $dom.find('a.cancel').click()
      expect($dom.hasClass('show-modal')).toEqual(false)

    it 'is not closed with a click on the model content', ->
      $dom.find('.modal-block').click()
      expect($dom.hasClass('show-modal')).toEqual(true)

    it 'is closed with a click outside of the model content', ->
      $dom.click()
      expect($dom.hasClass('show-modal')).toEqual(false)
