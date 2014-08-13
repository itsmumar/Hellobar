test 'it should launch ember immediately', ->
  equal find(".editor-wrapper.ember-view").length, 1, "Ember view should be present"
  equal find("ul.step-links").length, 1, "Side links were not present"
  equal find("ul.action-links .icon-close").length, 1, "Logout link (x) wasn't present"
