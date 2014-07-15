module "editor preview",
  setup: ->
    @route = getModule("route:application")
    ok @route.currentModel

test "it should immediately load a preview of the element being edited", ->
  equal find("#hellobar-preview-container iframe").length, 1, "Rendered element preview is empty"

test "changing certain model properties updates the preview", ->
  visit "text"

  fillIn(findLabeled("Bar text"), "New message").andThen =>
    ok find("#hellobar-preview-container iframe").contents().find("#hb_msg_container span").text().indexOf("New message") > -1,
      "Did not update preview"
