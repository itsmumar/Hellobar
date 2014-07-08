test 'it should launch ember immediately', ->
  equal find(".editor-wrapper.ember-view").length, 1, "Ember view should be present"
  equal find("ul.step-links").length, 1, "Side links were not present"
  equal find("ul.action-links li:last-child .icon-close").length, 1, "Logout link (x) wasn't present"
  equal find(".step-wrapper .step-title").text(), "Settings", "Settings tab was not the launch tab"
