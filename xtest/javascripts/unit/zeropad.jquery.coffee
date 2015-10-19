module 'zeropad',
  setup: ->
    @zeropad = $.zeropad

  test 'it should default to 2 digits', ->
    equal @zeropad("2"), "02", "Didn't equal correct value"
    equal @zeropad("16"), "16", "Didn't equal correct value"

  test 'it should allow more than 2 digits', ->
    equal @zeropad("2", 3), "002", "Didn't equal correct value"

  test 'it should work on numbers and strings', ->
    equal @zeropad(2, 3), "002", "Didn't equal correct value"
    equal @zeropad("hey", 4), "0hey", "Didn't equal correct value"
