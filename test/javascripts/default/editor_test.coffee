test 'it should launch ember immediately', ->
  equal find("ul.step-links").length, 1, "Side links were not present"
  equal find("ul.action-links li:last-child .icon-close").length, 1, "Logout link (x) wasn't present"
