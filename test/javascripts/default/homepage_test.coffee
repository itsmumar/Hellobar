test 'it should not launch ember immediately', ->
  visit("/").andThen ->
    equal find(".ember-view").length, 0
